import csv
import json
import os

CURATED_TITLE_POSTERS = {
    "guardians of the galaxy": "https://m.media-amazon.com/images/M/MV5BMTAwMjU5OTgxNjZeQTJeQWpwZ15BbWU4MDUxNDYxODEx._V1_SX300.jpg",
    "prometheus": "https://m.media-amazon.com/images/M/MV5BMTY3NzIyNTA2NV5BMl5BanBnXkFtZTcwNzM2MjcwOA@@._V1_SX300.jpg",
    "split": "https://m.media-amazon.com/images/M/MV5BZTJiNGM2NjItNDRiOC00MTk0LTgwMjctY2NmOTcad2VlZjdhXkEyXkFqcGc@._V1_SX300.jpg",
    "sing": "https://m.media-amazon.com/images/M/MV5BMjAzMTI4NjMyN15BMl5BanBnXkFtZTgwNzYzNzY3OTE@._V1_SX300.jpg",
    "suicide squad": "https://m.media-amazon.com/images/M/MV5BMjM1OTMxNzUyN15BMl5BanBnXkFtZTgwNjM5OTAwOTE@._V1_SX300.jpg",
    "the great wall": "https://m.media-amazon.com/images/M/MV5BMTUzMTU3MDUyMV5BMl5BanBnXkFtZTgwNTU0MDA2OTE@._V1_SX300.jpg",
    "la la land": "https://m.media-amazon.com/images/M/MV5BMzUzNDM2NzM9MV5BMl5BanBnXkFtZTgwNTM3NTg4OTE@._V1_SX300.jpg",
    "passengers": "https://m.media-amazon.com/images/M/MV5BZjQ5MmUxMDYtN2U3OS00MDMwLTkwNjctOWEyNjA2MGRkYmFmXkEyXkFqcGc@._V1_SX300.jpg",
    "rogue one": "https://m.media-amazon.com/images/M/MV5BMjEwMzMxODIzOV5BMl5BanBnXkFtZTgwNzg3OTAzMDI@._V1_SX300.jpg",
    "rogue one: a star wars story": "https://m.media-amazon.com/images/M/MV5BMjEwMzMxODIzOV5BMl5BanBnXkFtZTgwNzg3OTAzMDI@._V1_SX300.jpg",
    "hidden figures": "https://m.media-amazon.com/images/M/MV5BMzg2Mzg4YmUtNDdkNy00NWY1LWE3NmEtODMwMGE3ODk0Nzg4XkEyXkFqcGc@._V1_SX300.jpg",
    "lion": "https://m.media-amazon.com/images/M/MV5BMjA3Njc0Nzg4MV5BMl5BanBnXkFtZTgwMTkyNzYzOTE@._V1_SX300.jpg",
    "arrival": "https://m.media-amazon.com/images/M/MV5BMTExMzU0ODcxNDheQTJeQWpwZ15BbWU4MDE1OTI4MzAy._V1_SX300.jpg",
    "hacksaw ridge": "https://m.media-amazon.com/images/M/MV5BMjQ1NjM3NzUxOF5BMl5BanBnXkFtZTgwODE3ODk0OTE@._V1_SX300.jpg",
    "interstellar": "https://m.media-amazon.com/images/M/MV5BYzdjMDAxZGItMjI2My00ODA1LTlkNzItOWFjMDU5ZDJlYWY3XkEyXkFqcGc@._V1_SX300.jpg",
    "dangal": "https://m.media-amazon.com/images/M/MV5BMTQ4MzQzMzM2Nl5BMl5BanBnXkFtZTgwMTQ1NzU3MDI@._V1_SX300.jpg",
    "bahubali: the beginning": "https://m.media-amazon.com/images/M/MV5BYWVlMjVhZWYtNWViNC00ODFkLTk1MmItYjU1MDY5ZDdhMTU3XkEyXkFqcGc@._V1_SX300.jpg",
    "3 idiots": "https://m.media-amazon.com/images/M/MV5BNTkyOGVjMGEtNmQzZi00NzFlLTlhOWQtODYyMDc2ZGJmYzFhXkEyXkFqcGc@._V1_SX300.jpg",
    "taare zameen par": "https://m.media-amazon.com/images/M/MV5BNTFhMGJlYmItZGU0My00MGUxLWE0NTMtMDYzNTU1NWIzOTNlXkEyXkFqcGc@._V1_SX300.jpg",
    "the intouchables": "https://m.media-amazon.com/images/M/MV5BMTYxNDA3MDQwNl5BMl5BanBnXkFtZTcwNTU4Mjc1Nw@@._V1_SX300.jpg",
    "warrior": "https://m.media-amazon.com/images/M/MV5BMTk4ODk5MTY3EV5BMl5BanBnXkFtZTcwMDQ0NzgwNg@@._V1_SX300.jpg",
    "toy story 3": "https://m.media-amazon.com/images/M/MV5BMTgxOTY4Mjc0MF5BMl5BanBnXkFtZTcwNTA4MDQyMw@@._V1_SX300.jpg",
    "up": "https://m.media-amazon.com/images/M/MV5BMTk3NDE2NzI4NF5BMl5BanBnXkFtZTgwNzE1MzEyMTE@._V1_SX300.jpg",
    "gran torino": "https://m.media-amazon.com/images/M/MV5BMTQyMTczMTAxMl5BMl5BanBnXkFtZTcwOTc2ODQyMg@@._V1_SX300.jpg",
    "the lives of others": "https://m.media-amazon.com/images/M/MV5BNmJhZDU4NTMtNzEwYS00NzE5LThhNGMtM2E5Nzk1YmU5NjdhXkEyXkFqcGc@._V1_SX300.jpg",
    "wall·e": "https://m.media-amazon.com/images/M/MV5BMjExMTg5OTU0NF5BMl5BanBnXkFtZTcwMjMxMzMzMw@@._V1_SX300.jpg",
    "inception": "https://m.media-amazon.com/images/M/MV5BMjAxMzY3NjcxNF5BMl5BanBnXkFtZTcwNTI5OTM0Mw@@._V1_SX300.jpg",
    "the dark knight": "https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZTcwODAyMTk2Mw@@._V1_SX300.jpg",
    "the dark knight rises": "https://m.media-amazon.com/images/M/MV5BMTk4ODQzNDY3Ml5BMl5BanBnXkFtZTcwODA0NTM4Nw@@._V1_SX300.jpg",
    "avatar": "https://m.media-amazon.com/images/M/MV5BMDEzMmQwZjctZWU2My00MWVOLWE0NzItM2JlNDM5Mjc4ZDZkXkEyXkFqcGc@._V1_SX300.jpg",
    "the martian": "https://m.media-amazon.com/images/M/MV5BMTc2MTQ3MDA1Nl5BMl5BanBnXkFtZTgwODA3OTI4NjE@._V1_SX300.jpg",
    "mad max: fury road": "https://m.media-amazon.com/images/M/MV5BN2EwM2I5OWMtMGQyMi00Zjg1LWJkNTctZTdjYTA4OGUwZjMyXkEyXkFqcGc@._V1_SX300.jpg",
    "deadpool": "https://m.media-amazon.com/images/M/MV5BYzE5MjY1ZDgtMTkyNC00MTMyLThhMjAtZGI5OTE1NzFlZGJjXkEyXkFqcGc@._V1_SX300.jpg",
    "the avengers": "https://m.media-amazon.com/images/M/MV5BNGE0YTVjNzUtNzJjOS00NGNlLTgxMzctZTY4YTE1Y2Y1ZEQzXkEyXkFqcGc@._V1_SX300.jpg",
    "whiplash": "https://m.media-amazon.com/images/M/MV5BOTA5NDZlZGUtMjAxOS00YTRkLTkwYmMtYWQ0NWEwZDc4YzRjXkEyXkFqcGc@._V1_SX300.jpg",
    "django unchained": "https://m.media-amazon.com/images/M/MV5BMjIyOTM5OTIzNV5BMl5BanBnXkFtZTcwNjAzMzkzNw@@._V1_SX300.jpg",
    "the wolf of wall street": "https://m.media-amazon.com/images/M/MV5BMjIxMjgxNTk0MF5BMl5BanBnXkFtZTgwNjIyOTg2MDE@._V1_SX300.jpg",
    "shutter island": "https://m.media-amazon.com/images/M/MV5BYzA5Yzg0OGEtNDU5Ni00ZTkzLWFhMjgtYmQ5Njc2MmE1ZDgzXkEyXkFqcGc@._V1_SX300.jpg",
    "inglourious basterds": "https://m.media-amazon.com/images/M/MV5BOTJiNDEzOWYtMTVjOC00ZjlmLWE0NGMtZmE1OWVmZDQ2MzYzXkEyXkFqcGc@._V1_SX300.jpg",
    "iron man": "https://m.media-amazon.com/images/M/MV5BMTczNTI2ODUwOF5BMl5BanBnXkFtZTcwMTU0NTIzMw@@._V1_SX300.jpg",
    "the prestige": "https://m.media-amazon.com/images/M/MV5BMjA4NDI0MTIxNF5BMl5BanBnXkFtZTYpNTdhOTA3._V1_SX300.jpg",
    "gladiator": "https://m.media-amazon.com/images/M/MV5BYWQ4YmNjYjEtOWE1Zi00Y2U4LWI4NTAtMTU0MjkxNWQ1Dg@@._V1_SX300.jpg",
    "forrest gump": "https://m.media-amazon.com/images/M/MV5BNDYwNzVjMTItZmU5YS00YjQ5LTljYjgtMjY2NDVmYWMyNWFmXkEyXkFqcGc@._V1_SX300.jpg",
    "doctor strange": "https://m.media-amazon.com/images/M/MV5BNjgwNzAzNjk1Nl5BMl5BanBnXkFtZTgwMzQ2NjI1OTE@._V1_SX300.jpg",
    "captain america: civil war": "https://m.media-amazon.com/images/M/MV5BMjQ0MTgyNjAxMV5BMl5BanBnXkFtZTgwNjUzMDkyODE@._V1_SX300.jpg",
    "zootopia": "https://m.media-amazon.com/images/M/MV5BYjQ5NjM0Y2YtNjZkNC00ZDhkLWJjMWItN2QyNzFkZTFjMWY1XkEyXkFqcGc@._V1_SX300.jpg",
    "logan": "https://m.media-amazon.com/images/M/MV5BMmIwMWU4YWItNGVlNS00ZTIwLWE3MmYtN2Q3Yzk2ZTg2YjIxXkEyXkFqcGc@._V1_SX300.jpg",
    "spider-man: homecoming": "https://m.media-amazon.com/images/M/MV5BNTk4ODQ1NTM5MV5BMl5BanBnXkFtZTgwOTU1NTkyMjI@._V1_SX300.jpg",
    "pulp fiction": "https://m.media-amazon.com/images/M/MV5BYTViYTE3NWMtNmRhOS00NzRiLWEzYTUtOTk2NjcwOWUwZDUwXkEyXkFqcGc@._V1_SX300.jpg",
    "the shawshank redemption": "https://m.media-amazon.com/images/M/MV5BMDAyY2FhYjctNDc5OS00MDNlLThiMGUtYTEzNTA5OTJhZDJlXkEyXkFqcGc@._V1_SX300.jpg",
    "fight club": "https://m.media-amazon.com/images/M/MV5BOTgyOGQ1NDItNGU3Ny00MjU3LTg2YTMtNmFhNGFlNTY4ZkNkXkEyXkFqcGc@._V1_SX300.jpg",
    "the matrix": "https://m.media-amazon.com/images/M/MV5BN2NmN2VhMTQtMDNiOS00NDlhLTliMjgtODE2ZTY0ODQyNDRhXkEyXkFqcGc@._V1_SX300.jpg",
    "titanic": "https://m.media-amazon.com/images/M/MV5BYzYyN2FiZmUtYWYzMy00MzViLWJkZTMtOGY1ZjgzNWMwN2YxXkEyXkFqcGc@._V1_SX300.jpg",
    "jurassic world": "https://m.media-amazon.com/images/M/MV5BNzQ3OTY4NjAtNzM5OS00N2ZhLWJlOWUtYzYwNDVkZDUyNzczXkEyXkFqcGc@._V1_SX300.jpg",
    "gone girl": "https://m.media-amazon.com/images/M/MV5BMTk0MDQ3OTAzOV5BMl5BanBnXkFtZTgwNzU1NzE3MjE@._V1_SX300.jpg",
    "the revenant": "https://m.media-amazon.com/images/M/MV5BY2FmODc3ZWEtMTMwNC00NmZjLWIwNzAtZGIzYTE1NTBkMTRjXkEyXkFqcGc@._V1_SX300.jpg",
    "room": "https://m.media-amazon.com/images/M/MV5BMjE4NzgzNzEwMl5BMl5BanBnXkFtZTgwMTMzMDE0NzE@._V1_SX300.jpg",
    "ex machina": "https://m.media-amazon.com/images/M/MV5BMTUxNzc0OTIxMV5BMl5BanBnXkFtZTgwNDI3NzU2NDE@._V1_SX300.jpg",
    "inside out": "https://m.media-amazon.com/images/M/MV5BOTgxMDQwMDk0OF5BMl5BanBnXkFtZTgwMTZVDzg3MDE@._V1_SX300.jpg",
    "birdman": "https://m.media-amazon.com/images/M/MV5BODAzNDI2MjEtNDA3NS00M2NkLTlhMDgtMmUyYzk4Mzk0ZTFlXkEyXkFqcGc@._V1_SX300.jpg",
    "the grand budapest hotel": "https://m.media-amazon.com/images/M/MV5BMzM5NjUxOTEyMl5BMl5BanBnXkFtZTgwNjEyMDM0MDE@._V1_SX300.jpg",
    "her": "https://m.media-amazon.com/images/M/MV5BMjA1Nzk0OTM2OF5BMl5BanBnXkFtZTgwNjU2NjEwMDE@._V1_SX300.jpg",
    "gravity": "https://m.media-amazon.com/images/M/MV5BNjE5MzYwMzYxMF5BMl5BanBnXkFtZTcwOTk4MTk0OQ@@._V1_SX300.jpg",
    "12 years a slave": "https://m.media-amazon.com/images/M/MV5BMjExMTEzODkyN15BMl5BanBnXkFtZTcwNTU4NTc4OQ@@._V1_SX300.jpg",
    "prisoners": "https://m.media-amazon.com/images/M/MV5BMTg0NTIzMjQ1NV5BMl5BanBnXkFtZTcwNDc3MzM5OQ@@._V1_SX300.jpg",
    "skyfall": "https://m.media-amazon.com/images/M/MV5BNWY4MTk4NTMtODk1OC00ZGZkLThmNzMtNjM3OTYwZTFmMGVkXkEyXkFqcGc@._V1_SX300.jpg",
    "silver linings playbook": "https://m.media-amazon.com/images/M/MV5BMTM2MTI5NzA3MF5BMl5BanBnXkFtZTcwODExNTc0OA@@._V1_SX300.jpg",
    "drive": "https://m.media-amazon.com/images/M/MV5BZjY5ZjQ3OGMtN3UxNC00MDFmLWFkNGYtNDBlMGJmZjZkZDFhXkEyXkFqcGc@._V1_SX300.jpg",
    "black swan": "https://m.media-amazon.com/images/M/MV5BNzY2NzI4OTE5MV5BMl5BanBnXkFtZTcwMjMyNDY4Mw@@._V1_SX300.jpg",
    "the social network": "https://m.media-amazon.com/images/M/MV5BOGUyZDUxZjEtMmIzMC00MzlmLTg4MGItZWJmMzBhZjE0Mjc1XkEyXkFqcGc@._V1_SX300.jpg",
    "star trek": "https://m.media-amazon.com/images/M/MV5BMjE5NDQ5OTE4Ml5BMl5BanBnXkFtZTcwOTE3NDIzMw@@._V1_SX300.jpg",
    "no country for old men": "https://m.media-amazon.com/images/M/MV5BMjA5Njk3MjM4OV5BMl5BanBnXkFtZTcwMTc5MTE1MQ@@._V1_SX300.jpg",
    "there will be blood": "https://m.media-amazon.com/images/M/MV5BMjAxODQ4MDU5NV5BMl5BanBnXkFtZTcwMDU4MjU1MQ@@._V1_SX300.jpg",
    "the departed": "https://m.media-amazon.com/images/M/MV5BMTI1MTY2OTIxNV5BMl5BanBnXkFtZTYpNzQ4BF3._V1_SX300.jpg",
    "pan's labyrinth": "https://m.media-amazon.com/images/M/MV5BNzk5OWY0YjAtYWU3ZS00Y2Q4LWFlNjItMzgwMTQ2MjIyMDFmXkEyXkFqcGc@._V1_SX300.jpg",
    "casino royale": "https://m.media-amazon.com/images/M/MV5BN2EyNDhmMTUtNGZmMS00Y2UxLWI5MzEtZDA5Y2VmYmUzOGQ4XkEyXkFqcGc@._V1_SX300.jpg",
    "children of men": "https://m.media-amazon.com/images/M/MV5BNDQwNDMzMDE2N15BMl5BanBnXkFtZTcwOTY4NDg2MQ@@._V1_SX300.jpg",
    "batman begins": "https://m.media-amazon.com/images/M/MV5BOTY4YjI2N2MtYmGWZi00ZDFmLWE4MTMtMjVmODUxZGRhMDA2XkEyXkFqcGc@._V1_SX300.jpg",
    "eternal sunshine of the spotless mind": "https://m.media-amazon.com/images/M/MV5BMTY4NzcwODg3Nl5BMl5BanBnXkFtZTcwNTEwOTg0OQ@@._V1_SX300.jpg",
    "kill bill: vol. 1": "https://m.media-amazon.com/images/M/MV5BNzM3NDFhYTAtYmU5Mi00NGRmLTljYTYtNDU3ZWUxNmkyOWVkXkEyXkFqcGc@._V1_SX300.jpg",
    "finding nemo": "https://m.media-amazon.com/images/M/MV5BMTY1MTI5ODAyN15BMl5BanBnXkFtZTgwZDEzMDMzNzE@._V1_SX300.jpg",
    "spirited away": "https://m.media-amazon.com/images/M/MV5BMjlmZmI5MDctNDE2YS00YWE5LWE5ZWItZDBhYWQ0NTcxNWRhXkEyXkFqcGc@._V1_SX300.jpg",
    "the lord of the rings: the fellowship of the ring": "https://m.media-amazon.com/images/M/MV5BNzQzOTk3OTAtNDQ0Zi00ZTVkLWI0MTEtMDllZjNkYzNjNTc4L2ltYWdlXkEyXkFqcGc@._V1_SX300.jpg",
    "memento": "https://m.media-amazon.com/images/M/MV5BZTJmN2E3N2UtMWRhMi00NWY2LWE3ODgtZThkOGExNmFmMTgwXkEyXkFqcGc@._V1_SX300.jpg",
    "requiem for a dream": "https://m.media-amazon.com/images/M/MV5BOTdiNzTyOWUtNjJhSt00NDU3LWI4OWEtMDNiOTQ4NDM1NDBiXkEyXkFqcGc@._V1_SX300.jpg",
    "american psycho": "https://m.media-amazon.com/images/M/MV5BNTY2NWYyMmYtMWY4Ny00OTBhLTk1YjYtYWI5M2M5YTY1YTg2XkEyXkFqcGc@._V1_SX300.jpg"
}

GENRE_POSTER_POOLS = {
    "action": [
        "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80",
        "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&q=80",
        "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800&q=80"
    ],
    "sci-fi": [
        "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80",
        "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=800&q=80",
        "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800&q=80"
    ],
    "horror": [
        "https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=800&q=80",
        "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80"
    ],
    "comedy": [
        "https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=800&q=80",
        "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800&q=80"
    ],
    "drama": [
        "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800&q=80",
        "https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=800&q=80"
    ],
    "romance": [
        "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800&q=80",
        "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=800&q=80"
    ],
    "animation": [
        "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&q=80",
        "https://images.unsplash.com/photo-1563089145-599997674d42?w=800&q=80"
    ]
}

def derive_mood(genres_str: str) -> str:
    g = genres_str.lower()
    if "action" in g or "adventure" in g:
        return "Adrenaline"
    elif "horror" in g or "thriller" in g:
        return "Thrilled"
    elif "sci-fi" in g or "mystery" in g:
        return "Mind-bent"
    elif "comedy" in g:
        return "Chilled"
    elif "romance" in g:
        return "Romantic"
    elif "animation" in g:
        return "Playful"
    elif "drama" in g or "biography" in g:
        return "Inspired"
    return "Curious"

def get_poster_url(title: str, genres_str: str, index: int) -> str:
    norm_title = title.strip().lower()
    if norm_title in CURATED_TITLE_POSTERS:
        return CURATED_TITLE_POSTERS[norm_title]

    genres = [g.strip().lower() for g in genres_str.split(",")]
    for g in genres:
        if g in GENRE_POSTER_POOLS:
            pool = GENRE_POSTER_POOLS[g]
            return pool[index % len(pool)]
            
    return "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80"

def process_imdb():
    csv_path = "backend/data/imdb_movie_dataset.csv"
    movies = []
    with open(csv_path, "r", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            try:
                rank = int(row.get("Rank", i + 1))
                title = row.get("Title", "").strip()
                genre = row.get("Genre", "").strip()
                desc = row.get("Description", "").strip()
                director = row.get("Director", "").strip()
                actors = row.get("Actors", "").strip()
                year = int(row.get("Year", 2020) or 2020)
                runtime = int(row.get("Runtime (Minutes)", 120) or 120)
                rating = float(row.get("Rating", 7.0) or 7.0)
                votes = row.get("Votes", "0").strip()
                metascore = int(row.get("Metascore", 70) or 70) if row.get("Metascore") else 70

                movie_id = f"m_{rank}"
                mood = derive_mood(genre)
                poster = get_poster_url(title, genre, i)
                base_score = 80.0 + (rating * 2.0)

                movies.append({
                    "id": movie_id,
                    "rank": rank,
                    "title": title,
                    "genre": genre,
                    "mood": mood,
                    "director": director,
                    "actors": actors,
                    "year": year,
                    "runtime": runtime,
                    "rating": rating,
                    "votes": votes,
                    "metascore": metascore,
                    "synopsis": desc,
                    "poster_url": poster,
                    "recommended_score": round(base_score, 1)
                })
            except Exception:
                continue

    print(f"Parsed {len(movies)} movies from CSV.")
    
    # Save seed file (top 200)
    seed_movies = movies[:200]
    os.makedirs("assets/data", exist_ok=True)
    with open("assets/data/movies_seed.json", "w", encoding="utf-8") as f:
        json.dump(seed_movies, f, indent=2, ensure_ascii=False)
    print("Wrote assets/data/movies_seed.json.")

    with open("backend/data/full_movies.json", "w", encoding="utf-8") as f:
        json.dump(movies, f, indent=2, ensure_ascii=False)
    print("Wrote backend/data/full_movies.json.")

if __name__ == "__main__":
    process_imdb()
