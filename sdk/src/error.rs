use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppleMlError {
    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    #[error("Server error: {0}")]
    Server(String),

    #[error("Application error: {0}")]
    Application(String),

    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}

impl From<reqwest::StatusCode> for AppleMlError {
    fn from(status: reqwest::StatusCode) -> Self {
        match status.as_u16() {
            400 => AppleMlError::InvalidRequest(format!("HTTP {}", status)),
            403 => AppleMlError::Application(format!("HTTP {}", status)),
            500..=599 => AppleMlError::Server(format!("HTTP {}", status)),
            _ => AppleMlError::Application(format!("HTTP {}", status)),
        }
    }
}

impl AppleMlError {
    pub fn status_code(&self) -> Option<u16> {
        match self {
            AppleMlError::InvalidRequest(msg) => parse_status(msg),
            AppleMlError::Server(msg) => parse_status(msg),
            AppleMlError::Application(msg) => parse_status(msg),
            AppleMlError::Network(_) | AppleMlError::Json(_) => None,
        }
    }
}

fn parse_status(msg: &str) -> Option<u16> {
    msg.split_whitespace()
        .find(|w| w.chars().all(|c| c.is_ascii_digit()))
        .and_then(|w| w.parse().ok())
}
