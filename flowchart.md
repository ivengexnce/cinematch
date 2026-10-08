# CineMatch: Comprehensive Application Flowcharts
**Practical 12: Develop and Deploy a Complete Flutter Application with Backend API and Cloud Storage**

---

## 1. End-to-End Application Navigation & User Journey Flowchart

```mermaid
flowchart TD
    Start([🚀 Launch CineMatch App]) --> Init["WidgetsFlutterBinding.ensureInitialized()<br/>Firebase.initializeApp()"]
    Init --> ConcurrentBoot["Concurrent Startup:<br/>1. Load In-Memory Seed (0ms)<br/>2. Ping Backend /api/health<br/>3. Compute Match Scores"]
    
    ConcurrentBoot --> Home["📱 HomeScreen (Main Dashboard)"]
    
    %% Top Navigation & Global Controls
    Home --> TopBarActions{"Top Bar Action"}
    TopBarActions -->|Tap '+ ADD MOVIE'| AddScreen["AddMovieScreen (Cloud Upload & Form)"]
    TopBarActions -->|Tap 'Surprise Me'| SurpriseModal["Surprise Movie Modal Picker"]
    TopBarActions -->|Tap 'Settings'| SettingsScreen["SettingsScreen (Diagnostics & Analytics)"]
    
    SurpriseModal -->|View Movie| DetailScreen["MovieDetailScreen"]
    
    %% Main Tabs
    Home --> TabSelect{"Select Dashboard Tab"}
    
    %% Tab 1: Recommended
    TabSelect -->|Tab 1: RECOMMENDED| RecTab["AI Recommendation Feed"]
    RecTab --> FilterChips["Filter by Mood & Genre Chips<br/>(Adrenaline, Mind-Bending, Sci-Fi, etc.)"]
    FilterChips --> HeroRec["Featured Hero Spotlight Card"]
    HeroRec --> RecGrid["Ranked Match Grid (Affinity Badges 72%-99%)"]
    
    %% Tab 2: All Movies Catalog
    TabSelect -->|Tab 2: ALL MOVIES| CatalogTab["1,000 IMDB Movie Catalog"]
    CatalogTab --> GenreCarousel["Interactive Genre Chip Carousel (All, Sci-Fi, Action...)"]
    GenreCarousel --> LiveSearch["Debounced Search (Title, Director, Cast, Genre)"]
    LiveSearch --> FilterControls["Sort Order (Rating, Year, Title) + Min Rating Slider"]
    FilterControls --> CatalogGrid["Filtered Movie Grid View"]
    
    %% Tab 3: Watchlist
    TabSelect -->|Tab 3: WATCHLIST| WatchlistTab["Saved Movie Vault"]
    WatchlistTab --> WatchlistActions{"Watchlist Actions"}
    WatchlistActions -->|Browse Saved| SavedGrid["Watchlist Movie Cards"]
    WatchlistActions -->|Clear All| ClearVaultDialog["Confirm Clear Vault Dialog"]
    ClearVaultDialog -->|Confirm| EmptyVault["Clear In-Memory Bookmarks"]
    
    %% Movie Card Interaction
    RecGrid --> TapCard{"User Card Action"}
    CatalogGrid --> TapCard
    SavedGrid --> TapCard
    
    TapCard -->|Tap '+ Watchlist'| ToggleBookmark["Bookmark / Unbookmark Movie"]
    TapCard -->|Tap Movie Card| DetailScreen
    
    %% Detail Screen Actions
    DetailScreen --> DetailActions{"Detail Action"}
    DetailActions -->|Trailer Preview| PlayTrailer["In-App Modal Video Player"]
    DetailActions -->|Copy Summary| ShareClip["Copy Synopsis to Clipboard (Toast)"]
    DetailActions -->|Write Review / Edit| EditDialog["PUT /api/movies/:id Dialog"]
    DetailActions -->|Delete Film| DeleteConfirm["DELETE /api/movies/:id Guard"]
    DetailActions -->|Explore Similar| SimilarRecs["Smart Multi-Attribute Similar Carousel"]
    
    SimilarRecs -->|Select Film| DetailScreen
    EditDialog --> RefreshView["Update Local State & Refresh"]
    DeleteConfirm --> ReturnHome["Pop to Home & Refresh Catalog"]
```

---

## 2. Dual-Engine Resilience & Dynamic Failover Decision Tree

```mermaid
flowchart TD
    Req([Data Fetch Request: Catalog / Recommendations / Similar]) --> CheckMode{"Is Offline Mode Forced in Settings?"}
    
    CheckMode -->|Yes| LocalEngine["⚡ Execute In-App Offline Engine<br/>(Query assets/data/movies_seed.json)"]
    
    CheckMode -->|No| PingFastAPI["HTTP Ping /api/health<br/>(Timeout: 1,200ms with Stopwatch)"]
    
    PingFastAPI --> CheckHealth{"Server Responded 200 OK?"}
    
    CheckHealth -->|Yes (Remote Online)| ExecRemote["🌐 Dispatch Request to FastAPI Backend<br/>Base URL: http://127.0.0.1:8000"]
    ExecRemote --> RemoteSuccess{"HTTP 200 / 201?"}
    
    RemoteSuccess -->|Success| UpdateLatency["Record Round-Trip Latency (e.g. 14ms)<br/>Display: 'FASTAPI BACKEND ONLINE (14ms)'"]
    UpdateLatency --> RenderRemote["Render Fresh Data & Cache Locally"]
    
    RemoteSuccess -->|Network Timeout / 500| FailoverTrigger["Trigger Instant Transparent Failover"]
    CheckHealth -->|No / Offline| FailoverTrigger
    
    FailoverTrigger --> LocalEngine
    LocalEngine --> ComputeInApp["1. Jaccard Genre Intersect<br/>2. Delta Mood Matching<br/>3. Rating Normalization Formula"]
    ComputeInApp --> UpdateBadge["Display: 'OFFLINE MODE (IN-APP ENGINE)'"]
    UpdateBadge --> RenderLocal["Render Instant 0ms Local Results"]
```

---

## 3. Firebase Cloud Storage Media Upload & Ingestion Pipeline

```mermaid
flowchart TD
    OpenForm([User Opens AddMovieScreen]) --> MetaInput["Input Movie Title, Director, Actors, Genre, Year, Synopsis"]
    MetaInput --> PickMedia["User Clicks 'Gallery' or 'Camera'"]
    PickMedia --> ImagePicker["ImagePicker.pickImage(source: ImageSource)"]
    
    ImagePicker --> PickCheck{"Image File Selected?"}
    PickCheck -->|Cancelled| RetainPlaceholder["Keep Stock Unsplash Poster"]
    
    PickCheck -->|Selected| ReadBytes["Read Raw File Bytes & Inspect MIME Type"]
    ReadBytes --> PreviewUI["Display High-Res Local Image Preview"]
    
    PreviewUI --> ClickUpload["User Taps 'UPLOAD TO FIREBASE'"]
    ClickUpload --> CreateRef["FirebaseStorage.instance<br/>.ref('movie_posters/{timestamp}_{filename}.jpg')"]
    
    CreateRef --> StartTask["Create UploadTask with SettableMetadata(contentType: 'image/jpeg')"]
    StartTask --> StreamProgress["Listen to task.snapshotEvents Stream"]
    
    StreamProgress --> CalcBytes["Progress = bytesTransferred / totalBytes"]
    CalcBytes --> UpdateUIBar["Update Animated LinearProgressIndicator (0% to 100%)"]
    
    UpdateUIBar --> TaskDone{"Upload Completed?"}
    
    TaskDone -->|Success| GetURL["Call task.snapshot.ref.getDownloadURL()"]
    TaskDone -->|Storage Error / Unconfigured| MockFallback["Generate Secure Mock Cloud URL<br/>Show Fallback Notification Toast"]
    
    GetURL --> CloudURLReady["Store Firebase CDN Token URL in State"]
    MockFallback --> CloudURLReady
    
    CloudURLReady --> UserSubmit["User Taps 'PUBLISH MOVIE'"]
    UserSubmit --> ValidateForm{"Form Valid?"}
    ValidateForm -->|Errors| ShowErrors["Display Validation Prompts"]
    ValidateForm -->|Valid| BuildPayload["Construct JSON Payload with Cloud Poster URL"]
    
    BuildPayload --> SendPost["POST /api/movies"]
    SendPost --> Created{"201 Created?"}
    Created -->|Yes| InsertCatalog["Prepend to Catalog (Appears at Top)"]
    InsertCatalog --> PopClose["Pop Screen & Refresh HomeScreen"]
```

---

## 4. Multi-Factor Content-Based Recommendation Algorithm Flowchart

```mermaid
flowchart TD
    QueryIn([User Selects Mood and Genre Filter]) --> Normalize["Normalize Query:<br/>target_mood = toLowerCase(mood)<br/>target_genre = toLowerCase(genre)"]
    
    Normalize --> IterateCatalog["Iterate Over All 1,000 Catalog Movies"]
    
    subgraph ScoringEngine ["Scoring Formula: S = S_base + Δ_mood + Δ_genre + (Rating * 2.0)"]
        IterateCatalog --> FetchBase["S_base = movie.recommended_score (80.0 - 98.0)"]
        FetchBase --> MoodGate{"movie.mood matches target_mood?"}
        MoodGate -->|Match| MoodBonus["Δ_mood = +15.0"]
        MoodGate -->|No Match| MoodZero["Δ_mood = 0.0"]
        
        MoodBonus --> GenreGate{"movie.genre contains target_genre?"}
        MoodZero --> GenreGate
        
        GenreGate -->|Match| GenreBonus["Δ_genre = +10.0"]
        GenreGate -->|No Match| GenreZero["Δ_genre = 0.0"]
        
        GenreBonus --> CalcRating["Rating Factor = (movie.rating * 2.0)"]
        GenreZero --> CalcRating
        
        CalcRating --> SumRaw["S_raw = S_base + Δ_mood + Δ_genre + Rating Factor"]
        SumRaw --> NormalizeScore["S_norm = clamp( (S_raw / 142.0) * 100.0, 72.0, 99.0 )"]
        NormalizeScore --> BuildBreakdown["Construct score_breakdown Dict:<br/>{ base_score, mood_bonus, genre_bonus, rating_bonus }"]
    end
    
    BuildBreakdown --> CollectAll["Collect All Evaluated Movie Objects"]
    CollectAll --> SortList["Sort Descending:<br/>Primary Key: S_norm<br/>Secondary Key: movie.rating"]
    SortList --> SliceLimit["Slice Top N Results (Default: 12 Movies)"]
    SliceLimit --> OutputRecs([Return Ranked Recommendation List])
```

---

## 5. Multi-Attribute Similar Movie Recommendation Pipeline

```mermaid
flowchart TD
    ReqSimilar([Request: GET /api/movies/:id/similar]) --> FindTarget["Locate Target Movie by ID"]
    FindTarget --> ExtractFeatures["Extract Target Attributes:<br/>- Genres Set (e.g. Action, Sci-Fi)<br/>- Director<br/>- Mood<br/>- Release Year<br/>- IMDB Rating"]
    
    ExtractFeatures --> LoopCandidates["Loop Through Remaining Catalog Movies"]
    
    subgraph MultiFactorMath ["Similarity Score Calculation (0% - 100%)"]
        LoopCandidates --> JaccardCalc["1. Genre Jaccard Similarity (45% Weight):<br/>intersection(G_target, G_item) / union(G_target, G_item)"]
        JaccardCalc --> DirectorCalc["2. Director Exact Match (20% Weight):<br/>1.0 if director matches, else 0.0"]
        DirectorCalc --> MoodCalc["3. Mood Alignment (15% Weight):<br/>1.0 if mood matches, else 0.0"]
        MoodCalc --> EraCalc["4. Release Era Proximity (10% Weight):<br/>clamp(1.0 - abs(year_target - year_item) / 40.0, 0.0, 1.0)"]
        EraCalc --> RatingCalc["5. Rating Proximity (10% Weight):<br/>clamp(1.0 - abs(rating_target - rating_item) / 5.0, 0.0, 1.0)"]
        
        RatingCalc --> AggregateSim["Composite Similarity =<br/>(Jaccard * 45) + (Director * 20) + (Mood * 15) + (Era * 10) + (Rating * 10)"]
    end
    
    AggregateSim --> CollectSimilar["Collect Scored Candidates"]
    CollectSimilar --> SortSim["Sort Descending by Composite Similarity"]
    SortSim --> LimitResults["Slice Top 6-8 Movies"]
    LimitResults --> ReturnSimilar([Return JSON Array of Similar Movies])
```

---

## 6. REST API Full CRUD Request/Response Lifecycle

```mermaid
flowchart TD
    Incoming([Incoming Client HTTP Request]) --> CORSMiddleware["CORS Middleware Check<br/>Allow-Origin: *<br/>Methods: GET, POST, PUT, DELETE, OPTIONS"]
    
    CORSMiddleware --> RouteMatch{"Endpoint Match"}
    
    %% Route 1: Health
    RouteMatch -->|GET /api/health| HealthHandler["Check In-Memory Catalog Length<br/>Return 200 OK + Health JSON"]
    
    %% Route 2: Stats
    RouteMatch -->|GET /api/stats| StatsHandler["Aggregate Analytics:<br/>- Total Titles<br/>- Mean Rating<br/>- Genre Breakdown<br/>- Decade Histogram<br/>Return 200 OK"]
    
    %% Route 3: Movies Catalog
    RouteMatch -->|GET /api/movies| QueryCatalog["Parse Params: genre, search, min_rating, skip, limit<br/>Filter In-Memory Catalog List<br/>Return 200 OK + Paginated Array"]
    
    %% Route 4: Similar
    RouteMatch -->|GET /api/movies/:id/similar| SimilarHandler["Execute Multi-Attribute Similarity Engine<br/>Return 200 OK + Similar List"]
    
    %% Route 5: Recommendations
    RouteMatch -->|GET /api/recommendations| RecHandler["Execute Weighted Content Recommendation Engine<br/>Return 200 OK + Ranked List"]
    
    %% Route 6: Create (POST)
    RouteMatch -->|POST /api/movies| ValidateCreate{"Validate Pydantic MovieCreate Schema"}
    ValidateCreate -->|Invalid Payload| Err422["Return 422 Unprocessable Entity"]
    ValidateCreate -->|Valid| GenUUID["Generate Unique ID (custom_xxxx)<br/>Prepend to Catalog<br/>Return 201 Created"]
    
    %% Route 7: Update (PUT)
    RouteMatch -->|PUT /api/movies/:id| ValidateUpdate{"Locate Movie ID in Catalog"}
    ValidateUpdate -->|Not Found| Err404["Return 404 Movie Not Found"]
    ValidateUpdate -->|Found| MutateRecord["Update Rating, Synopsis & Recalculate Score<br/>Return 200 OK"]
    
    %% Route 8: Delete (DELETE)
    RouteMatch -->|DELETE /api/movies/:id| ValidateDelete{"Locate Movie ID in Catalog"}
    ValidateDelete -->|Not Found| Err404
    ValidateDelete -->|Found| RemoveRecord["Pop Record from Catalog<br/>Return 200 OK + Deleted Confirmation"]
```

---

## 7. Multi-Platform Build, Packaging & Production Deployment

```mermaid
flowchart TD
    Repo([Source Repository: Flutter + FastAPI]) --> DepCheck["Verify Environments:<br/>Flutter 3.22+, Python 3.10+"]
    
    DepCheck --> BranchPaths{"Select Target Platform"}
    
    %% Backend Deployment
    BranchPaths -->|Backend Service| BackendDeploy["Python FastAPI Service"]
    BackendDeploy --> LocalPy["Option A: Local ASGI<br/>uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload"]
    BackendDeploy --> DockerPy["Option B: Docker Container<br/>docker build -t cinematch-api .<br/>docker run -d -p 8000:8000 cinematch-api"]
    
    %% Android Release
    BranchPaths -->|Android Mobile| AndroidBuild["flutter build apk --release --split-per-abi"]
    AndroidBuild --> OutputAPK["Generated Release Package:<br/>build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"]
    OutputAPK --> AdbInstall["Deploy to Device / Emulator:<br/>adb install -r app-arm64-v8a-release.apk"]
    
    %% Web PWA Release
    BranchPaths -->|Web Client| WebBuild["flutter build web --release"]
    WebBuild --> OutputWeb["Generated PWA Web Assets in build/web/"]
    OutputWeb --> StaticHost["Deploy to Firebase Hosting / GitHub Pages / Nginx"]
    
    AdbInstall --> VivaDemo([Viva / Demonstration Ready])
    StaticHost --> VivaDemo
    LocalPy --> VivaDemo
```

---

## 8. Community Recommendation, User Rating & Consensus Flow

```mermaid
flowchart TD
    UserApp([User in CineMatch App]) --> ViewMovie["Views Movie Details in MovieDetailScreen"]
    
    %% Recommendation Branch
    ViewMovie --> RecAction["User Clicks '👍 RECOMMEND FILM'"]
    RecAction --> AuthCheck["AuthService Checks User Status"]
    AuthCheck --> LocalToggle["Toggle Local Set in AuthService<br/>Update 0ms Immediate Counter in UI"]
    LocalToggle --> ApiRec["ApiService.toggleRecommendation(movieId, userId)"]
    
    ApiRec --> RemoteRec{"FastAPI Online?"}
    RemoteRec -->|Yes| PostRec["POST /api/movies/{id}/recommend<br/>body: {'user_id': userId}"]
    PostRec --> RecPersist["Save Mutated Catalog to active_catalog.json"]
    RemoteRec -->|Offline| LocalSeedRec["Update in-memory catalog record"]
    
    %% Rating Branch
    ViewMovie --> RateAction["User Clicks '★ RATE FILM'"]
    RateAction --> RateModal["Opens 1.0 - 10.0 Rating Slider Dialog"]
    RateModal --> SubmitScore["User Selects Score & Submits"]
    SubmitScore --> LocalRate["AuthService.setUserRating(movieId, score)<br/>Update Local State"]
    LocalRate --> ApiRate["ApiService.submitUserRating(movieId, userId, score)"]
    
    ApiRate --> RemoteRate{"FastAPI Online?"}
    RemoteRate -->|Yes| PostRate["POST /api/movies/{id}/rate<br/>body: {'user_id': userId, 'rating': score}"]
    PostRate --> RatePersist["Recompute Community Average<br/>Save to active_catalog.json"]
    RemoteRate -->|Offline| LocalSeedRate["Recompute average in-memory"]
    
    %% Consensus Top Rating
    RecPersist --> RecalcTop["Recalculate Composite Top Rating:<br/>0.60 * IMDb + 0.25 * UserAvg + 0.15 * RecsBonus"]
    RatePersist --> RecalcTop
    LocalSeedRec --> RecalcTop
    LocalSeedRate --> RecalcTop
    
    RecalcTop --> FeedSort["Displayed in '★ TOP RATED' & '🔥 MOST RECOMMENDED' Catalog Sorts"]
    FeedSort --> Done([Real-Time Community Ranking Updated])
```
