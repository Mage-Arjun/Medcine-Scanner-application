"""Tests for the FastAPI endpoints."""

from __future__ import annotations

from unittest.mock import patch

import pandas as pd
import pytest
from fastapi.testclient import TestClient


MOCK_MED_DF = pd.DataFrame({
    "name": ["Crocin Advance", "Dolo 650"],
    "generic_name": ["Paracetamol", "Paracetamol"],
    "composition": ["Paracetamol (500mg)", "Paracetamol (650mg)"],
    "ingredient_name": ["Paracetamol (500mg)", "Paracetamol (650mg)"],
    "corpus_standard": ["crocin advance", "dolo 650"],
    "corpus_normalized": ["crocin advance", "dolo 650"],
    "uses": ["Pain relief", "Fever"],
    "side_effects": ["Nausea", "Dizziness"],
    "image_url": [
        "https://example.com/crocin.png",
        "https://example.com/dolo.png",
    ],
})

MOCK_ING_DF = pd.DataFrame({
    "medicine_id": [1, 2],
    "name": ["Crocin Advance", "Dolo 650"],
    "ingredient_name": ["Paracetamol", "Paracetamol"],
    "strength": ["500mg", "650mg"],
    "unit": ["mg", "mg"],
    "flag": ["", ""],
})

MOCK_ABBREV = {"pcm": "paracetamol"}
MOCK_SYNONYM = {"tylenol": "paracetamol"}
MOCK_CONFIG = {"weights": {"exact": 0.4, "fuzzy": 0.3, "ingredient": 0.2, "synonym": 0.1}, "ocr_threshold": 0.3}


@pytest.fixture(autouse=True)
def patch_all_loaders():
    patchers = [
        patch("backend.api.load_config", return_value=MOCK_CONFIG),
        patch("backend.api.load_abbreviation_dict", return_value=MOCK_ABBREV),
        patch("backend.api.load_synonym_dict", return_value=MOCK_SYNONYM),
        patch("backend.api.load_medicine_dataset", return_value=MOCK_MED_DF),
        patch("backend.api.load_ingredient_dataset", return_value=MOCK_ING_DF),
        patch("backend.retrieval_engine.load_config", return_value=MOCK_CONFIG),
        patch("backend.retrieval_engine.load_abbreviation_dict", return_value=MOCK_ABBREV),
        patch("backend.retrieval_engine.load_synonym_dict", return_value=MOCK_SYNONYM),
        patch("backend.retrieval_engine.load_medicine_dataset", return_value=MOCK_MED_DF),
        patch("backend.retrieval_engine.load_ingredient_dataset", return_value=MOCK_ING_DF),
        patch("backend.identifier.retrieve_response", return_value={
            "query": "crocin",
            "normalized_query": "crocin",
            "results": [{"medicine": "Crocin Advance", "generic_name": "Paracetamol", "score": 1.0, "match_type": "Exact Brand", "uses": "Pain relief", "side_effects": "Nausea", "image_url": "https://example.com/crocin.png"}],
        }),
    ]
    for p in patchers:
        p.start()
    yield
    for p in patchers:
        p.stop()


from backend.api import app  # noqa: E402

client = TestClient(app)


class TestHealth:
    def test_health_returns_ok(self):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert data["artifacts_loaded"] is True
        assert data["records"] == 2


class TestSearch:
    def test_search_exact_brand(self):
        resp = client.post("/search", json={"query": "crocin advance"})
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["results"]) > 0
        assert data["results"][0]["medicine"] == "Crocin Advance"
        assert data["results"][0]["match_type"] == "Exact Brand"

    def test_search_returns_new_fields(self):
        resp = client.post("/search", json={"query": "crocin advance"})
        assert resp.status_code == 200
        result = resp.json()["results"][0]
        assert "uses" in result
        assert "side_effects" in result
        assert "image_url" in result

    def test_search_empty_query_returns_422(self):
        resp = client.post("/search", json={"query": ""})
        assert resp.status_code == 422

    def test_search_no_results(self):
        resp = client.post("/search", json={"query": "nonexistent_drug_xyz"})
        assert resp.status_code == 200
        assert resp.json()["results"] == []

    def test_search_top_n(self):
        resp = client.post("/search", json={"query": "paracetamol", "top_n": 1})
        assert resp.status_code == 200
        assert len(resp.json()["results"]) <= 1

    def test_search_negative_top_n_returns_422(self):
        resp = client.post("/search", json={"query": "paracetamol", "top_n": -1})
        assert resp.status_code == 422


class TestIdentify:
    def test_identify_with_ocr_blocks(self):
        resp = client.post("/identify", json={
            "ocr_blocks": [
                {"text": "Crocin", "confidence": 0.95},
                {"text": "Advance", "confidence": 0.90},
            ],
            "top_n": 5,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "results" in data
        assert "normalized_query" in data

    def test_identify_empty_blocks_returns_422(self):
        resp = client.post("/identify", json={"ocr_blocks": []})
        assert resp.status_code == 422

    def test_identify_missing_text_field_returns_422(self):
        resp = client.post("/identify", json={"ocr_blocks": [{"confidence": 0.95}]})
        assert resp.status_code == 422

    def test_identify_returns_search_response_shape(self):
        resp = client.post("/identify", json={
            "ocr_blocks": [{"text": "Dolo 650", "confidence": 0.98}],
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "query" in data
        assert "normalized_query" in data
        assert "results" in data
