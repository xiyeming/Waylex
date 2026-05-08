use async_trait::async_trait;
use crate::ffi::types::{DesktopEnv, OcrResult, ShortcutBinding};
use crate::ffi::error::{ClipboardError, HotkeyError, OcrError, TrayError};

pub mod common;

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "macos")]
mod macos;

/// 平台能力抽象 trait
///
/// 所有平台相关功能（热键、剪贴板、截图/OCR、托盘、环境检测）
/// 通过此 trait 统一暴露，FFI bridge.rs 通过全局单例调用。
#[async_trait]
pub trait PlatformBackend: Send + Sync {
    // ==================== 热键 ====================

    /// 注册一组全局热键
    async fn register_hotkeys(&self, shortcuts: Vec<ShortcutBinding>) -> Result<(), HotkeyError>;

    /// 注销所有已注册的热键
    fn unregister_hotkeys(&self) -> Result<(), HotkeyError>;

    /// 轮询热键事件（非阻塞）
    /// 返回热键对应的 action 字符串，若无事件则返回 None
    fn poll_hotkey_event(&self) -> Option<String>;

    // ==================== 剪贴板 ====================

    /// 获取剪贴板中的纯文本内容
    fn get_clipboard_text(&self) -> Result<String, ClipboardError>;

    /// 设置剪贴板纯文本内容
    fn set_clipboard_text(&self, text: String) -> Result<(), ClipboardError>;

    // ==================== 截图与 OCR ====================

    /// 截取屏幕选区或全屏，返回 PNG 图像字节
    async fn screenshot(&self) -> Result<Vec<u8>, OcrError>;

    /// 对图像数据进行 OCR 识别
    async fn recognize(&self, image_data: Vec<u8>, lang: String) -> Result<OcrResult, OcrError>;

    // ==================== 系统托盘 ====================

    /// 初始化系统托盘图标与菜单
    async fn init_tray(&self) -> Result<(), TrayError>;

    /// 显示托盘通知气泡
    fn show_tray_notification(&self, title: &str, body: &str) -> Result<(), TrayError>;

    // ==================== 环境信息 ====================

    /// 检测当前桌面环境
    fn detect_desktop_env(&self) -> DesktopEnv;
}

/// 平台工厂：根据编译目标创建对应后端
pub fn create_platform_backend() -> Box<dyn PlatformBackend> {
    #[cfg(target_os = "linux")]
    return Box::new(linux::LinuxBackend::new());

    #[cfg(target_os = "windows")]
    return Box::new(windows::WindowsBackend::new());

    #[cfg(target_os = "macos")]
    return Box::new(macos::MacOsBackend::new());
}

/// 全局平台后端单例
static PLATFORM: once_cell::sync::OnceCell<Box<dyn PlatformBackend>> =
    once_cell::sync::OnceCell::new();

/// 初始化平台后端（在 Flutter 应用启动时调用）
pub fn init_platform() -> Result<(), PlatformInitError> {
    let backend = create_platform_backend();
    PLATFORM
        .set(backend)
        .map_err(|_| PlatformInitError::AlreadyInitialized)
}

/// 获取已初始化的平台后端实例
pub fn platform() -> &'static dyn PlatformBackend {
    PLATFORM.get().expect("Platform backend not initialized. Call init_platform() first.").as_ref()
}

/// 平台初始化错误
#[derive(Debug, thiserror::Error)]
pub enum PlatformInitError {
    #[error("Platform backend already initialized")]
    AlreadyInitialized,
}
