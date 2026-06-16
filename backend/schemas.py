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


class SearchResponse(BaseModel):
    query: str
    normalized_query: str
    results: List[SearchResult]
