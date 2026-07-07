use crate::ffi::error::OcrError;
use std::fs;
use std::process::Command;

/// 通用截图实现，被不同桌面环境调用
pub struct DesktopScreenshot;

impl DesktopScreenshot {
    /// 根据桌面环境选择截图方式
    pub fn capture(env: &crate::ffi::types::DesktopEnv) -> Result<Vec<u8>, OcrError> {
        match env {
            crate::ffi::types::DesktopEnv::KdePlasma => Self::capture_with_spectacle(),
            crate::ffi::types::DesktopEnv::Hyprland => Self::capture_grim_area(),
            crate::ffi::types::DesktopEnv::Gnome => Self::capture_with_gnome(),
            crate::ffi::types::DesktopEnv::Unknown => Err(OcrError::PermissionDenied),
        }
    }

    /// KDE: 优先使用 spectacle，回退 grim
    fn capture_with_spectacle() -> Result<Vec<u8>, OcrError> {
        if Self::has_spectacle() {
            let temp_file = tempfile::NamedTempFile::new()
                .map_err(|e| OcrError::IoError(e))?
                .into_temp_path();

            let output = Command::new("spectacle")
                .args(["-r", "-b", "-n", "-o"])
                .arg(temp_file.as_os_str())
                .output()
                .map_err(OcrError::CommandError)?;

            if !output.status.success() {
                return Err(OcrError::ScreenshotFailed);
            }

            let data = fs::read(&temp_file).map_err(OcrError::IoError)?;

            if data.is_empty() {
                return Err(OcrError::NoTextDetected);
            }

            return Ok(data);
        }

        // 回退到 grim
        Self::capture_grim_area()
    }

    /// GNOME: 使用 gnome-screenshot
    fn capture_with_gnome() -> Result<Vec<u8>, OcrError> {
        let temp_file = tempfile::NamedTempFile::new()
            .map_err(|e| OcrError::IoError(e))?
            .into_temp_path();

        let output = Command::new("gnome-screenshot")
            .args(["-a", "-f"])
            .arg(temp_file.as_os_str())
            .output()
            .map_err(OcrError::CommandError)?;

        if !output.status.success() {
            return Err(OcrError::ScreenshotFailed);
        }

        let data = fs::read(&temp_file).map_err(OcrError::IoError)?;
        Ok(data)
    }

    /// 通用: 使用 slurp + grim 截图
    fn capture_grim_area() -> Result<Vec<u8>, OcrError> {
        let slurp = Command::new("slurp")
            .arg("-d")
            .output()
            .map_err(OcrError::CommandError)?;

        if !slurp.status.success() {
            return Err(OcrError::UserCancelled);
        }

        let area = String::from_utf8_lossy(&slurp.stdout).trim().to_string();
        if area.is_empty() {
            return Err(OcrError::UserCancelled);
        }

        let output = Command::new("grim")
            .args(["-g", &area, "-t", "png", "-"])
            .output()
            .map_err(OcrError::CommandError)?;

        if !output.status.success() {
            return Err(OcrError::ScreenshotFailed);
        }

        Ok(output.stdout)
    }

    fn has_spectacle() -> bool {
        Command::new("which")
            .arg("spectacle")
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false)
    }
}
