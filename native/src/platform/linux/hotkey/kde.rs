use crate::ffi::error::HotkeyError;
use crate::ffi::types::ShortcutBinding;
use zbus::Connection;
use std::collections::HashMap;
use std::sync::Arc;
use futures_lite::StreamExt;
use tokio::sync::mpsc;

const KGLOBALACCEL_SERVICE: &str = "org.kde.kglobalaccel";
const KGLOBALACCEL_PATH: &str = "/kglobalaccel";
const KGLOBALACCEL_IFACE: &str = "org.kde.KGlobalAccel";

pub struct KdeHotkeyService {
    shortcuts: HashMap<String, ShortcutBinding>,
}

impl KdeHotkeyService {
    pub fn new() -> Self {
        Self {
            shortcuts: HashMap::new(),
        }
    }

    pub async fn register_all(
        &mut self,
        shortcuts: Vec<ShortcutBinding>,
        event_tx: mpsc::Sender<String>,
    ) -> Result<(), HotkeyError> {
        let conn = Connection::session().await
            .map_err(|e| HotkeyError::DbusError(e.to_string()))?;

        let proxy = zbus::Proxy::new(
            &conn,
            KGLOBALACCEL_SERVICE,
            KGLOBALACCEL_PATH,
            KGLOBALACCEL_IFACE,
        )
        .await
        .map_err(|e| HotkeyError::DbusError(e.to_string()))?;

        // 建立 action -> shortcut 的反向映射，用于信号匹配
        let mut action_by_keys: HashMap<String, String> = HashMap::new();

        for binding in &shortcuts {
            if !binding.enabled {
                continue;
            }
            self.register_single(&proxy, binding).await?;
            let bind = Self::to_hypr_bind(&binding.key_combination);
            if !bind.is_empty() {
                action_by_keys.insert(bind, binding.action.clone());
            }
        }

        self.shortcuts.clear();
        for s in shortcuts {
            self.shortcuts.insert(s.action.clone(), s);
        }

        // 启动 D-Bus 信号监听任务
        if !action_by_keys.is_empty() {
            let _action_map = Arc::new(action_by_keys);
            let mut signal_receiver = proxy
                .receive_signal("shortcutActivated")
                .await
                .map_err(|e| HotkeyError::DbusError(format!("Failed to listen for shortcutActivated signal: {}", e)))?;

            let tx = event_tx.clone();
            tokio::spawn(async move {
                loop {
                    match signal_receiver.next().await {
                        Some(signal) => {
                            // shortcutActivated 信号参数: (action: String, shortcut: String)
                            if let Ok((action, shortcut)) = signal.body().deserialize::<(String, String)>() {
                                tracing::debug!("[kde] shortcutActivated: action={}, shortcut={}", action, shortcut);
                                // 也通过按键匹配查找（因为 KDE 可能传 key combination 而非 action name）
                                if let Err(e) = tx.send(action).await {
                                    tracing::warn!("[kde] channel send failed: {:?}", e);
                                }
                            }
                        }
                        None => break,
                    }
                }
                tracing::warn!("[kde] shortcutActivated signal listener ended");
            });
        }

        Ok(())
    }

    async fn register_single(
        &self,
        proxy: &zbus::Proxy<'_>,
        binding: &ShortcutBinding,
    ) -> Result<(), HotkeyError> {
        let action = binding.action.clone();
        let keys = binding.key_combination.clone();

        let _reply = proxy
            .call_method(
                "registerShortcut",
                &(action.clone(), keys.clone(), keys),
            )
            .await
            .map_err(|e| HotkeyError::DbusError(e.to_string()))?;

        tracing::info!(
            "Registered KDE shortcut: {} -> {}",
            binding.key_combination,
            action
        );
        Ok(())
    }

    /// 将快捷键格式 "Ctrl+Shift+T" 转换为 KDE 格式
    pub fn to_hypr_bind(keys: &str) -> String {
        let parts: Vec<&str> = keys.split('+').collect();
        if parts.len() < 2 { return String::new(); }
        let mut mods = Vec::new();
        let mut key: Option<String> = None;
        for p in &parts {
            let upper = p.trim().to_uppercase();
            match upper.as_str() {
                "CTRL" | "CONTROL" => mods.push("CTRL"),
                "SHIFT" => mods.push("SHIFT"),
                "ALT" => mods.push("ALT"),
                "META" | "SUPER" | "WIN" => mods.push("SUPER"),
                k => key = Some(k.to_string()),
            }
        }
        let key = match key {
            Some(k) => k,
            None => return String::new(),
        };
        format!("{},{}", mods.join("_"), key)
    }
}
