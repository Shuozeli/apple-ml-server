use anyhow::{Context, Result};
use apple_ml_sdk::{AppleMlClient, OcrParams, TranscribeParams};
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::time::Instant;

/// Apple ML CLI - Client for Apple ML Server
#[derive(Parser)]
#[command(name = "apple-ml")]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// Server endpoint URL
    #[arg(
        short,
        long,
        env = "APPLE_ML_ENDPOINT",
        default_value = "http://localhost:8080"
    )]
    endpoint: String,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Transcribe audio to text
    Transcribe {
        /// Path to audio file
        #[arg(short, long)]
        file: PathBuf,

        /// Audio format (wav, mp3, m4a, flac). Auto-detected from extension if not specified.
        #[arg(short = 'F', long)]
        format: Option<String>,

        /// Language code (e.g., en-US, zh-CN)
        #[arg(short, long)]
        language: Option<String>,

        /// Include word-level timestamps
        #[arg(short, long, default_value = "false")]
        timestamps: bool,

        /// Timeout in seconds
        #[arg(short = 'T', long, default_value = "300")]
        timeout: u32,

        /// Output format (text, json)
        #[arg(short, long, default_value = "text")]
        output: String,
    },

    /// Perform OCR on an image
    Ocr {
        /// Path to image file
        #[arg(short, long)]
        file: PathBuf,

        /// Language code (e.g., en-US, zh-CN)
        #[arg(short, long)]
        language: Option<String>,

        /// Output format (text, json)
        #[arg(short, long, default_value = "text")]
        output: String,
    },

    /// Check server health
    Health,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    let client = AppleMlClient::builder()
        .endpoint(&cli.endpoint)
        .timeout(std::time::Duration::from_secs(600))
        .build();

    match cli.command {
        Commands::Health => {
            let start = Instant::now();
            let resp = client.health().await;
            let elapsed = start.elapsed();

            match resp {
                Ok(_body) => {
                    println!("OK");
                    eprintln!("Server healthy ({:.0}ms)", elapsed.as_millis());
                }
                Err(e) => {
                    println!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }

        Commands::Transcribe {
            file,
            format,
            language,
            timestamps,
            timeout,
            output,
        } => {
            // Read file into memory
            let audio_data = std::fs::read(&file)
                .with_context(|| format!("Failed to read file: {}", file.display()))?;

            // Auto-detect format from extension
            let format =
                format.or_else(|| file.extension().and_then(|e| e.to_str()).map(String::from));

            let params = TranscribeParams {
                language,
                timestamps,
                timeout_secs: Some(timeout),
            };

            eprintln!("Transcribing {}...", file.display());
            let start = Instant::now();

            let result = client
                .transcribe(&audio_data, format.as_deref(), params)
                .await;

            let elapsed = start.elapsed();

            match result {
                Ok(result) => match output.as_str() {
                    "json" => {
                        println!("{}", serde_json::to_string_pretty(&result)?);
                    }
                    _ => {
                        println!("{}", result.transcript);
                        eprintln!(
                            "\n---\nLanguage: {}, Confidence: {:.1}%, Time: {:.1}s (server: {}ms)",
                            result.language,
                            result.confidence * 100.0,
                            elapsed.as_secs_f64(),
                            result.processing_time_ms
                        );
                        if let Some(words) = &result.words {
                            eprintln!("Words: {}", words.len());
                        }
                    }
                },
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }

        Commands::Ocr {
            file,
            language,
            output,
        } => {
            // Read file into memory
            let image_data = std::fs::read(&file)
                .with_context(|| format!("Failed to read file: {}", file.display()))?;

            let params = OcrParams { language };

            eprintln!("Processing {}...", file.display());
            let start = Instant::now();

            let result = client.ocr(&image_data, params).await;

            let elapsed = start.elapsed();

            match result {
                Ok(result) => match output.as_str() {
                    "json" => {
                        println!("{}", serde_json::to_string_pretty(&result)?);
                    }
                    _ => {
                        println!("{}", result.text);
                        eprintln!(
                            "\n---\nBlocks: {}, Confidence: {:.1}%, Time: {:.1}s (server: {}ms)",
                            result.blocks.len(),
                            result.confidence * 100.0,
                            elapsed.as_secs_f64(),
                            result.processing_time_ms
                        );
                    }
                },
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
    }

    Ok(())
}
