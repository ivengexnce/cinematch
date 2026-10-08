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
ACTIVE_DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "active_catalog.json")

# In-memory movie catalog with disk persistence
catalog: List[dict] = []
initial_catalog: List[dict] = []

def save_catalog():
    """Atomically persists active catalog state to disk to survive server restarts."""
    try:
        os.makedirs(os.path.dirname(ACTIVE_DATA_PATH), exist_ok=True)
        temp_path = ACTIVE_DATA_PATH + ".tmp"
        with open(temp_path, "w", encoding="utf-8") as f:
            json.dump(catalog, f, indent=2, ensure_ascii=False)
        if os.path.exists(ACTIVE_DATA_PATH):
            os.replace(temp_path, ACTIVE_DATA_PATH)
        else:
            os.rename(temp_path, ACTIVE_DATA_PATH)
    except Exception as e:
        print(f"Warning: Failed to persist catalog: {e}")

def load_catalog():
    global catalog, initial_catalog
    if os.path.exists(DATA_PATH):
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            initial_catalog = json.load(f)
    else:
        initial_catalog = []

    target = ACTIVE_DATA_PATH if os.path.exists(ACTIVE_DATA_PATH) else DATA_PATH
    if os.path.exists(target):
        with open(target, "r", encoding="utf-8") as f:
            catalog = json.load(f)
        print(f"Loaded {len(catalog)} movies into CineMatch catalog from {os.path.basename(target)}.")
    else:
        print("Warning: Catalog file not found, using empty catalog.")
        catalog = []

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

class RecommendPayload(BaseModel):
    user_id: str = Field(..., min_length=1)

class RatePayload(BaseModel):
    user_id: str = Field(..., min_length=1)
    rating: float = Field(..., ge=0.0, le=10.0)

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
    sort_by: Optional[str] = Query("rating", description="Sort by: rating, top_rating, recommendations, year, title"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500)
):
    results = list(catalog)

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

    # Dynamic sorting
    if sort_by == "top_rating":
        results.sort(
            key=lambda m: (
                float(m.get("rating", 7.0)) * 0.60 +
                float(m.get("user_rating_average", m.get("rating", 7.0))) * 0.25 +
                min(1.5, 0.9 + float(m.get("user_recommendations_count", 40)) / 300.0)
            ),
            reverse=True
        )
    elif sort_by == "recommendations":
        results.sort(key=lambda m: int(m.get("user_recommendations_count", 0)), reverse=True)
    elif sort_by == "year":
        results.sort(key=lambda m: int(m.get("year", 2020)), reverse=True)
    elif sort_by == "title":
        results.sort(key=lambda m: str(m.get("title", "")).lower())
    else: # default: rating
        results.sort(key=lambda m: float(m.get("rating", 0.0)), reverse=True)

    total = len(results)
    sliced = results[skip : skip + limit]

    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "movies": sliced
    }

@app.post("/api/movies/{movie_id}/recommend", summary="Toggle Community Recommendation for Movie")
def toggle_movie_recommendation(movie_id: str, payload: RecommendPayload):
    for m in catalog:
        if m.get("id") == movie_id:
            users_list = m.setdefault("recommended_by_users", [])
            user_id = payload.user_id.strip()
            
            if user_id in users_list:
                users_list.remove(user_id)
                m["user_recommendations_count"] = max(0, int(m.get("user_recommendations_count", 1)) - 1)
                is_recommended = False
            else:
                users_list.append(user_id)
                m["user_recommendations_count"] = int(m.get("user_recommendations_count", 0)) + 1
                is_recommended = True
            
            save_catalog()
            return {
                "message": "Recommendation updated",
                "movie_id": movie_id,
                "is_recommended": is_recommended,
                "user_recommendations_count": m["user_recommendations_count"],
                "movie": m
            }

    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.post("/api/movies/{movie_id}/rate", summary="Submit Community User Rating")
def submit_user_rating(movie_id: str, payload: RatePayload):
    for m in catalog:
        if m.get("id") == movie_id:
            current_avg = float(m.get("user_rating_average", m.get("rating", 7.0)))
            current_count = int(m.get("user_ratings_count", 0))
            
            new_count = current_count + 1
            new_avg = round(((current_avg * current_count) + payload.rating) / new_count, 1)
            
            m["user_rating_average"] = new_avg
            m["user_ratings_count"] = new_count
            
            save_catalog()
            return {
                "message": "Rating submitted successfully",
                "movie_id": movie_id,
                "user_rating_average": new_avg,
                "user_ratings_count": new_count,
                "movie": m
            }

    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

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

@app.get("/api/stats", summary="Catalog Statistics & Analytics")
def get_stats():
    """Returns analytics and distribution statistics across the entire movie catalog."""
    if not catalog:
        return {"total_movies": 0, "avg_rating": 0.0, "genres": {}, "moods": {}, "decades": {}}

    total = len(catalog)
    ratings = [float(m.get("rating", 0.0)) for m in catalog]
    avg_rating = round(sum(ratings) / total, 2) if total > 0 else 0.0

    genre_counts = {}
    mood_counts = {}
    decade_counts = {}

    for m in catalog:
        # Genre breakdown
        for g in str(m.get("genre", "")).split(","):
            cleaned = g.strip()
            if cleaned:
                genre_counts[cleaned] = genre_counts.get(cleaned, 0) + 1

        # Mood breakdown
        mood = m.get("mood", "Curious")
        mood_counts[mood] = mood_counts.get(mood, 0) + 1

        # Decade breakdown
        year = int(m.get("year", 2020))
        decade = f"{(year // 10) * 10}s"
        decade_counts[decade] = decade_counts.get(decade, 0) + 1

    # Top 3 rated movies
    sorted_by_rating = sorted(catalog, key=lambda x: float(x.get("rating", 0.0)), reverse=True)
    top_rated = [
        {"id": m.get("id"), "title": m.get("title"), "rating": m.get("rating"), "year": m.get("year")}
        for m in sorted_by_rating[:5]
    ]

    return {
        "total_movies": total,
        "avg_rating": avg_rating,
        "genres": dict(sorted(genre_counts.items(), key=lambda x: x[1], reverse=True)[:10]),
        "moods": mood_counts,
        "decades": dict(sorted(decade_counts.items())),
        "top_rated": top_rated
    }

@app.get("/api/genres", summary="List All Unique Genres")
def get_genres():
    """Returns all unique genre tags available in the dataset."""
    genres_set = set()
    for m in catalog:
        for g in str(m.get("genre", "")).split(","):
            cleaned = g.strip()
            if cleaned:
                genres_set.add(cleaned)
    return {"genres": sorted(list(genres_set))}

@app.get("/api/moods", summary="List All Available Moods")
def get_moods():
    """Returns all available mood classifications."""
    moods_set = {m.get("mood", "Curious") for m in catalog if m.get("mood")}
    return {"moods": sorted(list(moods_set))}

@app.get("/api/movies/{movie_id}/similar", summary="Multi-Attribute Similar Movie Recommendations")
def get_similar_movies(movie_id: str, limit: int = Query(6, ge=1, le=20)):
    """Computes hybrid similarity against the target movie based on genre overlap, director, mood, era, and rating."""
    target = None
    for m in catalog:
        if m.get("id") == movie_id:
            target = m
            break

    if not target:
        raise HTTPException(status_code=404, detail=f"Target movie '{movie_id}' not found")

    target_genres = {g.strip().lower() for g in str(target.get("genre", "")).split(",") if g.strip()}
    target_director = str(target.get("director", "")).lower()
    target_mood = str(target.get("mood", "")).lower()
    target_year = int(target.get("year", 2020))
    target_rating = float(target.get("rating", 7.0))

    scored = []
    for m in catalog:
        if m.get("id") == movie_id:
            continue

        item_genres = {g.strip().lower() for g in str(m.get("genre", "")).split(",") if g.strip()}
        
        # 1. Genre Jaccard Similarity (Weight: 45%)
        intersection = len(target_genres & item_genres)
        union = len(target_genres | item_genres) or 1
        jaccard = intersection / union

        # 2. Director match bonus (Weight: 20%)
        director_match = 1.0 if target_director and target_director == str(m.get("director", "")).lower() else 0.0

        # 3. Mood similarity (Weight: 15%)
        mood_match = 1.0 if target_mood and target_mood == str(m.get("mood", "")).lower() else 0.0

        # 4. Era proximity (Weight: 10%)
        item_year = int(m.get("year", 2020))
        year_diff = abs(target_year - item_year)
        era_similarity = max(0.0, 1.0 - (year_diff / 40.0))

        # 5. Rating proximity (Weight: 10%)
        item_rating = float(m.get("rating", 7.0))
        rating_diff = abs(target_rating - item_rating)
        rating_similarity = max(0.0, 1.0 - (rating_diff / 5.0))

        # Combined similarity index in percentage
        similarity_index = (
            (jaccard * 45.0) +
            (director_match * 20.0) +
            (mood_match * 15.0) +
            (era_similarity * 10.0) +
            (rating_similarity * 10.0)
        )

        item = dict(m)
        item["similarity_score"] = round(similarity_index, 1)
        scored.append(item)

    scored.sort(key=lambda x: (x["similarity_score"], float(x.get("rating", 0.0))), reverse=True)
    return {
        "target_id": movie_id,
        "target_title": target.get("title"),
        "count": min(limit, len(scored)),
        "similar_movies": scored[:limit]
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
    save_catalog()
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
            save_catalog()
            return updated

    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.delete("/api/movies/{movie_id}", summary="Delete Movie")
def delete_movie(movie_id: str):
    for i, m in enumerate(catalog):
        if m.get("id") == movie_id:
            removed = catalog.pop(i)
            save_catalog()
            return {"message": "Movie deleted successfully", "deleted_movie": removed}
    raise HTTPException(status_code=404, detail=f"Movie with id '{movie_id}' not found")

@app.post("/api/movies/reset", summary="Reset Catalog to Default")
def reset_catalog():
    global catalog
    catalog = list(initial_catalog)
    save_catalog()
    return {"message": "Catalog reset to default dataset", "total_movies": len(catalog)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)

