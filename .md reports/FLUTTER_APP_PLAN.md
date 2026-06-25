# MedCam Flutter App — Plan & Architecture

Generated: 17 June 2026

## Goal

Build a Flutter mobile app that uses the system camera to scan/OCR medicine packaging and display detailed medicine information by calling the MedScan backend API.

## Architecture

```
┌──────────────────────────────────────┐       POST /identify (OCR text blocks)      ┌──────────────────────┐
│          Flutter App                 │  ────────────────────────────────────────►   │   FastAPI Backend     │
│  (iOS + Android)                     │  ◄────────────────────────────────────────   │  (Python / Uvicorn)   │
│                                      │       SearchResponse (medicine details)     │                      │
│  ┌──────────────────────────┐        │                                            │  • 226k records       │
│  │  Camera Viewfinder       │        │       POST /search (text query)             │  • Hybrid search      │
│  │  (google_mlkit_camera)   │        │  ────────────────────────────────────────►   │  • Synonyms/abbrev    │
│  └──────────┬───────────────┘        │  ◄────────────────────────────────────────   │  • OCR text parser    │
│             │ capture                │       SearchResponse                        │  • CORS enabled       │
│             ▼                        │                                            └──────────────────────┘
│  ┌──────────────────────────┐        │
│  │  ML Kit OCR              │        │
│  │  (on-device)             │        │
│  └──────────┬───────────────┘        │
│             │ text blocks            │
│             ▼                        │
│  ┌──────────────────────────┐        │
│  │  ApiService              │        │
│  │  (HTTP client)           │        │
│  └──────────┬───────────────┘        │
│             │ response               │
│             ▼                        │
│  ┌──────────────────────────┐        │
│  │  Result / Detail Screen  │        │
│  │  (uses, side_effects,    │        │
│  │   image_url, generic)    │        │
│  └──────────────────────────┘        │
│                                      │
│  ┌──────────────────────────┐        │
│  │  Search Screen (manual)  │        │
│  │  (text input fallback)   │        │
│  └──────────────────────────┘        │
└──────────────────────────────────────┘
```

## Project Structure

```
medcam_app/                          ← Root-level Flutter project
├── lib/
│   ├── main.dart                    ← App entry, MaterialApp, dark theme
│   ├── app.dart                     ← Root widget with navigation
│   │
│   ├── models/
│   │   └── medicine.dart            ← SearchResult, SearchResponse, OcrBlock, IdentifyRequest models
│   │
│   ├── services/
│   │   ├── api_service.dart         ← HTTP client: /search, /identify, /health
│   │   └── settings_service.dart    ← Local prefs: API base URL
│   │
│   ├── screens/
│   │   ├── scan_screen.dart         ← Camera preview + capture + ML Kit OCR → /identify
│   │   ├── search_screen.dart       ← Manual text search → /search → results list
│   │   ├── result_screen.dart       ← Single medicine detail view (uses, side_effects, image)
│   │   └── settings_screen.dart     ← API URL configuration
│   │
│   └── theme/
│       └── app_theme.dart           ← Dark apothecary theme (dark bg, amber/gold accents)
│
├── pubspec.yaml
└── ...
```

## Screens & Navigation

```
ScanScreen ──(capture→OCR→/identify)──→ ResultScreen
      │
      └──(tap search icon)──→ SearchScreen ──(tap result)──→ ResultScreen

SettingsScreen (accessible from app bar)
```

### ScanScreen (Primary)
- Opens device camera via `google_mlkit_camera` / `camera` package
- **Capture button** takes a photo
- Runs **Google ML Kit Text Recognition** on the captured image
- Extracts text blocks with confidence scores
- Calls `POST /identify` with `{"ocr_blocks": [{"text": "...", "confidence": 0.95}, ...]}`
- Navigates to `ResultScreen` on success
- Shows loading spinner during OCR and API call

### SearchScreen (Fallback)
- Text input field with search icon
- Debounced calls to `POST /search`
- Shows results as a scrollable list (medicine name, generic name, match type)
- Tap a result → navigate to `ResultScreen`

### ResultScreen
- Displays full medicine info:
  - **Medicine name** (brand)
  - **Generic name**
  - **Uses** (scrollable text)
  - **Side effects** (scrollable text)
  - **Medicine image** (from `image_url`)
  - **Match type & score**
- Loading, empty, and error states handled

### SettingsScreen
- Text field for backend API base URL (default: `http://127.0.0.1:8000`)
- Saved to shared preferences

## Data Models (Dart)

```dart
class SearchResult {
  final String medicine;
  final String? genericName;
  final double score;
  final String matchType;
  final String? uses;
  final String? sideEffects;
  final String? imageUrl;
}

class SearchResponse {
  final String query;
  final String normalizedQuery;
  final List<SearchResult> results;
}

class OcrBlock {
  final String text;
  final double confidence;
  final Map<String, dynamic>? boundingBox;
}

class IdentifyRequest {
  final List<OcrBlock> ocrBlocks;
  final int topN;
}
```

## Key Dependencies (pubspec.yaml)

| Package | Purpose |
|---|---|
| `google_mlkit_text_recognition` | On-device OCR for text extraction from images |
| `camera` | Camera preview and photo capture |
| `http` | HTTP client for API calls |
| `shared_preferences` | Persist API URL setting |
| `provider` or `riverpod` | State management |

## Dark Apothecary Theme

- **Background**: `#121212` or darker (`#0D0D0D`)
- **Primary**: Amber/Gold (`#FFB300`)
- **Accent**: Deep amber (`#FF8F00`)
- **Surface**: Dark grey (`#1E1E1E`)
- **Text**: Warm white (`#FFF8E1`)
- **Error**: Deep red (`#CF6679`)

## Implementation Phases

### Phase 1: Foundation
1. Create Flutter project, configure `pubspec.yaml`
2. Implement data models (`medicine.dart`)
3. Implement `ApiService` and `SettingsService`

### Phase 2: Screens
4. Build `ScanScreen` — camera + OCR + identify flow
5. Build `ResultScreen` — medicine details display
6. Build `SearchScreen` — manual text search fallback
7. Build `SettingsScreen` — API URL configuration

### Phase 3: Polish
8. Dark apothecary theme applied globally
9. Loading, error, empty state handling on all screens
10. App icon and branding

## Backend API Reference

All endpoints are served by the FastAPI backend (running on configurable host/port):

### `GET /health`
```json
{"status": "ok", "records": 226709, "artifacts_loaded": true}
```

### `POST /search`
Request:
```json
{"query": "paracetamol", "top_n": 10}
```
Response:
```json
{
  "query": "paracetamol",
  "normalized_query": "paracetamol",
  "results": [
    {
      "medicine": "Paracetamol 500mg Tablet",
      "generic_name": "Paracetamol",
      "score": 1.0,
      "match_type": "Exact Generic",
      "uses": "Pain relief, Fever...",
      "side_effects": "Nausea, Dizziness...",
      "image_url": "https://onemg.gumlet.io/..."
    }
  ]
}
```

### `POST /identify`
Request:
```json
{
  "ocr_blocks": [
    {"text": "Dolo", "confidence": 0.95},
    {"text": "650", "confidence": 0.90}
  ],
  "top_n": 5
}
```
Response: Same `SearchResponse` format as `/search`.
