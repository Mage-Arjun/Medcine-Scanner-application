# MedScan Backend — Audit & Action Plan

Generated: 16 June 2026

## Goal

Build an app that uses the system camera to scan/OCR medicine packaging and display detailed medicine information. The first priority is a **flawless backend**.

## Tech Stack

- **Backend**: Python, FastAPI, Pandas, RapidFuzz
- **Mobile**: Flutter (planned, not started)
- **Scanning**: Google ML Kit OCR (on-device, planned)

---

## Current Backend Files (all committed)

| File | Purpose |
|---|---|
| `backend/api.py` | FastAPI app — `/search` POST endpoint, startup artifact loading |
| `backend/schemas.py` | Pydantic models: `SearchRequest`, `SearchResult`, `SearchResponse` |
| `backend/artifact_loader.py` | Cached loading of CSVs, config, abbreviation/synonym dicts |
| `backend/query_processor.py` | Query preprocessing: abbreviation expansion, synonym normalization, OCR correction |
| `backend/retrieval_engine.py` | Hybrid search engine: exact + fuzzy + ingredient + synonym matching |
| `backend/__init__.py` | Package marker |

---

## P0 Bugs — Fix First

### 1. OCR rule corrupts valid queries (`query_processor.py:13`)

**Problem**: `(r"i", "l")` replaces **every** `i` with `l` globally with no word boundaries.  
"ibuprofen" → "lbuprolen", "medicine" → "medlcine".

**Fix**: Remove `(r"i", "l")` from `OCR_RULES`. The `i→l` confusion only makes sense in context (e.g., `rn→m` already handles the common OCR error where "m" looks like "rn"). Alternatively, use context-aware rules (e.g., only replace `i` when surrounded by digits/symbols).

### 2. Config weights silently ignored (`retrieval_engine.py:56-57`)

**Problem**: `_weights_from_config()` ignores the loaded config dict and always returns `DEFAULT_WEIGHTS` `(0.5, 0.3, 0.1, 0.1)`. The actual config file specifies `(0.4, 0.3, 0.2, 0.1)`.

**Fix**: Read `cfg["weights"]` and map to the four weight values. Ensure both config files use the same schema.

### 3-4. Column mismatch in search result concatenation (`retrieval_engine.py:112, 221`)

**Problem**: `search_fuzzy()` returns only `["name", "generic_name", "match_type", "match_score", "fuzz_ratio"]` while `exact_res` and `ing_res` have all original DataFrame columns. `pd.concat()` creates a sparse DataFrame with NaN for missing columns. `drop_duplicates()` and `_row_score()` may misbehave.

**Fix**: Standardize the columns returned by all three search functions to include at minimum: `name`, `generic_name`, `match_type`, `match_score`. Add other columns needed downstream (`ingredient_name`, etc.) consistently.

---

## P1 Missing Features — Required for Mobile App

### 5. Add uses / side_effects / image_url to search results

**Problem**: `SearchResult` schema only has `medicine`, `generic_name`, `score`, `match_type`. The dataset has `uses`, `side_effects`, `image_url`.

**Fix**:
- Add optional fields to `SearchResult` in `schemas.py`
- Populate them from the medicine DataFrame in `retrieve_response()`

### 6. Add `/identify` endpoint for OCR text

**Problem**: Mobile app needs an endpoint that accepts raw OCR output (multiple text blocks from packaging) and returns the best matching medicine.

**Proposed multi-stage approach**:
1. **Largest text heuristic** — rank OCR blocks by size, prioritize longest/uppercase as brand candidate
2. **Keyword + pattern matching** — regex for suffixes (Tablet, Capsule, Syrup, etc.) + known brand prefixes
3. **Full-text fuzzy fallback** — send all OCR text to existing hybrid search

**Endpoint**: `POST /identify` with `{"ocr_blocks": [{"text": "...", "confidence": 0.95, "bounding_box": {...}}, ...]}` returns same `SearchResponse` format.

### 7. Add CORS middleware

**Problem**: No `CORSMiddleware` — mobile app and any web client will be blocked.

**Fix**: Add FastAPI `CORSMiddleware` in `api.py` allowing all origins during development (lock down for production).

### 8. Add health check endpoint

**Problem**: No `/health` or `/ping` for deployment monitoring.

**Fix**: Add `GET /health` returning `{"status": "ok", "records": 226000, "artifacts_loaded": true}`.

---

## P2 Code Quality & Infrastructure

### 9. Add `requirements.txt`

Pin all dependencies with compatible versions:
```
fastapi>=0.104.0
uvicorn>=0.24.0
pydantic>=2.5.0
pandas>=2.1.0
rapidfuzz>=3.0.0
```

### 10. Add tests

Set up `pytest` with:
- Test each search strategy (exact, fuzzy, ingredient, synonym) with known queries
- Test OCR correction edge cases
- Test `/identify` endpoint with mock OCR input
- Test error handling (empty query, missing data, file-not-found)

### 11. Cache safety for mutable objects

`@lru_cache` returns mutable dicts/DataFrames. Either:
- Document they must not be mutated, or
- Return a deep copy, or
- Return a frozen/immutable wrapper

### 12. Unify config file schema

Two config files exist with different schemas. Pick one format and delete the other.

---

## Architecture Summary

```
┌─────────────────────┐       POST /identify (OCR blocks)      ┌──────────────────────┐
│   Flutter App        │  ──────────────────────────────────►   │   FastAPI Backend     │
│  (iOS + Android)     │  ◄──────────────────────────────────   │  (Python / Uvicorn)   │
│                      │       POST /search (text query)       │                      │
│  • Google ML Kit OCR │                                        │  • Hybrid search      │
│  • Camera viewfinder │                                        │  • 226k records       │
│  • Dark apothecary   │                                        │  • Synonyms/abbrev    │
│    UI (DESIGN.md)    │                                        │  • OCR text parser    │
└─────────────────────┘                                        └──────────────────────┘
```

---

## Implementation Order

```
Phase 0: P0 Bug fixes ─────────────────── 1 → 2 → 3-4
Phase 1: P1 Features ──────────────────── 5 → 6 → 7 → 8
Phase 2: P2 Quality ───────────────────── 9 → 10 → 11 → 12
```

---

## References

- Full design spec: `.md reports/DESIGN.md`
- Phase 2 NLP report: `.md reports/PHASE_2_REPORT.md`
- Project status: `.md reports/medscan_status.md`
- Backend source: `backend/`
- Dataset: `data/final/medicine_ready_v2.csv` (724 MB, gitignored)
- Ingredient data: `data/final/ingredient_master_table.csv`
- Config (to fix): `retrieval_artifacts/retrieval_config.json`
