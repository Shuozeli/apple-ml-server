use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Request types
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscribeRequest {
    pub audio: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub language: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timestamps: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OcrRequest {
    pub image: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub language: Option<String>,
}

// ---------------------------------------------------------------------------
// Response types
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscribeResponse {
    pub transcript: String,
    pub confidence: f32,
    pub language: String,
    #[serde(default)]
    pub words: Option<Vec<WordTiming>>,
    pub processing_time_ms: i64,
    #[serde(default)]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WordTiming {
    pub word: String,
    pub confidence: f32,
    pub start_ms: i64,
    pub end_ms: i64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OcrResponse {
    pub text: String,
    pub blocks: Vec<TextBlock>,
    pub confidence: f32,
    pub processing_time_ms: i64,
    #[serde(default)]
    pub error: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TextBlock {
    pub text: String,
    pub confidence: f32,
    pub bounding_box: BoundingBox,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BoundingBox {
    pub x_min: f32,
    pub y_min: f32,
    pub x_max: f32,
    pub y_max: f32,
}

// ---------------------------------------------------------------------------
// Convenience params structs
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default)]
pub struct TranscribeParams {
    pub language: Option<String>,
    pub timestamps: bool,
    pub timeout_secs: Option<u32>,
}

#[derive(Debug, Clone, Default)]
pub struct OcrParams {
    pub language: Option<String>,
}
