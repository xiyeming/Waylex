#![allow(dead_code)]

use crate::ffi::error::HotkeyError;
use crate::ffi::types::ShortcutBinding;
use std::io::{Read, Write};
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::mpsc;

/// Hyprland IPC hotkey integration via helper script + FIFO.
///
/// 使用 Hyprland Lua IPC (`eval hl.bind()`) 注册快捷键：
/// 1. 创建 helper script（/tmp/hypr-waylex-helper-<pid>.sh）
/// 2. 创建 FIFO（/tmp/hypr-waylex-<pid>）
/// 3. 通过 `eval hl.bind("CTRL + SHIFT + S", function() os.execute("helper.sh action") end)` 注册
/// 4. helper script 写入 action 到 FIFO
/// 5. 后台线程读取 FIFO，通过 broadcast channel 发送 action
///
/// 注意：Hyprland 0.55+ Lua config 不支持 `keyword binde`，必须使用 `eval hl.bind()`。
///       通过 `eval hl.unbind()` 可以在退出时清理动态注册的 bind。
pub struct HyprlandHotkeyService {
    binds: Vec<(String, String)>,   // (bind_format, action) - for unbind cleanup
    fifo_path: PathBuf,
    helper_path: PathBuf,
    running: Arc<AtomicBool>,
    _listener_handle: Option<std::thread::JoinHandle<()>>,
}

#[allow(dead_code)]
impl HyprlandHotkeyService {
    pub fn new() -> Result<Self, HotkeyError> {
        let pid = std::process::id();
        Ok(Self {
            binds: Vec::new(),
            fifo_path: PathBuf::from(format!("/tmp/hypr-waylex-{pid}")),
            helper_path: PathBuf::from(format!("/tmp/hypr-waylex-helper-{pid}.sh")),
            running: Arc::new(AtomicBool::new(false)),
            _listener_handle: None,
        })
    }

    #[allow(dead_code)]
    fn find_socket() -> Option<String> {
        let sig = std::env::var("HYPRLAND_INSTANCE_SIGNATURE").ok()?;
        let dir = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
        Some(format!("{}/hypr/{}/.socket.sock", dir, sig))
    }

    #[allow(dead_code)]
    fn send_ipc(command: &str) -> Result<(), String> {
        let socket = match Self::find_socket() {
            Some(s) => s,
            None => return Err("No socket (HYPRLAND_INSTANCE_SIGNATURE not set)".into()),
        };
        let mut stream = std::os::unix::net::UnixStream::connect(&socket)
            .map_err(|e| format!("connect {}: {}", socket, e))?;
        stream.write_all(command.as_bytes()).map_err(|e| format!("write: {}", e))?;
        // 读取响应
        let mut buf = [0u8; 4096];
        let _ = stream.read(&mut buf);
        Ok(())
    }

    /// Convert our key format "Ctrl+Shift+S" to Hyprland Lua format "CTRL + SHIFT + S"
    fn to_hypr_bind(keys: &str) -> Result<String, HotkeyError> {
        let parts: Vec<&str> = keys.split('+').collect();
        if parts.len() < 2 { return Ok(String::new()); }
        let mut parts_out: Vec<String> = Vec::new();
        for p in &parts {
            let upper = p.trim().to_uppercase();
            match upper.as_str() {
                "CTRL" | "CONTROL" => parts_out.push("CTRL".to_string()),
                "SHIFT" => parts_out.push("SHIFT".to_string()),
                "ALT" => parts_out.push("ALT".to_string()),
                "META" | "SUPER" | "WIN" => parts_out.push("SUPER".to_string()),
                _ => {
                    let k = p.trim().to_uppercase();
                    if !k.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
                        return Err(HotkeyError::ParseError(format!(
                            "Invalid characters in key name: {}", k
                        )));
                    }
                    parts_out.push(k);
                }
            }
        }
        Ok(parts_out.join(" + "))
    }

    /// Escape double quotes in action string for safe shell embedding
    fn escape_action(action: &str) -> String {
        action.replace('"', "\\\"")
    }

    /// 创建 FIFO 文件
    fn create_fifo(path: &PathBuf) -> Result<(), HotkeyError> {
        let _ = std::fs::remove_file(path);
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let status = Command::new("mkfifo").arg(path).status()
            .map_err(|e| HotkeyError::ParseError(format!("mkfifo failed: {}", e)))?;
        if !status.success() {
            return Err(HotkeyError::ParseError(format!(
                "mkfifo {} exited with {:?}", path.display(), status.code()
            )));
        }
        Ok(())
    }

    /// 创建 helper script（用于将 action 写入 FIFO）
    /// 使用 `&` 后台执行 echo，确保 os.execute() 永不阻塞。
    fn create_helper_script(helper_path: &PathBuf, fifo_path: &PathBuf) -> Result<(), HotkeyError> {
        let script_content = format!(
            "#!/bin/sh\n\
            # Hyprland keybind helper for Waylex\n\
            # Background echo so os.execute() returns immediately\n\
            echo \"$1\" > {} 2>/dev/null &\n",
            fifo_path.display()
        );
        std::fs::write(helper_path, script_content)
            .map_err(|e| HotkeyError::ParseError(format!("write helper script: {}", e)))?;
        std::fs::set_permissions(helper_path, std::fs::Permissions::from_mode(0o700))
            .map_err(|e| HotkeyError::ParseError(format!("chmod helper: {}", e)))?;
        Ok(())
    }

    /// 删除 FIFO 和 helper script
    fn cleanup_files(fifo_path: &PathBuf, helper_path: &PathBuf) {
        let _ = std::fs::remove_file(fifo_path);
        let _ = std::fs::remove_file(helper_path);
    }

    pub async fn register_all(
        mut self,
        shortcuts: Vec<ShortcutBinding>,
        event_tx: mpsc::Sender<String>,
    ) -> Result<Self, HotkeyError> {
        tracing::info!("[hyprland] register_all start: {} shortcuts", shortcuts.len());
        eprintln!("[rust] [hyprland] register_all start: {} shortcuts", shortcuts.len());
        self.binds.clear();

        // 先创建 FIFO，再创建 helper script
        Self::create_fifo(&self.fifo_path)?;
        tracing::info!("[hyprland] FIFO created: {}", self.fifo_path.display());
        eprintln!("[rust] [hyprland] FIFO={}", self.fifo_path.display());

        Self::create_helper_script(&self.helper_path, &self.fifo_path)?;
        tracing::info!("[hyprland] Helper script: {}", self.helper_path.display());
        eprintln!("[rust] [hyprland] helper={}", self.helper_path.display());

        // 用非阻塞方式打开 FIFO，立即开始监听
        let mut opts = std::fs::OpenOptions::new();
        opts.read(true);
        #[cfg(target_os = "linux")]
        {
            use std::os::unix::fs::OpenOptionsExt;
            opts.custom_flags(libc::O_RDONLY | libc::O_NONBLOCK);
        }
        let file = match opts.open(&self.fifo_path) {
            Ok(f) => f,
            Err(e) => {
                tracing::error!("[hyprland] Cannot open FIFO non-blocking: {}", e);
                eprintln!("[rust] [hyprland] Cannot open FIFO: {}", e);
                Self::cleanup_files(&self.fifo_path, &self.helper_path);
                return Err(HotkeyError::ParseError(format!("Cannot open FIFO non-blocking: {}", e)));
            }
        };

        // 启动 FIFO 读取线程
        self.running = Arc::new(AtomicBool::new(true));
        let running = self.running.clone();

        let handle = std::thread::spawn(move || {
            let mut file = file;
            let mut buf = [0u8; 256];

            loop {
                if !running.load(Ordering::SeqCst) {
                    tracing::debug!("[hyprland] FIFO reader: running=false, exiting");
                    break;
                }
                match file.read(&mut buf) {
                    Ok(0) => {
                        std::thread::sleep(std::time::Duration::from_millis(50));
                    }
                    Ok(n) => {
                        let action = String::from_utf8_lossy(&buf[..n]).trim().to_string();
                        if action.is_empty() {
                            continue;
                        }
                        tracing::info!("[hyprland] FIFO received action: {}", action);
                        eprintln!("[rust] [hyprland] FIFO action: {}", action);
                        // FIFO reader 跑在标准线程里，不能 .await；用 blocking_send 同步发送
                        let _ = event_tx.blocking_send(action);
                    }
                    Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                        std::thread::sleep(std::time::Duration::from_millis(20));
                    }
                    Err(e) => {
                        tracing::warn!("[hyprland] FIFO read error: {}", e);
                        eprintln!("[rust] [hyprland] FIFO read error: {}", e);
                        std::thread::sleep(std::time::Duration::from_millis(50));
                    }
                }
            }

            tracing::info!("[hyprland] FIFO reader exited");
            eprintln!("[rust] [hyprland] FIFO reader exited");
        });

        self._listener_handle = Some(handle);

        // 通过 `eval hl.bind()` 注册快捷键
        let mut registered_count = 0usize;
        let mut first_error: Option<String> = None;

        for s in &shortcuts {
            if !s.enabled { continue; }
            let bind = match Self::to_hypr_bind(&s.key_combination) {
                Ok(b) => b,
                Err(e) => {
                    tracing::warn!("[hyprland] Skipping invalid key '{}': {}", s.key_combination, e);
                    eprintln!("[rust] [hyprland] skip invalid '{}': {}", s.key_combination, e);
                    continue;
                }
            };
            if bind.is_empty() { continue; }

            let escaped_action = Self::escape_action(&s.action);
            let helper_str = self.helper_path.display().to_string();
            // 使用 eval hl.bind() 注册，兼容 Hyprland Lua config
            let ipc_cmd = format!(
                "eval hl.bind(\"{}\", function() os.execute(\"{} \\\"{}\\\"\") end)\n",
                bind, helper_str, escaped_action
            );

            if let Err(e) = Self::send_ipc(&ipc_cmd) {
                let err_msg = format!("Failed to register bind '{}': {}", s.key_combination, e);
                tracing::warn!("[hyprland] {}", err_msg);
                eprintln!("[rust] [hyprland] {}", err_msg);
                if first_error.is_none() {
                    first_error = Some(err_msg);
                }
            } else {
                tracing::info!("[hyprland] Registered bind: {} -> {}", s.key_combination, bind);
                eprintln!("[rust] [hyprland] Registered bind: {} -> {}", s.key_combination, bind);
                self.binds.push((bind.clone(), s.action.clone()));
                registered_count += 1;
            }
        }

        tracing::info!(
            "[hyprland] Registered {}/{} binds via eval hl.bind()",
            registered_count, shortcuts.len()
        );
        eprintln!(
            "[rust] [hyprland] Registered {}/{} binds via eval hl.bind()",
            registered_count, shortcuts.len()
        );

        if registered_count == 0 {
            tracing::error!("[hyprland] No binds registered, cleaning up");
            self.running.store(false, Ordering::SeqCst);
            let _ = self._listener_handle.take().and_then(|h| Some(h.join()));
            Self::cleanup_files(&self.fifo_path, &self.helper_path);
            return Err(HotkeyError::NoKeyboardDevices);
        }

        tracing::info!("[hyprland] FIFO IPC listener started ({} shortcuts)", registered_count);
        eprintln!("[rust] [hyprland] FIFO IPC listener started ({} shortcuts)", registered_count);
        Ok(self)
    }

    pub fn unregister_all(&mut self) -> Result<(), HotkeyError> {
        tracing::info!("[hyprland] unregister_all start, {} binds to unbind", self.binds.len());
        eprintln!("[rust] [hyprland] unregister_all start");

        // 停止读取线程（必须在 unbind 之前，避免 FIFO writer 阻塞）
        self.running.store(false, Ordering::SeqCst);
        tracing::info!("[hyprland] running flag set to false");

        // 取消所有动态注册的 bind
        for (bind, action) in &self.binds {
            tracing::info!("[hyprland] unbinding: {} -> {}", bind, action);
            let _ = Self::send_ipc(&format!("eval hl.unbind(\"{}\")\n", bind));
        }
        self.binds.clear();
        tracing::info!("[hyprland] all binds cleared");

        // 等待 reader 线程退出
        if let Some(handle) = self._listener_handle.take() {
            tracing::info!("[hyprland] waiting for FIFO reader thread to exit...");
            let _ = handle.join();
            tracing::info!("[hyprland] FIFO reader thread joined");
        }

        // 删除 FIFO 和 helper script
        Self::cleanup_files(&self.fifo_path, &self.helper_path);
        tracing::info!("[hyprland] temp files cleaned up");
        eprintln!("[rust] [hyprland] unregister_all done");

        Ok(())
    }
}
