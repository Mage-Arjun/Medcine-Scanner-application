"""FastAPI integration for MedScan retrieval."""

from __future__ import annotations

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from typing import AsyncIterator

from backend.artifact_loader import (
    load_abbreviation_dict,
    load_config,
    load_ingredient_dataset,
    load_medicine_dataset,
    load_synonym_dict,
)
from backend.identifier import identify
from backend.retrieval_engine import retrieve_response
from backend.schemas import IdentifyRequest, OcrBlock, OcrRequest, OcrResponse, SearchRequest, SearchResponse


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    from backend.artifact_loader import (
        ABBREVIATION_DICT_PATH, CONFIG_PATH,
        INGREDIENT_DATASET_PATH, MEDICINE_DATASET_PATH,
        SYNONYM_DICT_PATH,
    )
    missing = []
    for label, path in [
        ("config", CONFIG_PATH),
        ("abbreviation_dict", ABBREVIATION_DICT_PATH),
        ("synonym_dict", SYNONYM_DICT_PATH),
        ("medicine_dataset", MEDICINE_DATASET_PATH),
        ("ingredient_dataset", INGREDIENT_DATASET_PATH),
    ]:
        if not path.exists():
            missing.append(f"{label}: {path}")
    if missing:
        for entry in missing:
            logger.error("Missing artifact: %s", entry)
        raise RuntimeError(f"Missing required artifacts: {', '.join(missing)}")

    load_config()
    load_abbreviation_dict()
    load_synonym_dict()
    load_medicine_dataset()
    load_ingredient_dataset()
    logger.info("MedScan retrieval artifacts loaded")
    yield


app = FastAPI(title="MedScan Retrieval API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
def global_exception_handler(request: Request, exc: Exception) -> object:
    if isinstance(exc, HTTPException):
        raise exc
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    from fastapi.responses import JSONResponse
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "records": len(load_medicine_dataset()),
        "artifacts_loaded": True,
    }


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


@app.post("/identify", response_model=SearchResponse)
def search_by_ocr(request: IdentifyRequest) -> SearchResponse:
    blocks = [b.model_dump() for b in request.ocr_blocks]
    if not blocks:
        raise HTTPException(status_code=422, detail="ocr_blocks must not be empty")

    started = time.perf_counter()
    try:
        response = identify(blocks, top_n=request.top_n)
    except Exception as exc:
        logger.exception("Identification failed")
        raise HTTPException(status_code=500, detail="identification failed") from exc

    latency_ms = (time.perf_counter() - started) * 1000
    logger.info("identify ocr_blocks=%s top_n=%s latency_ms=%.2f", len(blocks), request.top_n, latency_ms)
    return SearchResponse(**response)


@app.post("/ocr", response_model=OcrResponse)
def ocr_extract(request: OcrRequest) -> OcrResponse:
    from backend.ocr import ocr_from_image

    started = time.perf_counter()
    try:
        raw_blocks = ocr_from_image(request.image)
    except Exception as exc:
        logger.exception("OCR failed: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    latency_ms = (time.perf_counter() - started) * 1000
    logger.info("ocr blocks=%s latency_ms=%.2f", len(raw_blocks), latency_ms)

    blocks = [
        OcrBlock(text=b["text"], confidence=b["confidence"], bounding_box=b.get("bounding_box"))
        for b in raw_blocks
    ]
    return OcrResponse(blocks=blocks)
