# CineMatch — Movie Recommendation System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Firebase Storage](https://img.shields.io/badge/Firebase-Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS-lightgrey)](#)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-success)](#)

> **Practical 12**: *Develop and Deploy a Complete Flutter Application with a Backend API and Cloud Storage.*
>
> CineMatch is an intelligent movie recommendation and exploration platform built with a high-performance **Flutter** frontend, an asynchronous **Python FastAPI** backend, and **Firebase Cloud Storage** for media uploads.

---

## 📑 Table of Contents

- [Overview & Features](#-overview--features)
- [System Architecture](#-system-architecture)
- [Recommendation Algorithm](#-recommendation-algorithm)
- [Project Structure](#-project-structure)
- [REST API Specification](#-rest-api-specification)
- [Quick Start Guide](#-quick-start-guide)
  - [1. Backend Setup (FastAPI)](#1-backend-setup-fastapi)
  - [2. Frontend Setup (Flutter)](#2-frontend-setup-flutter)
  - [3. Firebase Cloud Storage](#3-firebase-cloud-storage)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Build & Deployment (Release APK)](#-build--deployment-release-apk)
- [Academic Attribution](#-academic-attribution)

---

## 🌟 Overview & Features

- **Mood & Genre Recommendation Engine**
  - Select from intuitive mood categories:
    - `Action & Energy`
    - `Suspense & Thrill`
    - `Mind-Bending`
    - `Chill & Relaxed`
    - `Romantic`
    - `Inspiring`
  - Select genres such as `Action`, `Sci-Fi`, `Drama`, etc.
  - Generate personalized match scores.

- **Dual-Engine Architecture**
  - Operates with a live Python FastAPI server on:
    `http://127.0.0.1:8000`
  - Automatically switches to an in-app local offline engine if the server is unreachable.

- **Full CRUD Capabilities**
  - **CREATE (POST):** Add new movies with poster images, cast, director, runtime, and custom storyline.
  - **READ (GET):** Browse 1,000 Kaggle IMDB movies with real-time search, sorting, and pagination.
  - **UPDATE (PUT):** Edit existing ratings and synopses with live updates.
  - **DELETE (DELETE):** Remove movies from the database with confirmation guards.

- **Firebase Cloud Storage Integration**
  - Upload custom movie posters directly from a device camera or photo gallery.
  - Live upload progress indicator.
  - Verified cloud poster badge.

- **Bespoke Obsidian & Vermilion Design System**
  - Restrained dark editorial palette:
    - Obsidian: `#0C0E14`
    - Slate: `#131722`
    - Vermilion: `#E23D28`
    - Gold Star: `#E8A838`
  - Clear, natural English across all screens and dialogs.
  - Instant zero-latency loading with in-memory caching and pure CSS web splash screen.

---

## 🏗 System Architecture

```mermaid
graph TD

    subgraph Client["Flutter Multiplatform Client (Web / Android / iOS)"]
        UI["Presentation Layer<br/>(HomeScreen, MovieDetailScreen, AddMovieScreen, SettingsScreen)"]
        Services["Service Layer<br/>(ApiService, WatchlistService, FirebaseStorageService)"]
        Models["Domain Models<br/>(Movie Entity, ScoreBreakdown)"]

        UI --> Services
        Services --> Models
    end

    subgraph Backend["FastAPI ASGI Service (:8000)"]
        Gateway["API Gateway & Routers<br/>(/api/movies, /api/recommendations)"]
        Engine["Weighted Scoring Engine<br/>(Base + Mood + Genre + Rating)"]
        Store["Catalog Storage<br/>(1,000 Kaggle IMDB Records)"]

        Gateway --> Engine
        Gateway --> Store
    end

    subgraph Firebase["Google Firebase Platform"]
        CloudBucket["Firebase Cloud Storage<br/>(Posters Bucket)"]
    end

    Services -- "HTTP REST (GET / POST / PUT / DELETE)" --> Gateway
    Services -- "Binary Upload / File Stream" --> CloudBucket
    CloudBucket -- "Public Download URL" --> Services
