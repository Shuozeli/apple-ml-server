<!-- agent-updated: 2026-04-21T06:00:00Z -->

# Tasks

## Pending

### App Polish

- [ ] Add app icon
- [ ] **Launch at login**: Implement via `SMAppService`
- [ ] **Distribution**: DMG or Homebrew cask packaging
- [ ] **Tests**: Unit tests for Core services
- [ ] **PDF OCR support**: Pre-convert PDFs to images within the app
- [ ] **Live recording**: Microphone input for real-time transcription

### Future ML Features

Features tracked for potential addition. Not currently planned for implementation.

#### Translation (Translation framework, macOS 14+)
- On-device translation between ~30 languages
- Chains with transcription: transcribe audio then translate
- **Constraint**: SwiftUI-only API (`TranslationSession` requires `.translationTask()` view modifier), needs architectural workaround for headless/API mode
- No permissions required; language packs download on demand

#### Image Classification (Vision, macOS 10.15+)
- Classify images into 1000+ categories (scenes, objects, activities)
- `VNClassifyImageRequest` / `ClassifyImageRequest`
- No permissions required
- Could add as metadata alongside OCR results

#### Barcode/QR Detection (Vision, macOS 10.13+)
- Detect and decode QR codes, EAN, Code128, Aztec, PDF417, DataMatrix
- `VNDetectBarcodesRequest` / `DetectBarcodesRequest`
- No permissions required

#### Face Detection (Vision, macOS 10.13+)
- Detect faces with 76 facial landmarks
- Face capture quality scoring
- `VNDetectFaceLandmarksRequest` / `DetectFaceLandmarksRequest`
- No permissions required

#### Person Segmentation (Vision, macOS 12.0+)
- Remove/isolate background from photos (portrait mode effect)
- Three quality levels: `.fast`, `.balanced`, `.accurate`
- `VNGeneratePersonSegmentationRequest`
- No permissions required

#### Sound Classification (SoundAnalysis, macOS 12.0+)
- Classify 300+ sound types (speech, music, animals, environment, vehicles, household)
- Built-in classifier via `SNClassifySoundRequest(classifierIdentifier: .version1)`
- Could auto-classify audio before transcription
- No permissions required for audio files

#### Sentiment Analysis (NaturalLanguage, macOS 11.0+)
- Score text from -1.0 (negative) to +1.0 (positive)
- `NLTagger` with `.sentimentScore` scheme
- Could run as post-processing on transcription results
- No permissions required

#### Named Entity Recognition (NaturalLanguage, macOS 10.14+)
- Extract person names, places, organizations from text
- `NLTagger` with `.nameType` scheme
- Post-processing on transcription/OCR results
- No permissions required

#### Text Embeddings & Similarity (NaturalLanguage, macOS 10.15+)
- Word and sentence embeddings for semantic similarity
- `NLEmbedding` (static) and `NLContextualEmbedding` (BERT-based, macOS 14+)
- Nearest-neighbor search, semantic clustering
- No permissions required

#### Image Aesthetics Scoring (Vision, macOS 15.0+)
- Rate photo quality (composition, lighting)
- `CalculateImageAestheticsScoresRequest`
- Requires macOS 15+

#### Image Similarity (Vision, macOS 10.15+)
- Generate feature vectors for images, compute distance
- `VNGenerateImageFeaturePrintRequest`
- Duplicate/similar image detection

#### Subject Lifting (VisionKit, macOS 14.0+)
- Extract foreground object with transparent background
- `ImageAnalyzer` + `.generateSubjectImage()`

#### Document Detection (Vision, macOS 12.0+)
- Find document boundaries for perspective correction
- `VNDetectDocumentSegmentationRequest`

#### Body/Hand Pose Detection (Vision, macOS 11.0+)
- Detect skeleton joints (19 body, 21 hand per hand)
- `VNDetectHumanBodyPoseRequest`, `VNDetectHumanHandPoseRequest`
- 3D body pose available on macOS 14+

#### Custom Model Inference (CoreML, macOS 10.13+)
- Run any CoreML model (Whisper, YOLO, Stable Diffusion, custom classifiers)
- Convert from PyTorch/TensorFlow/ONNX via `coremltools`
- ANE acceleration for supported operations

## In Progress

## Completed

- [x] Swift Vapor REST API server (2026-04-20)
- [x] Rust CLI client with clap (2026-04-20)
- [x] Rust SDK library (2026-04-20)
- [x] OpenAPI 3.0 specification (2026-04-20)
- [x] OCR with Vision.framework (2026-04-20)
- [x] Transcription with Speech.framework (2026-04-20)
- [x] Language auto-detection (2026-04-20)
- [x] Info.plist embedding for TCC permissions (2026-04-20)
- [x] CORS middleware (2026-04-20)
- [x] Health check and version endpoints (2026-04-20)
- [x] Xcode project with macOS app target (2026-04-20)
- [x] Core services migrated to app (2026-04-20)
- [x] ServerManager with embedded Vapor (2026-04-20)
- [x] Routes + OpenAPI spec (2026-04-20)
- [x] Headless --serve mode (2026-04-20)
- [x] Menu bar icon with server status (2026-04-20)
- [x] NavigationSplitView with sidebar history + feature cards (2026-04-20)
- [x] TranscribeView with drag-drop (2026-04-20)
- [x] OCRView with drag-drop and image preview (2026-04-20)
- [x] SwiftData history (HistoryItem + HistoryStore) (2026-04-20)
- [x] History delete and clear all (2026-04-20)
- [x] Settings view (2026-04-20)
- [x] Speech Recognition permission on app startup (2026-04-20)

## Known Issues

- **Sequential language detection**: Detection tries locales one at a time because Speech.framework doesn't handle concurrent recognitions reliably. Adds ~10-20s overhead when language is not specified.
- **OCR images only**: PDFs must be pre-converted to images before OCR.
- **Translation API**: SwiftUI-only (`TranslationSession` requires view modifier), making headless API support non-trivial.
