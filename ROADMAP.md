# MediCam Roadmap

## Legend
- ✅ **v1** — Shipped in v1
- 🔜 **Next** — Planned for next release
- 📅 **Future** — On the horizon

---

## v1 (Current) — Text-Based Medicine Identification

| Feature | Status |
|---------|--------|
| OCR text extraction (Tesseract) | ✅ |
| Medicine database search (226K records) | ✅ |
| Fuzzy / exact / ingredient matching | ✅ |
| History tracking | ✅ |
| OCR noise filter (batch, MRP, dates) | ✅ |
| Multi-block matching + confidence weighting | ✅ |
| OpenCV pre-processing (grayscale + adaptive threshold) | ✅ |
| Auto-fill best OCR block into text field | ✅ |

---

## Phase 1 — 🔜 Next

### Barcode / QR Scanning
- **Why:** Instant, 100% accurate identification — no OCR needed
- **What:**
  - Add `mobile_scanner` Flutter package
  - Add barcode column to medicine CSV
  - New `POST /identify-barcode` endpoint or reuse `/identify` with barcode string
- **Effort:** 2–4 hours

### Smart Composition Parser
- **Why:** "Paracetamol 500mg + Caffeine 50mg" should be parsed into structured ingredients, unlocking ingredient-level features
- **What:**
  - `POST /parse-composition` endpoint
  - Regex + lookup-based parser
  - Returns structured `[{ ingredient, strength, unit }]`
- **Effort:** 4–8 hours

### Multilingual OCR
- **Why:** Indian medicines use Hindi, Tamil, Bengali, etc.
- **What:**
  - Tesseract supports 100+ languages
  - Add language auto-detect or manual selector in Flutter
  - Pass `lang=` parameter to `/ocr` endpoint
- **Effort:** 4–6 hours

---

## Phase 2 — 📅 Future

### Drug Interaction Checker
- **Why:** High safety value — warn users when two medicines interact
- **What:**
  - Source: OpenFDA or DrugBank interaction datasets
  - `POST /check-interaction` endpoint
  - Cross-reference scanned medicines from user's history
- **Effort:** 8–16 hours

### Allergy / Safety Filter
- **Why:** Personalize results based on user's known allergies
- **What:**
  - Simple user profile with allergen list (paracetamol, penicillin, etc.)
  - Flag matching ingredients in scan results
- **Effort:** 4–8 hours

### Expiry Date Auto-Detect
- **Why:** Users want to know when their medicines expire
- **What:**
  - Extract expiry dates from packaging noise (currently filtered out)
  - Store in a "medicine cabinet" with expiry timeline
- **Effort:** 4–8 hours

### Dosage Reminders
- **Why:** "1 tablet twice daily after meals" → push notification
- **What:**
  - Parse dosage instructions from packaging
  - Flutter local notifications plugin
  - User confirms or edits parsed schedule
- **Effort:** 1–2 weeks

---

## Phase 3 — 📅 Future (Higher Effort)

### Pill Image Recognition (Visual ID)
- **Why:** Identify a loose pill by its shape, color, and imprint — no packaging needed
- **What:**
  - Requires labeled dataset (NIH Pill Image Recognition / RxImage / custom)
  - Lightweight CNN (MobileNet) on-device or server-side
  - Fall back to imprint OCR if classification confidence is low
- **Effort:** Weeks (dataset-dependent)

### Medicine Cabinet
- **Why:** Dashboard showing all scanned medicines, expiry status, reorder alerts
- **What:**
  - Persistent local storage for scanned items
  - Group by "Expiring Soon", "In Use", "Past"
  - Low-stock / reorder notifications
- **Effort:** 1–2 weeks

### Voice Search
- **Why:** Say the name instead of typing
- **What:**
  - `speech_to_text` Flutter package
  - Feed transcribed text into existing search pipeline
- **Effort:** 4–8 hours

### Offline Mode
- **Why:** Use without internet (rural areas, travel)
- **What:**
  - Compressed medicine DB (226K rows → ~50MB SQLite)
  - On-device retrieval engine
  - Sync history when online
- **Effort:** 2–3 weeks

### Nearby Pharmacy Locator
- **Why:** Find where the medicine is in stock nearby
- **What:**
  - Integrate with Google Places / OpenStreetMap API
  - Search by medicine name → show nearby pharmacies with stock
- **Effort:** 1–2 weeks

---

## Phase 4 — 📅 Future (Ecosystem)

### User Accounts & Cloud Sync
- **Why:** Sync history, cabinet, allergies across devices
- **What:**
  - Firebase Auth or custom auth
  - Cloud Firestore for user data
  - Cross-device history and cabinet

### Doctor / Pharmacy Portal
- **Why:** Prescription scanning, doctor shares medicine list with patient
- **What:**
  - QR-coded prescriptions
  - Shared medicine lists
  - Telemedicine integration

### Medicine Stock & Pricing
- **Why:** Compare prices across pharmacies
- **What:**
  - Aggregate pricing data
  - Show lowest price / substitute options
