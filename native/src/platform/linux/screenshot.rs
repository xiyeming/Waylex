use crate::ffi::error::OcrError;
use crate::ffi::types::DesktopEnv;
use crate::platform::linux::screenshot_impl::DesktopScreenshot as Impl;

/// 委托给共享实现
pub struct DesktopScreenshot;

impl DesktopScreenshot {
    pub fn capture(env: &DesktopEnv) -> Result<Vec<u8>, OcrError> {
        Impl::capture(env)
    }
}
