# MedScan Project Status Document

## 1. Project Overview
**MedScan** is a personal medicine intelligence tool designed with a unique "Dark Apothecary" aesthetic. It moves away from sterile clinical designs toward a vintage scientific notebook feel, combining modern data scraping with historical visual cues.

---

## 2. Folder Structure Analysis

```text
Medi Cam/
├── DESIGN.md              # Detailed UI/UX Specification & Design System
├── normalization.py       # [Empty] Placeholder for data cleaning logic
├── data/
│   ├── raw/               # Ingested CSVs (marketers, initial URLs)
│   └── final/             # Large-scale datasets (up to 724MB)
├── pipeline/              # Data Acquisition & Processing Scripts
│   ├── medinfo10x.py      # High-concurrency async scraper (httpx + BeautifulSoup)
│   ├── test_scraper.py    # Scraping validation & testing
│   ├── marketers.py       # Marketer data processing
│   ├── medicine.py        # Medicine data handling
│   ├── validation.py      # Data integrity checks
│   └── compaare.py        # URL/Data comparison logic
├── notebook/              # Research & Exploration (Jupyter)
└── random test/           # Experimental snippets
```

---

## 3. Current Development Status

### 🎨 Design & UX (Completed/Defined)
- **Visual Identity**: Established in `DESIGN.md`. Uses an "Amber Glow" palette on dark backgrounds.
- **Typography**: Mixed system using *Cormorant Garamond* (Elegant/Editorial) and *IBM Plex Mono* (Scientific/Lab).
- **Core Feature**: Circular "Microscope" scanner viewfinder.
- **Implementation Status**: High-fidelity specifications are ready; UI components are not yet initialized in this directory.

### 🛠️ Data Pipeline (Mature)
- **Scraping Engine**: `medinfo10x.py` is a production-grade async scraper with:
    - 50-concurrency limit (Semaphore protected).
    - Auto-resume functionality based on existing CSV rows.
    - Robust retry logic (3 attempts per URL).
    - Batch-writer to prevent memory bloat (500 rows per batch).
- **Dataset Size**: The project has successfully scraped and processed significant data:
    - `medicine_ready_v2.csv`: ~724 MB.
    - `medicine_final_clean.csv`: ~321 MB.

### 🧪 Data Cleaning (In Progress)
- `normalization.py` is currently a placeholder.
- Basic cleaning logic exists within the scraper (`clean_text` function in `medinfo10x.py`) to strip boilerplate keywords like "USES OF" and "SIDE EFFECTS OF".

---

## 4. Architectural Highlights
- **Field Researcher Aesthetic**: The UI is designed to feel like a microscope eyepiece with a "hairline reticle" scan line.
- **Monospace Data Fields**: All data fields use mono fonts to emphasize "honesty and precision" in lab readouts.
- **Identity Separation**: The system is designed to treat medicines as research entities rather than consumer products.

---

## 5. Recommended Next Steps
1.  **Populate `normalization.py`**: Migrate cleaning logic from pipeline scripts to this central module to handle the 700MB+ dataset consistently.
2.  **Initialize Frontend**: Begin building the UI based on `DESIGN.md`. (The project currently lacks a web/mobile framework setup in this root).
3.  **Data Indexing**: With datasets >700MB, moving to a database (SQLite/PostgreSQL) or using a search engine (Meilisearch/Elasticsearch) is recommended for the dashboard search feature.
