use crate::ffi::error::ConfigError;
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use base64::{engine::general_purpose, Engine as _};
use hkdf::Hkdf;
use sha2::Sha256;
use sqlx::Row;
use tracing::warn;

const SERVICE_NAME: &str = "xym-ft";

/// 设备唯一标识，用于派生加密密钥。
/// 使用 machine-id 或 fallback 到固定字符串（非 ideal，但比明文好）。
fn device_identity() -> [u8; 32] {
    let mut id = Vec::new();

    // 优先读取 /etc/machine-id
    if let Ok(content) = std::fs::read_to_string("/etc/machine-id") {
        id.extend_from_slice(content.trim().as_bytes());
    }
    // fallback: 用户 ID
    if let Ok(uid) = std::env::var("XDG_RUNTIME_DIR") {
        id.extend_from_slice(uid.as_bytes());
    }
    // 最终 fallback
    if id.is_empty() {
        id.extend_from_slice(b"waylex-default-identity");
    }

    // 用 HKDF-SHA256 派生固定长度的密钥素材
    let hkdf = Hkdf::<Sha256>::new(None, &id);
    let mut okm = [0u8; 32];
    hkdf.expand(b"waylex-api-key-encryption-v1", &mut okm)
        .expect("HKDF expansion should never fail with fixed output length");

    okm
}

/// 使用 AES-256-GCM 加密 API Key。
/// 返回格式: base64(nonce || ciphertext)
fn encrypt_api_key(plaintext: &str) -> Result<String, ConfigError> {
    let key_bytes = device_identity();
    let cipher = Aes256Gcm::new(&key_bytes.into());

    let nonce_bytes: [u8; 12] = rand::random();
    let nonce = Nonce::from(nonce_bytes);

    let ciphertext = cipher
        .encrypt(&nonce, plaintext.as_bytes())
        .map_err(|e| ConfigError::SecretError(format!("Encryption failed: {}", e)))?;

    let mut result = nonce_bytes.to_vec();
    result.extend_from_slice(&ciphertext);
    Ok(general_purpose::STANDARD.encode(&result))
}

/// 解密 API Key
fn decrypt_api_key(encoded: &str) -> Result<String, ConfigError> {
    let data = general_purpose::STANDARD
        .decode(encoded)
        .map_err(|e| ConfigError::SecretError(format!("Base64 decode failed: {}", e)))?;

    if data.len() < 12 {
        return Err(ConfigError::SecretError("Ciphertext too short".into()));
    }

    let (nonce_bytes, ciphertext) = data.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);

    let key_bytes = device_identity();
    let cipher = Aes256Gcm::new(&key_bytes.into());

    let plaintext = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| ConfigError::SecretError(format!("Decryption failed: {}", e)))?;

    String::from_utf8(plaintext).map_err(ConfigError::Utf8Error)
}

/// 优先从 keyring 读取，回退到加密的 SQLite 存储。
pub async fn get_api_key(provider_id: &str) -> Result<String, ConfigError> {
    // 1. 优先尝试 keyring
    match get_from_keyring(provider_id) {
        Ok(key) => return Ok(key),
        Err(_) => {
            // keyring 不可用时回退到 SQLite
        }
    }

    // 2. 回退到 SQLite 加密存储
    get_from_sqlite(provider_id).await
}

/// 优先写入 keyring，同时写入加密的 SQLite 作为备份。
/// keyring 失败时记录警告，SQLite 写入也失败时才报错。
pub async fn set_api_key(provider_id: &str, api_key: &str) -> Result<(), ConfigError> {
    // 先尝试写入 keyring
    let keyring_result = set_to_keyring(provider_id, api_key);
    if keyring_result.is_err() {
        warn!(
            "Failed to store API key in system keyring for '{}': {:?}. Falling back to encrypted SQLite.",
            provider_id, keyring_result
        );
    }

    // 总是写入加密的 SQLite 作为可靠回退
    set_to_sqlite_encrypted(provider_id, api_key).await?;

    Ok(())
}

/// 同时从 keyring 和 SQLite 删除
pub async fn delete_api_key(provider_id: &str) -> Result<(), ConfigError> {
    let _ = delete_from_keyring(provider_id);
    delete_from_sqlite(provider_id).await
}

fn get_from_keyring(provider_id: &str) -> Result<String, ConfigError> {
    let entry = keyring::Entry::new(SERVICE_NAME, provider_id)
        .map_err(|e| ConfigError::KeyNotFound(e.to_string()))?;
    entry.get_password()
        .map_err(|_| ConfigError::KeyNotFound("keyring entry not found".to_string()))
}

fn set_to_keyring(provider_id: &str, api_key: &str) -> Result<(), ConfigError> {
    let entry = keyring::Entry::new(SERVICE_NAME, provider_id)
        .map_err(|e| ConfigError::KeyNotFound(e.to_string()))?;
    entry.set_password(api_key)
        .map_err(|e| ConfigError::KeyNotFound(e.to_string()))
}

fn delete_from_keyring(provider_id: &str) -> Result<(), ConfigError> {
    let entry = keyring::Entry::new(SERVICE_NAME, provider_id)
        .map_err(|e| ConfigError::KeyNotFound(e.to_string()))?;
    entry.delete_credential()
        .map_err(|e| ConfigError::KeyNotFound(e.to_string()))
}

async fn get_from_sqlite(provider_id: &str) -> Result<String, ConfigError> {
    let pool = crate::config::storage::get_pool().await?;
    let row = sqlx::query("SELECT api_key FROM provider_keys WHERE provider_id = $1")
        .bind(provider_id)
        .fetch_optional(&pool)
        .await
        .map_err(ConfigError::DbError)?;

    match row {
        Some(row) => {
            let encrypted: String = row.get("api_key");
            decrypt_api_key(&encrypted)
        }
        None => Err(ConfigError::KeyNotFound("api key not found".to_string())),
    }
}

async fn set_to_sqlite_encrypted(provider_id: &str, api_key: &str) -> Result<(), ConfigError> {
    let encrypted = encrypt_api_key(api_key)?;
    let pool = crate::config::storage::get_pool().await?;
    sqlx::query(
        r#"INSERT INTO provider_keys (provider_id, api_key) VALUES ($1, $2)
           ON CONFLICT(provider_id) DO UPDATE SET api_key = $2"#,
    )
    .bind(provider_id)
    .bind(encrypted)
    .execute(&pool)
    .await
    .map_err(ConfigError::DbError)?;
    Ok(())
}

async fn delete_from_sqlite(provider_id: &str) -> Result<(), ConfigError> {
    let pool = crate::config::storage::get_pool().await?;
    sqlx::query("DELETE FROM provider_keys WHERE provider_id = $1")
        .bind(provider_id)
        .execute(&pool)
        .await
        .map_err(ConfigError::DbError)?;
    Ok(())
}
