use apple_ml_sdk::types::{BoundingBox, OcrResponse, TextBlock, TranscribeResponse, WordTiming};
use apple_ml_sdk::{AppleMlClient, OcrParams, TranscribeParams};
use mockito::Server;

#[tokio::test]
async fn test_health_success() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("GET", "/health")
        .match_header("accept", "*/*")
        .with_body("OK")
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client.health().await;

    mock.assert_async().await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), "OK");
}

#[tokio::test]
async fn test_transcribe_success() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/transcribe")
        .match_header("content-type", "application/json")
        .match_body(mockito::Matcher::Regex(
            r#""audio":"ZmFrZSBhdWRpbyBkYXRh""#.to_string(),
        ))
        .with_body(
            serde_json::to_string(&TranscribeResponse {
                transcript: "Hello world".to_string(),
                confidence: 0.95,
                language: "en-US".to_string(),
                words: Some(vec![WordTiming {
                    word: "Hello".to_string(),
                    confidence: 0.98,
                    start_ms: 0,
                    end_ms: 500,
                }]),
                processing_time_ms: 1234,
                error: None,
            })
            .unwrap(),
        )
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .transcribe(
            b"fake audio data",
            Some("wav"),
            TranscribeParams {
                language: Some("en-US".to_string()),
                timestamps: true,
                timeout_secs: Some(300),
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.transcript, "Hello world");
    assert_eq!(response.confidence, 0.95);
    assert_eq!(response.language, "en-US");
    assert!(response.words.is_some());
}

#[tokio::test]
async fn test_transcribe_server_error() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/transcribe")
        .match_header("content-type", "application/json")
        .with_status(500)
        .with_body("Internal Server Error")
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .transcribe(
            b"fake audio data",
            Some("wav"),
            TranscribeParams {
                language: None,
                timestamps: false,
                timeout_secs: None,
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert_eq!(err.status_code(), Some(500));
}

#[tokio::test]
async fn test_transcribe_not_authorized() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/transcribe")
        .match_header("content-type", "application/json")
        .with_status(403)
        .with_body("Forbidden")
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .transcribe(
            b"fake audio data",
            Some("wav"),
            TranscribeParams {
                language: None,
                timestamps: false,
                timeout_secs: None,
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert_eq!(err.status_code(), Some(403));
}

#[tokio::test]
async fn test_transcribe_bad_request() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/transcribe")
        .match_header("content-type", "application/json")
        .with_status(400)
        .with_body("Bad Request")
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .transcribe(
            b"fake audio data",
            Some("wav"),
            TranscribeParams {
                language: None,
                timestamps: false,
                timeout_secs: None,
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert_eq!(err.status_code(), Some(400));
}

#[tokio::test]
async fn test_ocr_success() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/ocr")
        .match_header("content-type", "application/json")
        .match_body(mockito::Matcher::Regex(
            r#""image":"ZmFrZSBpbWFnZSBkYXRh""#.to_string(),
        ))
        .with_body(
            serde_json::to_string(&OcrResponse {
                text: "Hello world".to_string(),
                blocks: vec![TextBlock {
                    text: "Hello world".to_string(),
                    confidence: 0.92,
                    bounding_box: BoundingBox {
                        x_min: 0.1,
                        y_min: 0.2,
                        x_max: 0.9,
                        y_max: 0.3,
                    },
                }],
                confidence: 0.92,
                processing_time_ms: 567,
                error: None,
            })
            .unwrap(),
        )
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .ocr(
            b"fake image data",
            OcrParams {
                language: Some("en-US".to_string()),
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.text, "Hello world");
    assert_eq!(response.blocks.len(), 1);
    assert_eq!(response.confidence, 0.92);
}

#[tokio::test]
async fn test_ocr_server_error() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/ocr")
        .match_header("content-type", "application/json")
        .with_status(500)
        .with_body("Recognition failed")
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .ocr(b"fake image data", OcrParams { language: None })
        .await;

    mock.assert_async().await;
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert_eq!(err.status_code(), Some(500));
}

#[tokio::test]
async fn test_client_builder_default_endpoint() {
    let client = AppleMlClient::builder().build();

    let result = client.health().await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_client_builder_custom_timeout() {
    let client = AppleMlClient::builder()
        .endpoint("http://localhost:9999")
        .timeout(std::time::Duration::from_secs(1))
        .build();

    let result = client.health().await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_transcribe_with_format() {
    let mut server = Server::new_async().await;
    let mock = server
        .mock("POST", "/transcribe")
        .match_header("content-type", "application/json")
        .match_body(mockito::Matcher::Regex(r#""format":"m4a""#.to_string()))
        .with_body(
            serde_json::to_string(&TranscribeResponse {
                transcript: "Test".to_string(),
                confidence: 0.9,
                language: "en-US".to_string(),
                words: None,
                processing_time_ms: 100,
                error: None,
            })
            .unwrap(),
        )
        .create_async()
        .await;

    let client = AppleMlClient::builder().endpoint(server.url()).build();

    let result = client
        .transcribe(
            b"fake audio",
            Some("m4a"),
            TranscribeParams {
                language: None,
                timestamps: false,
                timeout_secs: None,
            },
        )
        .await;

    mock.assert_async().await;
    assert!(result.is_ok());
}
