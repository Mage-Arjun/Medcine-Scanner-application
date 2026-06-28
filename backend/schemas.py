"""Pydantic schemas for the MedScan API."""

from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class SearchRequest(BaseModel):
    query: str = Field(..., min_length=1)
    top_n: int = Field(default=10, ge=1, le=100)


class SearchResult(BaseModel):
    medicine: str
    generic_name: Optional[str] = None
    score: float
    match_type: str
    uses: Optional[str] = None
    side_effects: Optional[str] = None
    image_url: Optional[str] = None


class SearchResponse(BaseModel):
    query: str
    normalized_query: str
    results: List[SearchResult]


class OcrBlock(BaseModel):
    text: str = Field(..., min_length=1)
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    bounding_box: Optional[dict] = None


class IdentifyRequest(BaseModel):
    ocr_blocks: List[OcrBlock] = Field(..., min_length=1)
    top_n: int = Field(default=5, ge=1, le=100)


class OcrRequest(BaseModel):
    image: str = Field(..., min_length=1)


class OcrResponse(BaseModel):
    blocks: List[OcrBlock]
