"""FastAPI integration for MedScan retrieval."""

from __future__ import annotations

import logging
import time

from fastapi import FastAPI, HTTPException

from backend.artifact_loader import (
    load_abbreviation_dict,
    load_config,
    load_ingredient_dataset,
    load_medicine_dataset,
    load_synonym_dict,
)
from backend.retrieval_engine import retrieve_response
from backend.schemas import SearchRequest, SearchResponse


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="MedScan Retrieval API", version="1.0.0")


@app.on_event("startup")
def startup() -> None:
    load_config()
    load_abbreviation_dict()
    load_synonym_dict()
    load_medicine_dataset()
    load_ingredient_dataset()
    logger.info("MedScan retrieval artifacts loaded")


@app.post("/search", response_model=SearchResponse)
def search(request: SearchRequest) -> SearchResponse:
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=422, detail="query must not be empty")

    started = time.perf_counter()
    try:
        response = retrieve_response(query, top_n=request.top_n)
    except Exception as exc:
        logger.exception("Search failed for query=%r", query)
        raise HTTPException(status_code=500, detail="search failed") from exc

    latency_ms = (time.perf_counter() - started) * 1000
    logger.info("search query=%r top_n=%s latency_ms=%.2f", query, request.top_n, latency_ms)
    return SearchResponse(**response)
