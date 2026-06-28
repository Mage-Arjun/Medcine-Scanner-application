# Tomorrow's Plan — OCR Quality Fix

## Problem
1. **Wrong medicine detected**: Tesseract misreads "PARACETAMOL" as "ACERTAMOL"
2. **Too much noise**: Scanning the back of a medicine strip picks up batch numbers, dates, MRP, manufacturer info — all muddies the match

## Root Cause
Flutter combines ALL 50+ OCR words into one string → sends as a single block → backend tries to match the whole mess against the medicine database.

---

## Fix: 5 Changes, 3 Files

### Change 1: Expand OCR correction rules
**File:** `backend/query_processor.py` (line 11-16)

Replace the current OCR_RULES with broader rules:
```python
OCR_RULES = [
    (r"(?<![a-z])0(?![0-9])", "o"),
    (r"(?<![a-z])1(?![0-9])", "l"),
    (r"(?<![a-z])5(?![0-9])", "s"),
    (r"(?<![a-z])8(?![0-9])", "b"),
    (r"rn", "m"),
    (r"cer", "par"),
]
```

### Change 2: Backend noise filter
**File:** `backend/identifier.py`

Add `_filter_noise(blocks)` — remove blocks matching:
- Regex: `BATCH`, `MFG`, `EXP`, `MRP`, `RS`, currency symbols
- Pure numbers/dates
- Very short text (< 3 chars)
- Manufacturing words: `LICENCE`, `FORMULATION`, `STORAGE`, `DOSAGE`, `WARNINGS`, `SIDE EFFECTS`

### Change 3: Backend multi-candidate matching
**File:** `backend/identifier.py`

Rewrite `identify()`:
- Filter noise blocks first
- Sort remaining by confidence (highest first)
- Try **top 3 blocks** as separate candidate queries
- Merge results: deduplicate by medicine name, keep highest score
- Fall back to combined text if individual blocks produce nothing

### Change 4: Backend OCR confidence weighting
**File:** `backend/identifier.py`

Pass OCR block confidence as a score multiplier on `final_score`.

### Change 5: Flutter sends individual OCR blocks
**File:** `medcam_app/lib/screens/scanner/scanner_screen.dart`

**a)** In `_captureImage()` (~line 91):
- Sort blocks by confidence, take top 5
- Filter out blocks with len < 3
- Auto-fill text field with highest-confidence block
- Store blocks in a new `_ocrBlocks` field on the state

**b)** In `_submitText()` (~line 132):
- Send stored `_ocrBlocks` (from OCR) + user's text as additional block
- Instead of: `final blocks = [OcrBlock(text: text, confidence: 1.0)];`
- Use: merge OCR blocks with user text

---

## Execution Order

| Step | File | Change |
|---|---|---|
| 1 | `backend/query_processor.py` | Expand OCR correction rules |
| 2 | `backend/identifier.py` | Add noise filter + multi-candidate matching + confidence weighting |
| 3 | `scanner_screen.dart` | Send individual blocks, auto-fill with best |
| 4 | Restart backend + hot restart app | Test |

## How to Test
1. Restart backend: `python -m uvicorn backend.api:app --reload --host 0.0.0.0 --port 8000`
2. Hot restart Flutter app
3. Scan the **FRONT** of a medicine strip (e.g. Dolo 650, Paracetamol 500)
4. Check: correct medicine detected, no noise in results
5. Scan the **BACK** of a medicine strip
6. Check: still detects correctly, noise filtered out
