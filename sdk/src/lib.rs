//! apple-ml-sdk - Rust client library for Apple ML Server
//!
//! Provides async client for speech-to-text (Speech.framework) and OCR
//! (Vision.framework) endpoints.

pub mod client;
pub mod error;
pub mod types;

pub use client::{AppleMlClient, AppleMlClientBuilder};
pub use error::AppleMlError;
pub use types::{
    BoundingBox, OcrParams, OcrRequest, OcrResponse, TextBlock, TranscribeParams,
    TranscribeRequest, TranscribeResponse, WordTiming,
};
