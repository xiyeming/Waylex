#![allow(dead_code)]

use crate::ffi::error::HotkeyError;
use crate::ffi::types::ShortcutBinding;
use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use tokio::sync::mpsc;

type ShortcutDef = (HashSet<u16>, u16, String);

pub struct EvdevHotkeyService {
    shortcuts: Vec<ShortcutDef>,
    running: Arc<AtomicBool>,
}

#[allow(dead_code)]
impl EvdevHotkeyService {
    pub fn new() -> Result<Self, HotkeyError> {
        Ok(Self {
            shortcuts: Vec::new(),
            running: Arc::new(AtomicBool::new(false)),
        })
    }

    pub fn with_running(running: Arc<AtomicBool>) -> Result<Self, HotkeyError> {
        Ok(Self { shortcuts: Vec::new(), running })
    }

    #[allow(dead_code)]
    pub fn shortcuts(&self) -> &[ShortcutDef] {
        &self.shortcuts
    }

    /// Quick probe: can we open at least one keyboard device?
    /// Used by Hyprland path to decide whether to use evdev or fall back to IPC.
    #[allow(dead_code)]
    pub fn probe_device() -> Result<(), HotkeyError> {
        for (path, _) in evdev::enumerate() {
            if Self::open_keyboard_device(&path).is_ok() {
                return Ok(());
            }
        }
        Err(HotkeyError::NoKeyboardDevices)
    }

    fn parse_key_combination(keys: &str) -> Vec<u16> {
        keys.split('+')
            .filter_map(|k| {
                let key = k.trim().to_uppercase();
                match key.as_str() {
                    "CTRL" | "CONTROL" => Some(29),
                    "SHIFT" => Some(42),
                    "ALT" => Some(56),
                    "META" | "SUPER" | "WIN" => Some(125),
                    "F1" => Some(59), "F2" => Some(60), "F3" => Some(61),
                    "F4" => Some(62), "F5" => Some(63), "F6" => Some(64),
                    "F7" => Some(65), "F8" => Some(66), "F9" => Some(67),
                    "F10" => Some(68), "F11" => Some(87), "F12" => Some(88),
                    // Linux evdev keycodes (QWERTY positions, NOT alphabetical)
                    "A" => Some(30), "B" => Some(48), "C" => Some(46),
                    "D" => Some(32), "E" => Some(18), "F" => Some(33),
                    "G" => Some(34), "H" => Some(35), "I" => Some(23),
                    "J" => Some(36), "K" => Some(37), "L" => Some(38),
                    "M" => Some(50), "N" => Some(49), "O" => Some(24),
                    "P" => Some(25), "Q" => Some(16), "R" => Some(19),
                    "S" => Some(31), "T" => Some(20), "U" => Some(22),
                    "V" => Some(47), "W" => Some(17), "X" => Some(45),
                    "Y" => Some(21), "Z" => Some(44),
                    "0" => Some(11), "1" => Some(2), "2" => Some(3),
                    "3" => Some(4), "4" => Some(5), "5" => Some(6),
                    "6" => Some(7), "7" => Some(8), "8" => Some(9),
                    "9" => Some(10),
                    "SPACE" => Some(57),
                    "ESC" | "ESCAPE" => Some(1),
                    "TAB" => Some(15),
                    "ENTER" | "RETURN" => Some(28),
                    _ => None,
                }
            })
            .collect()
    }

    pub async fn register_all(&mut self, shortcuts: Vec<ShortcutBinding>) -> Result<(), HotkeyError> {
        self.shortcuts.clear();
        for binding in shortcuts {
            if !binding.enabled { continue; }
            let key_codes = Self::parse_key_combination(&binding.key_combination);
            if key_codes.len() < 2 { continue; }
            let modifiers: HashSet<u16> = key_codes[..key_codes.len()-1].iter().copied().collect();
            let trigger = key_codes[key_codes.len() - 1];
            self.shortcuts.push((modifiers, trigger, binding.action.clone()));
        }
        self.running.store(true, Ordering::SeqCst);
        tracing::info!("Evdev configured {} shortcuts", self.shortcuts.len());
        Ok(())
    }

    fn open_keyboard_device(path: &std::path::Path) -> Result<evdev::Device, String> {
        let device = evdev::Device::open(path)
            .map_err(|e| format!("open {:?}: {}", path, e))?;
        let name = device.name().unwrap_or("unknown").to_string();
        let name_lower = name.to_lowercase();

        if name_lower.contains("mouse")
            || name_lower.contains("touchpad")
            || name_lower.contains("trackpoint")
        {
            return Err(format!("{} is not a keyboard candidate", name));
        }

        let keys = device
            .supported_keys()
            .ok_or_else(|| format!("{} has no supported_keys", name))?;

        if !keys.contains(evdev::KeyCode::KEY_A) {
            return Err(format!("{} has no KEY_A support", name));
        }

        Ok(device)
    }

    fn reopen_keyboard_device(
        preferred_path: &std::path::Path,
        device_name: &str,
    ) -> Result<(evdev::Device, std::path::PathBuf), String> {
        if let Ok(device) = Self::open_keyboard_device(preferred_path) {
            return Ok((device, preferred_path.to_path_buf()));
        }

        for (path, _) in evdev::enumerate() {
            let Ok(device) = Self::open_keyboard_device(&path) else {
                continue;
            };
            if device.name().unwrap_or("unknown") == device_name {
                return Ok((device, path));
            }
        }

        Err(format!(
            "could not reopen keyboard '{}' from {:?} or current evdev enumeration",
            device_name, preferred_path
        ))
    }

    pub fn unregister_all(&mut self) -> Result<(), HotkeyError> {
        self.shortcuts.clear();
        self.running.store(false, Ordering::SeqCst);
        tracing::info!("Evdev hotkey service stopped");
        Ok(())
    }

    pub fn listen_blocking(&self, tx: mpsc::Sender<String>) -> Result<(), HotkeyError> {
        let mut device_paths: Vec<std::path::PathBuf> = Vec::new();

        for (path, _) in evdev::enumerate() {
            device_paths.push(path);
        }

        if device_paths.is_empty() {
            tracing::warn!("No keyboard devices found for evdev");
            return Err(HotkeyError::NoKeyboardDevices);
        }

        tracing::info!("Evdev listener starting for {} candidate devices", device_paths.len());

        let running = self.running.clone();
        let held_keys = Arc::new(Mutex::new(HashSet::<u16>::new()));
        let shortcuts = self.shortcuts.clone();
        let last_trigger = Arc::new(Mutex::new(std::collections::HashMap::<String, Instant>::new()));
        let mut opened = 0u32;

        for path in device_paths {
            let device = match Self::open_keyboard_device(&path) {
                Ok(device) => {
                    tracing::info!(
                        "[evdev] Opened keyboard device: {} at {:?}",
                        device.name().unwrap_or("unknown"),
                        path
                    );
                    device
                }
                Err(reason) => {
                    tracing::debug!("[evdev] Skipping device {:?}: {}", path, reason);
                    continue;
                }
            };
            opened += 1;
            let tx = tx.clone();
            let running = running.clone();
            let held_keys = held_keys.clone();
            let shortcuts = shortcuts.clone();
            let last_trigger = last_trigger.clone();
            let initial_path = path.clone();

            std::thread::spawn(move || {
                let device_name = device.name().unwrap_or("unknown").to_string();
                let mut current_path = initial_path.clone();
                let mut device = Some(device);
                let mut consecutive_errors = 0u32;
                let mut reconnect_attempts = 0u32;
                while running.load(Ordering::SeqCst) {
                    if device.is_none() {
                        reconnect_attempts += 1;
                        if reconnect_attempts == 1 || reconnect_attempts.is_multiple_of(10) {
                            tracing::warn!(
                                "[evdev] Reopening keyboard '{}' (attempt {}) from {:?}",
                                device_name,
                                reconnect_attempts,
                                current_path
                            );
                        }
                        match Self::reopen_keyboard_device(&current_path, &device_name) {
                            Ok((reopened, new_path)) => {
                                if new_path != current_path {
                                    tracing::info!(
                                        "[evdev] Keyboard '{}' moved from {:?} to {:?}",
                                        device_name,
                                        current_path,
                                        new_path
                                    );
                                }
                                tracing::info!(
                                    "[evdev] Keyboard '{}' listener recovered on {:?}",
                                    device_name,
                                    new_path
                                );
                                current_path = new_path;
                                held_keys.lock().unwrap().clear();
                                consecutive_errors = 0;
                                reconnect_attempts = 0;
                                device = Some(reopened);
                            }
                            Err(e) => {
                                if reconnect_attempts == 1 || reconnect_attempts.is_multiple_of(10) {
                                    tracing::warn!(
                                        "[evdev] Reopen failed for '{}' on {:?}: {}",
                                        device_name,
                                        current_path,
                                        e
                                    );
                                }
                                std::thread::sleep(std::time::Duration::from_secs(1));
                                continue;
                            }
                        }
                    }

                    let mut should_reconnect = false;
                    {
                        let Some(device_ref) = device.as_mut() else {
                            continue;
                        };
                        match device_ref.fetch_events() {
                            Ok(events) => {
                                consecutive_errors = 0;
                                for ev in events {
                                    // 只处理键盘按键事件，忽略鼠标移动/滚轮/同步事件
                                    if ev.event_type() != evdev::EventType::KEY {
                                        continue;
                                    }
                                    let code = ev.code();
                                    if code == 0 {
                                        // KEY_RESERVED，忽略无效事件
                                        continue;
                                    }
                                    let value = ev.value();
                                    if value == 1 {
                                        held_keys.lock().unwrap().insert(code);
                                        let keys = held_keys.lock().unwrap();
                                        tracing::debug!("[evdev] key down: code={} held={:?}", code, *keys);
                                        for (mods, trigger, action) in &shortcuts {
                                            if code == *trigger && mods.iter().all(|m| keys.contains(m)) {
                                                let now = Instant::now();
                                                let mut lt = last_trigger.lock().unwrap();
                                                let last = lt.get(action).copied().unwrap_or(Instant::now() - Duration::from_secs(1));
                                                if now.duration_since(last).as_millis() < 400 { continue; }
                                                lt.insert(action.clone(), now);
                                                drop(lt);
                                                tracing::info!("[evdev] Hotkey triggered: {}", action);
                                                let _ = tx.blocking_send(action.clone());
                                            }
                                        }
                                    } else if value == 0 {
                                        held_keys.lock().unwrap().remove(&code);
                                        tracing::debug!("[evdev] key up: code={}", code);
                                    }
                                }
                            }
                            Err(e) => {
                                consecutive_errors += 1;
                                if consecutive_errors == 1 || consecutive_errors.is_multiple_of(50) {
                                    tracing::warn!(
                                        "[evdev] fetch_events error on {} at {:?} ({} consecutive): {}",
                                        device_name, current_path, consecutive_errors, e
                                    );
                                }
                                if consecutive_errors > 100 {
                                    tracing::error!(
                                        "[evdev] Device {} at {:?} appears disconnected, entering recovery",
                                        device_name,
                                        current_path
                                    );
                                    should_reconnect = true;
                                } else {
                                    std::thread::sleep(std::time::Duration::from_millis(100));
                                }
                            }
                        }
                    }

                    if should_reconnect {
                        held_keys.lock().unwrap().clear();
                        device = None;
                        consecutive_errors = 0;
                        std::thread::sleep(std::time::Duration::from_secs(1));
                        continue;
                    }
                }
                tracing::info!(
                    "[evdev] Listener thread exited for device: {} at {:?}",
                    device_name,
                    current_path
                );
            });
        }

        if opened == 0 {
            return Err(HotkeyError::NoKeyboardDevices);
        }

        tracing::info!("Evdev listener started ({} keyboard devices opened)", opened);
        Ok(())
    }
}
