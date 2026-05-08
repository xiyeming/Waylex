use crate::ffi::error::OcrError;
use crate::ffi::types::OcrResult;

pub struct OcrService;

impl OcrService {
    pub fn new() -> Result<Self, OcrError> {
        Ok(Self)
    }

    pub async fn recognize(&self, image_data: &[u8], lang: &str) -> Result<OcrResult, OcrError> {
        if image_data.is_empty() {
            return Err(OcrError::NoTextDetected);
        }

        let data = image_data.to_vec();
        let lang = lang.to_string();
        tokio::task::spawn_blocking(move || Self::recognize_blocking(&data, &lang))
            .await
            .map_err(|e| {
                OcrError::CommandError(std::io::Error::other(e.to_string()))
            })?
    }

    fn recognize_blocking(image_data: &[u8], lang: &str) -> Result<OcrResult, OcrError> {
        crate::platform::common::ocr_tesseract::recognize_blocking(image_data, lang)
    }
}
