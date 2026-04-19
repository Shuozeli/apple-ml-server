use crate::error::AppleMlError;
use crate::types::{
    OcrParams, OcrRequest, OcrResponse, TranscribeParams, TranscribeRequest, TranscribeResponse,
};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use reqwest::Client;
use std::time::Duration;

pub struct AppleMlClient {
    base_url: String,
    http_client: Client,
}

impl AppleMlClient {
    pub fn builder() -> AppleMlClientBuilder {
        AppleMlClientBuilder::default()
    }

    pub async fn health(&self) -> Result<String, AppleMlError> {
        let url = format!("{}/health", self.base_url);
        let resp = self.http_client.get(&url).send().await?;
        let text = resp.text().await?;
        Ok(text)
    }

    pub async fn transcribe(
        &self,
        audio: &[u8],
        format: Option<&str>,
        params: TranscribeParams,
    ) -> Result<TranscribeResponse, AppleMlError> {
        let audio_b64 = BASE64.encode(audio);

        let request = TranscribeRequest {
            audio: audio_b64,
            format: format.map(String::from),
            language: params.language,
            timestamps: if params.timestamps { Some(true) } else { None },
            timeout: params.timeout_secs,
        };

        self.transcribe_raw(request).await
    }

    pub async fn transcribe_raw(
        &self,
        request: TranscribeRequest,
    ) -> Result<TranscribeResponse, AppleMlError> {
        let url = format!("{}/transcribe", self.base_url);
        let resp = self.http_client.post(&url).json(&request).send().await?;

        let status = resp.status();
        if status.is_success() {
            let result: TranscribeResponse = resp.json().await?;
            if let Some(err) = &result.error {
                return Err(AppleMlError::Application(err.clone()));
            }
            Ok(result)
        } else {
            Err(status.into())
        }
    }

    pub async fn ocr(&self, image: &[u8], params: OcrParams) -> Result<OcrResponse, AppleMlError> {
        let image_b64 = BASE64.encode(image);

        let request = OcrRequest {
            image: image_b64,
            language: params.language,
        };

        self.ocr_raw(request).await
    }

    pub async fn ocr_raw(&self, request: OcrRequest) -> Result<OcrResponse, AppleMlError> {
        let url = format!("{}/ocr", self.base_url);
        let resp = self.http_client.post(&url).json(&request).send().await?;

        let status = resp.status();
        if status.is_success() {
            let result: OcrResponse = resp.json().await?;
            if let Some(err) = &result.error {
                return Err(AppleMlError::Application(err.clone()));
            }
            Ok(result)
        } else {
            Err(status.into())
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct AppleMlClientBuilder {
    endpoint: Option<String>,
    timeout: Option<Duration>,
}

impl AppleMlClientBuilder {
    pub fn endpoint(mut self, endpoint: impl Into<String>) -> Self {
        self.endpoint = Some(endpoint.into());
        self
    }

    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }

    pub fn build(self) -> AppleMlClient {
        let http_client = Client::builder()
            .timeout(self.timeout.unwrap_or(Duration::from_secs(300)))
            .build()
            .expect("Failed to create HTTP client");

        AppleMlClient {
            base_url: self
                .endpoint
                .unwrap_or_else(|| "http://localhost:8080".to_string()),
            http_client,
        }
    }
}
