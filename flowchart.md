# CineMatch: Application Flowcharts
**Practical 12: Develop and Deploy a Complete Flutter App with Backend API and Firebase Storage**

---

## 1. Overall Application Navigation Flowchart

```mermaid
flowchart TD
    Start([Launch CineMatch App]) --> Init["WidgetsFlutterBinding.ensureInitialized()<br/>Firebase.initializeApp()"]
    Init --> Splash["Initialize Theme & Check API Health"]
    Splash --> Home["HomeScreen (Main Dashboard)"]

    Home --> ModeChoice{"Select View Mode"}
    ModeChoice -->|AI Recommendations| RecView["Filter by Mood & Genre<br/>GET /api/recommendations"]
    ModeChoice -->|All Movies| AllView["Browse & Live Search<br/>GET /api/movies"]

    RecView --> MovieList["Render Movie Grid (MovieCards)"]
    AllView --> MovieList

    MovieList --> TapCard{"User Interaction"}
    TapCard -->|Tap on Card| Detail["MovieDetailScreen"]
    TapCard -->|Tap Floating Action Button| Add["AddMovieScreen"]
    TapCard -->|Tap Settings Icon| Settings["SettingsScreen"]

    Detail --> DetailActions{"Detail Action"}
    DetailActions -->|View Synopsis| ReadDetails["Read Cast, Rating, Storage URL"]
    DetailActions -->|Edit Movie| EditDialog["Open PUT Dialog<br/>Send PUT /api/movies/:id"]
    DetailActions -->|Delete Movie| DeleteConfirm["Confirm Deletion<br/>Send DELETE /api/movies/:id"]

    EditDialog --> RefreshDetail["Update View & Return Refresh Signal"]
    DeleteConfirm --> ReturnHome["Return to HomeScreen & Reload"]

    Settings --> ConfigureURL["Set API Base URL & Ping Test (/api/health)"]
    Settings --> ToggleMock["Toggle Offline Mock Fallback"]
```

---

## 2. Firebase Cloud Storage Upload & Add Movie Flowchart

```mermaid
flowchart TD
    OpenAdd([User Opens AddMovieScreen]) --> InputMeta["Enter Title, Director, Genre, Year, Rating, Synopsis"]
    InputMeta --> PickImage["User clicks 'Gallery' or 'Camera'"]
    PickImage --> ImagePicker["ImagePicker.pickImage()"]

    ImagePicker --> CheckPick{"Image Selected?"}
    CheckPick -->|No| WaitPick["Keep placeholder"]
    CheckPick -->|Yes| ShowPreview["Display Image Preview in UI"]

    ShowPreview --> ClickUpload["User taps 'Upload To Cloud Storage'"]
    ClickUpload --> InitTask["FirebaseStorage.instance.ref('movie_posters/...')<br/>Start UploadTask"]
    InitTask --> StreamProgress["Listen to snapshotEvents (0% to 100%)"]
    StreamProgress --> UpdateBar["Update Live LinearProgressBar in UI"]

    UpdateBar --> FinishUpload{"Upload Complete?"}
    FinishUpload -->|Success| GetURL["Invoke task.snapshot.ref.getDownloadURL()"]
    FinishUpload -->|Fail / No Firebase Config| FallbackDemo["Generate Demo Cloud URL & Notify User"]

    GetURL --> SaveURL["Store Download URL in State"]
    FallbackDemo --> SaveURL

    SaveURL --> ClickSubmit["User clicks 'Publish Movie'"]
    ClickSubmit --> Validate{"Form Validated?"}
    Validate -->|No| ShowErrors["Display Validation Errors"]
    Validate -->|Yes| ConstructJSON["Construct JSON Payload with title, rating, poster_url, etc."]

    ConstructJSON --> SendPOST["HTTP POST /api/movies"]
    SendPOST --> Response{"API Response 201 Created?"}
    Response -->|Yes| SuccessToast["Show Success Notification & Pop Screen"]
    Response -->|No| FailToast["Show Error Message"]
    SuccessToast --> RefreshCatalog["HomeScreen reloads latest movie catalog"]
```

---

## 3. Backend REST API & Recommendation Engine Flowchart

```mermaid
flowchart TD
    ClientReq([Incoming HTTP Request from Flutter Client]) --> Router{"Match Endpoint Route"}

    %% Route Matches
    Router -->|GET /api/health| HealthCheck["Return 200 OK & Status Info"]
    Router -->|GET /api/movies| QueryMovies["Extract query params: genre, search, min_rating<br/>Filter Movie Catalog<br/>Return 200 OK + JSON Array"]
    Router -->|GET /api/recommendations| RecEngine["Run Content-Based Recommendation Algorithm"]
    Router -->|POST /api/movies| CreateMovie["Validate Pydantic MovieCreate Schema<br/>Generate UUID<br/>Append to Catalog<br/>Return 201 Created"]
    Router -->|PUT /api/movies/:id| UpdateMovie["Find movie by ID<br/>Update fields<br/>Return 200 OK"]
    Router -->|DELETE /api/movies/:id| DeleteMovie["Find movie by ID<br/>Remove record<br/>Return 200 OK"]

    %% Recommendation Engine Details
    RecEngine --> ForEachMovie["Iterate through each catalog movie"]
    ForEachMovie --> BaseScore["Initialize Score = movie.recommended_score"]
    BaseScore --> MoodCheck{"Movie Mood == Query Mood?"}
    MoodCheck -->|Yes| MoodBonus["Score += 15.0"]
    MoodCheck -->|No| GenreCheck
    MoodBonus --> GenreCheck{"Movie Genre == Query Genre?"}
    GenreCheck -->|Yes| GenreBonus["Score += 10.0"]
    GenreCheck -->|No| RatingFactor
    GenreBonus --> RatingFactor["Score += (movie.rating * 2.0)"]
    RatingFactor --> SortList["Sort all scored movies descending"]
    SortList --> SliceLimit["Take top N results (default 5 or 6)"]
    SliceLimit --> ReturnRecs["Return 200 OK + RecommendationResponse JSON"]
```

---

## 4. Build, Packaging & Deployment Flowchart

```mermaid
flowchart TD
    CodeReady([Complete Code & Assets Ready]) --> Step1["Step 1: Install & Verify Dependencies<br/>pip install -r requirements.txt<br/>flutter pub get"]

    Step1 --> BackendRun["Step 2: Start Backend Server<br/>uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload"]
    BackendRun --> VerifySwagger["Verify interactive docs at http://localhost:8000/docs"]

    VerifySwagger --> Step3["Step 3: Firebase Integration<br/>Download google-services.json to android/app/<br/>Configure Firebase Storage Bucket"]

    Step3 --> TestRun["Step 4: Execute & Debug on Device / Emulator<br/>flutter run"]

    TestRun --> BuildRelease["Step 5: Build Production Release APK<br/>flutter build apk --release"]
    BuildRelease --> OutputAPK["Generated APK:<br/>build/app/outputs/flutter-apk/app-release.apk"]
    OutputAPK --> DeployDevice["Deploy to Android Device for Viva / Demonstration"]
```
