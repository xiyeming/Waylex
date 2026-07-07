pub mod evdev;
pub mod hyprland;
pub mod kde;

use crate::ffi::error::HotkeyError;
use crate::ffi::types::ShortcutBinding;
use crate::config::ConfigManager;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::mpsc;

pub struct HotkeyService {
    registered: Vec<ShortcutBinding>,
    event_tx: Option<mpsc::Sender<String>>,
    event_rx: Option<mpsc::Receiver<String>>,
    running: Arc<AtomicBool>,
    hyprland_service: Option<Arc<std::sync::Mutex<hyprland::HyprlandHotkeyService>>>,
}

impl HotkeyService {
    pub fn new() -> Self {
        Self {
            registered: Vec::new(),
            event_tx: None,
            event_rx: None,
            running: Arc::new(AtomicBool::new(false)),
            hyprland_service: None,
        }
    }

    pub async fn register_all(&mut self, shortcuts: Vec<ShortcutBinding>) -> Result<(), HotkeyError> {
        eprintln!("[rust] hotkey::register_all called with {} shortcuts", shortcuts.len());
        let shortcut_summary = shortcuts
            .iter()
            .map(|s| format!("{}={}{}", s.action, s.key_combination, if s.enabled { "" } else { "(disabled)" }))
            .collect::<Vec<_>>()
            .join(", ");

        self.running.store(false, Ordering::SeqCst);
        tracing::info!("[hotkey] stopping previous listener before re-register");
        eprintln!("[rust] [hotkey] stopping previous listener");
        tokio::time::sleep(tokio::time::Duration::from_millis(200)).await;

        let desktop_env = ConfigManager::detect_desktop_env();
        tracing::info!(
            "[hotkey] register_all start: desktop_env={:?}, shortcuts=[{}]",
            desktop_env,
            shortcut_summary
        );
        eprintln!("[rust] [hotkey] desktop_env={:?}", desktop_env);
        let (tx, rx) = mpsc::channel::<String>(1024);
        self.event_tx = Some(tx.clone());
        self.event_rx = Some(rx);
        self.running = Arc::new(AtomicBool::new(true));
        tracing::info!("[hotkey] channel created (capacity=1024)");

        // Hyprland: use FIFO-based IPC (socket2 does not emit activekeyv2)
        if desktop_env == crate::ffi::types::DesktopEnv::Hyprland {
            tracing::info!("[hotkey] Hyprland detected, using FIFO IPC backend");
            eprintln!("[rust] [hotkey] Hyprland detected, using FIFO IPC");
            let hl_service = hyprland::HyprlandHotkeyService::new()?;
            let hl_service = hl_service.register_all(shortcuts.clone(), tx.clone()).await?;
            self.hyprland_service = Some(Arc::new(std::sync::Mutex::new(hl_service)));
            self.registered = shortcuts;
            tracing::info!("[hotkey] Hyprland FIFO IPC hotkeys registered");
            eprintln!("[rust] [hotkey] Hyprland FIFO IPC hotkeys registered");
            return Ok(());
        }

        // KDE: try KGlobalAccel
        if desktop_env == crate::ffi::types::DesktopEnv::KdePlasma {
            tracing::info!("[hotkey] KDE detected, trying KGlobalAccel");
            eprintln!("[rust] [hotkey] KDE detected, trying KGlobalAccel");
            let mut kde_service = kde::KdeHotkeyService::new();
            if kde_service.register_all(shortcuts.clone(), tx.clone()).await.is_ok() {
                self.registered = shortcuts;
                tracing::info!("[hotkey] KDE hotkeys registered successfully");
                eprintln!("[rust] [hotkey] KDE hotkeys registered");
                return Ok(());
            }
            tracing::info!("[hotkey] KDE hotkey failed, falling back to evdev");
            eprintln!("[rust] [hotkey] KDE hotkey failed, falling back to evdev");
        }

        // Fallback: evdev
        tracing::info!("[hotkey] Using evdev hotkey backend");
        eprintln!("[rust] [hotkey] Using evdev hotkey backend");
        let mut evdev_service = evdev::EvdevHotkeyService::with_running(self.running.clone())?;
        evdev_service.register_all(shortcuts.clone()).await?;

        let event_tx = tx;
        tokio::task::spawn_blocking(move || {
            if let Err(e) = evdev_service.listen_blocking(event_tx) {
                tracing::warn!(
                    "Evdev listener failed: {}. On Hyprland, ensure you are in the 'input' group: sudo usermod -aG input $USER",
                    e
                );
                eprintln!("[rust] [hotkey] evdev listener failed: {}", e);
            }
        });

        self.registered = shortcuts;
        tracing::info!("[hotkey] Evdev hotkeys registered ({} shortcuts)", self.registered.len());
        eprintln!("[rust] [hotkey] evdev hotkeys registered ({} shortcuts)", self.registered.len());
        Ok(())
    }

    pub fn unregister_all(&mut self) -> Result<(), HotkeyError> {
        tracing::info!(
            "[hotkey] unregister_all called, clearing {} registered shortcuts",
            self.registered.len()
        );
        eprintln!("[rust] [hotkey] unregister_all called");
        self.running.store(false, Ordering::SeqCst);
        tracing::info!("[hotkey] running flag set to false");

        // 在 join reader 线程之前先释放 event_tx/event_rx，
        // 使 reader 线程里阻塞的 send() 立刻收到 SendError 而退出循环
        drop(self.event_tx.take());
        drop(self.event_rx.take());
        tracing::info!("[hotkey] event_tx/event_rx dropped before join");

        if let Some(ref svc) = self.hyprland_service {
            tracing::info!("[hotkey] calling hyprland unregister_all");
            let _ = svc.lock().unwrap().unregister_all();
            tracing::info!("[hotkey] hyprland unregister_all done");
        }
        self.registered.clear();
        tracing::info!("[hotkey] registered list cleared");

        self.hyprland_service = None;
        tracing::info!("[hotkey] unregister_all complete");
        Ok(())
    }

    /// Poll for the next hotkey event. Returns None if no event available.
    pub fn poll_event(&mut self, _timeout_ms: u64) -> Option<String> {
        let rx = self.event_rx.as_mut()?;
        match rx.try_recv() {
            Ok(action) => {
                tracing::info!("[hotkey] poll_event received: {}", action);
                eprintln!("[rust] [hotkey] poll_event received: {}", action);
                Some(action)
            }
            Err(tokio::sync::mpsc::error::TryRecvError::Empty) => {
                tracing::trace!("[hotkey] poll_event: empty (no pending event)");
                None
            }
            Err(e) => {
                tracing::warn!("[hotkey] poll_event receiver error: {:?}", e);
                eprintln!("[rust] [hotkey] poll_event receiver error: {:?}", e);
                None
            }
        }
    }
}
