use async_trait::async_trait;
use crate::ffi::types::{DesktopEnv, OcrResult, ShortcutBinding};
use crate::ffi::error::{ClipboardError, HotkeyError, OcrError, TrayError};
use crate::platform::PlatformBackend;
use std::sync::{Arc, Mutex};

pub struct WindowsBackend {
    hotkey_manager: Arc<Mutex<global_hotkey::GlobalHotKeyManager>>,
    clipboard: Arc<Mutex<arboard::Clipboard>>,
    tray_icon: Arc<Mutex<Option<tray_icon::TrayIcon>>>,
    registered_hotkeys: Arc<Mutex<Vec<(u32, String)>>>,
}

impl WindowsBackend {
    pub fn new() -> Self {
        let hotkey_manager = global_hotkey::GlobalHotKeyManager::new()
            .expect("Failed to create global hotkey manager");
        let clipboard = arboard::Clipboard::new()
            .expect("Failed to create clipboard");

        Self {
            hotkey_manager: Arc::new(Mutex::new(hotkey_manager)),
            clipboard: Arc::new(Mutex::new(clipboard)),
            tray_icon: Arc::new(Mutex::new(None)),
            registered_hotkeys: Arc::new(Mutex::new(Vec::new())),
        }
    }

    fn parse_hotkey(combo: &str) -> Result<global_hotkey::HotKey, HotkeyError> {
        use global_hotkey::{HotKey, Modifiers, Code};

        let parts: Vec<&str> = combo.split('+').map(|s| s.trim()).collect();
        if parts.is_empty() {
            return Err(HotkeyError::ParseError("Empty key combination".into()));
        }

        let mut modifiers = Modifiers::empty();
        let mut code = Code::Unidentified;

        for part in &parts {
            let upper = part.to_uppercase();
            match upper.as_str() {
                "CTRL" | "CONTROL" => modifiers |= Modifiers::CONTROL,
                "ALT" => modifiers |= Modifiers::ALT,
                "SHIFT" => modifiers |= Modifiers::SHIFT,
                "META" | "SUPER" | "WIN" | "CMD" | "COMMAND" => modifiers |= Modifiers::META,
                "F1" => code = Code::F1,
                "F2" => code = Code::F2,
                "F3" => code = Code::F3,
                "F4" => code = Code::F4,
                "F5" => code = Code::F5,
                "F6" => code = Code::F6,
                "F7" => code = Code::F7,
                "F8" => code = Code::F8,
                "F9" => code = Code::F9,
                "F10" => code = Code::F10,
                "F11" => code = Code::F11,
                "F12" => code = Code::F12,
                "ESC" | "ESCAPE" => code = Code::Escape,
                "TAB" => code = Code::Tab,
                "SPACE" => code = Code::Space,
                "ENTER" | "RETURN" => code = Code::Enter,
                "BACKSPACE" => code = Code::Backspace,
                "DELETE" => code = Code::Delete,
                "UP" => code = Code::ArrowUp,
                "DOWN" => code = Code::ArrowDown,
                "LEFT" => code = Code::ArrowLeft,
                "RIGHT" => code = Code::ArrowRight,
                "HOME" => code = Code::Home,
                "END" => code = Code::End,
                "PAGEUP" => code = Code::PageUp,
                "PAGEDOWN" => code = Code::PageDown,
                "A" => code = Code::KeyA,
                "B" => code = Code::KeyB,
                "C" => code = Code::KeyC,
                "D" => code = Code::KeyD,
                "E" => code = Code::KeyE,
                "F" => code = Code::KeyF,
                "G" => code = Code::KeyG,
                "H" => code = Code::KeyH,
                "I" => code = Code::KeyI,
                "J" => code = Code::KeyJ,
                "K" => code = Code::KeyK,
                "L" => code = Code::KeyL,
                "M" => code = Code::KeyM,
                "N" => code = Code::KeyN,
                "O" => code = Code::KeyO,
                "P" => code = Code::KeyP,
                "Q" => code = Code::KeyQ,
                "R" => code = Code::KeyR,
                "S" => code = Code::KeyS,
                "T" => code = Code::KeyT,
                "U" => code = Code::KeyU,
                "V" => code = Code::KeyV,
                "W" => code = Code::KeyW,
                "X" => code = Code::KeyX,
                "Y" => code = Code::KeyY,
                "Z" => code = Code::KeyZ,
                "0" => code = Code::Digit0,
                "1" => code = Code::Digit1,
                "2" => code = Code::Digit2,
                "3" => code = Code::Digit3,
                "4" => code = Code::Digit4,
                "5" => code = Code::Digit5,
                "6" => code = Code::Digit6,
                "7" => code = Code::Digit7,
                "8" => code = Code::Digit8,
                "9" => code = Code::Digit9,
                _ => return Err(HotkeyError::ParseError(format!("Unknown key: {}", part))),
            }
        }

        if code == Code::Unidentified {
            return Err(HotkeyError::ParseError("No trigger key found".into()));
        }

        Ok(HotKey::new(Some(modifiers), code))
    }
}

#[async_trait]
impl PlatformBackend for WindowsBackend {
    async fn register_hotkeys(&self, shortcuts: Vec<ShortcutBinding>) -> Result<(), HotkeyError> {
        let manager = self.hotkey_manager.lock().unwrap();
        let mut registered = self.registered_hotkeys.lock().unwrap();
        registered.clear();

        for binding in shortcuts {
            if !binding.enabled { continue; }
            match Self::parse_hotkey(&binding.key_combination) {
                Ok(hotkey) => {
                    if let Ok(id) = manager.register(hotkey) {
                        registered.push((id.0, binding.action));
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to parse hotkey '{}': {}", binding.key_combination, e);
                }
            }
        }

        tracing::info!("Registered {} Windows global hotkeys", registered.len());
        Ok(())
    }

    fn unregister_hotkeys(&self) -> Result<(), HotkeyError> {
        let manager = self.hotkey_manager.lock().unwrap();
        let registered = self.registered_hotkeys.lock().unwrap();
        for (id, _) in registered.iter() {
            let _ = manager.unregister(global_hotkey::HotKeyId(*id));
        }
        drop(registered);
        self.registered_hotkeys.lock().unwrap().clear();
        Ok(())
    }

    fn poll_hotkey_event(&self) -> Option<String> {
        if let Ok(event) = global_hotkey::GlobalHotKeyEvent::receiver().try_recv() {
            let registered = self.registered_hotkeys.lock().unwrap();
            for (id, action) in registered.iter() {
                if event.id == global_hotkey::HotKeyId(*id) {
                    return Some(action.clone());
                }
            }
        }
        None
    }

    fn get_clipboard_text(&self) -> Result<String, ClipboardError> {
        let mut clipboard = self.clipboard.lock().unwrap();
        clipboard.get_text()
            .map_err(|e| ClipboardError::WlError(e.to_string()))
    }

    fn set_clipboard_text(&self, text: String) -> Result<(), ClipboardError> {
        let mut clipboard = self.clipboard.lock().unwrap();
        clipboard.set_text(text)
            .map_err(|e| ClipboardError::WlError(e.to_string()))
    }

    async fn screenshot(&self) -> Result<Vec<u8>, OcrError> {
        let screens = screenshots::Screen::all()
            .map_err(|e| OcrError::ScreenshotFailed)?;

        let screen = screens.first()
            .ok_or(OcrError::ScreenshotFailed)?;

        let image = screen.capture()
            .map_err(|e| OcrError::ScreenshotFailed)?;

        Ok(image.to_png())
    }

    async fn recognize(&self, image_data: Vec<u8>, lang: String) -> Result<OcrResult, OcrError> {
        crate::platform::common::ocr_tesseract::recognize_blocking(&image_data, &lang)
    }

    async fn init_tray(&self) -> Result<(), TrayError> {
        let mut tray = self.tray_icon.lock().unwrap();
        if tray.is_some() {
            return Ok(());
        }

        let tray_icon = tray_icon::TrayIconBuilder::new()
            .with_tooltip("Waylex")
            .build()
            .map_err(|e| TrayError::MenuError(e.to_string()))?;

        *tray = Some(tray_icon);
        tracing::info!("Windows tray initialized");
        Ok(())
    }

    fn show_tray_notification(&self, title: &str, body: &str) -> Result<(), TrayError> {
        tracing::info!("Tray notification: {} - {}", title, body);
        Ok(())
    }

    fn detect_desktop_env(&self) -> DesktopEnv {
        DesktopEnv::Unknown
    }
}
