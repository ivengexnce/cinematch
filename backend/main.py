import json
import os
import uuid
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(
    title="CineMatch REST API",
    description="Intelligent Movie Recommendation System & Catalog API (Practical 12)",
    version="1.0.0"
)

# Enable CORS for Flutter Web, Mobile, and Desktop clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "full_movies.json")

# In-memory movie catalog
catalog: List[dict] = []
initial_catalog: List[dict] = []

def load_catalog():
    global catalog, initial_catalog
    if os.path.exists(DATA_PATH):
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            catalog = json.load(f)
            initial_catalog = list(catalog)
        print(f"Loaded {len(catalog)} movies into CineMatch catalog.")
    else:
        print("Warning: full_movies.json not found, using empty catalog.")
        catalog = []
        initial_catalog = []

load_catalog()

# --- Pydantic Schemas ---
class MovieBase(BaseModel):
    title: str = Field(..., min_length=1)
    genre: str = Field(..., min_length=1)
    mood: Optional[str] = "Curious"
    director: Optional[str] = "Unknown"
    actors: Optional[str] = "Unknown"
    year: int = Field(default=2024, ge=1880, le=2100)
    runtime: int = Field(default=120, ge=1)
    rating: float = Field(default=7.5, ge=0.0, le=10.0)
    votes: Optional[str] = "0"
    metascore: Optional[int] = 70
    synopsis: str = Field(..., min_length=3)
    poster_url: str = Field(default="https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80")

class MovieCreate(MovieBase):
    pass

class MovieUpdate(BaseModel):
    rating: Optional[float] = Field(None, ge=0.0, le=10.0)
    synopsis: Optional[str] = Field(None, min_length=3)
    title: Optional[str] = None
    genre: Optional[str] = None
    mood: Optional[str] = None
    poster_url: Optional[str] = None

class MovieResponse(MovieBase):
    id: str
    rank: Optional[int] = None
    recommended_score: Optional[float] = None

class RecommendationResponse(BaseModel):
    query_mood: Optional[str]
    query_genre: Optional[str]
    count: int
    recommendations: List[dict]

from fastapi.responses import RedirectResponse

# --- Endpoints ---

@app.get("/", summary="Root Endpoint - Redirects to API Documentation")
def root_index():
    return RedirectResponse(url="/docs")

@app.get("/api/health", summary="Health Check")
def health_check():
    return {
        "status": "healthy",
        "service": "CineMatch API",
        "version": "1.0.0",
        "total_movies": len(catalog)
    }

@app.get("/api/movies", summary="Retrieve Movies Catalog")
def get_movies(
    genre: Optional[str] = None,
    search: Optional[str] = None,
    min_rating: Optional[float] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500)
):
    results = catalog

    if search:
        s = search.lower().strip()
        results = [
            m for m in results 
            if s in m.get("title", "").lower() 
            or s in m.get("director", "").lower() 
            or s in m.get("actors", "").lower()
            or s in m.get("genre", "").lower()
        ]

    if genre and genre.lower() != "all":
        g = genre.lower().strip()
        results = [m for m in results if g in m.get("genre", "").lower()]

    if min_rating is not None:
        results = [m for m in results if float(m.get("rating", 0.0)) >= min_rating]

    total = len(results)
    sliced = results[skip : skip + limit]

    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "movies": sliced
    }

@app.get("/api/movies/{movie_id}", summary="Get Movie by ID")
def get_movie_by_id(movie_id: str):
    for m in catalog:
        if m.get("id") == movie_id:
            return m
    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.get("/api/recommendations", summary="AI Content-Based Recommendation Engine")
def get_recommendations(
    mood: Optional[str] = Query(None, description="Current mood: Adrenaline, Thrilled, Mind-bent, Chilled, Romantic, Inspired"),
    genre: Optional[str] = Query(None, description="Preferred genre"),
    limit: int = Query(6, ge=1, le=50)
):
    scored_movies = []
    target_mood = mood.lower().strip() if mood and mood.lower() != "all" else None
    target_genre = genre.lower().strip() if genre and genre.lower() != "all" else None

    for m in catalog:
        # Base score
        base_score = float(m.get("recommended_score", 80.0))
        delta_mood = 0.0
        delta_genre = 0.0

        movie_mood = str(m.get("mood", "")).lower()
        movie_genre = str(m.get("genre", "")).lower()
        rating = float(m.get("rating", 7.0))

        if target_mood and (target_mood in movie_mood or movie_mood in target_mood):
            delta_mood = 15.0

        if target_genre and (target_genre in movie_genre):
            delta_genre = 10.0

        # Formula: S = S_base + delta_mood + delta_genre + (Rating * 2.0)
        raw_score = base_score + delta_mood + delta_genre + (rating * 2.0)
        # Normalize into realistic match percentage (70% - 99%)
        norm_score = round(min(99.0, max(72.0, (raw_score / 142.0) * 100.0)), 1)

        # Build enriched copy with real-time score
        item = dict(m)
        item["calculated_score"] = norm_score
        item["score_breakdown"] = {
            "base_score": base_score,
            "mood_bonus": delta_mood,
            "genre_bonus": delta_genre,
            "rating_bonus": round(rating * 2.0, 1),
            "raw_total": round(raw_score, 1)
        }
        scored_movies.append(item)

    # Sort descending by calculated_score, then rating
    scored_movies.sort(key=lambda x: (x["calculated_score"], float(x.get("rating", 0.0))), reverse=True)
    top_recommendations = scored_movies[:limit]

    return {
        "query_mood": mood,
        "query_genre": genre,
        "count": len(top_recommendations),
        "recommendations": top_recommendations
    }

@app.post("/api/movies", status_code=status.HTTP_201_CREATED, summary="Add New Movie")
def create_movie(payload: MovieCreate):
    new_id = f"custom_{uuid.uuid4().hex[:8]}"
    base_score = round(80.0 + (payload.rating * 2.0), 1)

    new_movie = {
        "id": new_id,
        "rank": len(catalog) + 1,
        "title": payload.title,
        "genre": payload.genre,
        "mood": payload.mood or "Curious",
        "director": payload.director or "Unknown",
        "actors": payload.actors or "Unknown",
        "year": payload.year,
        "runtime": payload.runtime,
        "rating": payload.rating,
        "votes": payload.votes or "1",
        "metascore": payload.metascore or 75,
        "synopsis": payload.synopsis,
        "poster_url": payload.poster_url,
        "recommended_score": base_score
    }

    # Prepend to catalog so new additions appear prominently
    catalog.insert(0, new_movie)
    return new_movie

@app.put("/api/movies/{movie_id}", summary="Update Movie Details")
def update_movie(movie_id: str, payload: MovieUpdate):
    for i, m in enumerate(catalog):
        if m.get("id") == movie_id:
            updated = dict(m)
            if payload.rating is not None:
                updated["rating"] = payload.rating
                updated["recommended_score"] = round(80.0 + (payload.rating * 2.0), 1)
            if payload.synopsis is not None:
                updated["synopsis"] = payload.synopsis
            if payload.title is not None:
                updated["title"] = payload.title
            if payload.genre is not None:
                updated["genre"] = payload.genre
            if payload.mood is not None:
                updated["mood"] = payload.mood
            if payload.poster_url is not None:
                updated["poster_url"] = payload.poster_url

            catalog[i] = updated
            return updated

    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.delete("/api/movies/{movie_id}", summary="Delete Movie")
def delete_movie(movie_id: str):
    for i, m in enumerate(catalog):
        if m.get("id") == movie_id:
            removed = catalog.pop(i)
            return {"message": "Movie deleted successfully", "deleted_movie": removed}
    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.post("/api/movies/reset", summary="Reset Catalog to Default")
def reset_catalog():
    global catalog
    catalog = list(initial_catalog)
    return {"message": "Catalog reset to default dataset", "total_movies": len(catalog)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
