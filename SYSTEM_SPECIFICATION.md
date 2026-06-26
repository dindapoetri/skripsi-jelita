# JELITA Skincare Recommendation System - Complete System Specification

**Document Version:** 1.0.0  
**Last Updated:** June 2026  
**System Name:** Jelita - Intelligent Skincare Type & Product Recommendation Platform  
**Application Type:** Mobile App (Flutter) + REST API Backend (FastAPI)

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [System Components](#system-components)
4. [Frontend (Flutter) Application](#frontend-flutter-application)
5. [Backend (FastAPI) Services](#backend-fastapi-services)
6. [Machine Learning Services](#machine-learning-services)
7. [Database Schema & Structure](#database-schema--structure)
8. [Data Flow & User Journeys](#data-flow--user-journeys)
9. [API Endpoints Reference](#api-endpoints-reference)
10. [Authentication & Security](#authentication--security)
11. [Configuration & Deployment](#configuration--deployment)
12. [Error Handling & Logging](#error-handling--logging)
13. [Third-Party Integrations](#third-party-integrations)

---

## System Overview

### Purpose
Jelita is an intelligent skincare recommendation system that helps users identify their skin type using AI and provides personalized skincare product recommendations based on their skin type and concerns.

### Core Features
- **Skin Type Classification**: Uses CNN (MobileNetV3) to classify skin type from facial photos (5 categories: oily, dry, normal, combination, sensitive)
- **Symptom Detection**: Users can select skin concerns/symptoms they're experiencing
- **Product Recommendations**: Content-Based Filtering (CBF) with TF-IDF vectorization to recommend suitable skincare products
- **User Authentication**: Register/login system with JWT tokens
- **Scan History**: Users can view previous skin scans and results
- **Guest Mode**: Users can test skin classification without creating an account

### Key Stakeholders
- **End Users**: People seeking skincare advice and product recommendations
- **Admin**: System managers for content and ML model updates
- **Mobile Users**: iOS & Android via Flutter cross-platform app
- **Data Analysts**: For monitoring system performance and recommendations quality

---

## Architecture & Technology Stack

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Mobile App                 │
│  (Camera, UI, Local Storage, API Communication)     │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP/REST (Bearer Token)
                       │
┌──────────────────────▼──────────────────────────────┐
│            FastAPI Backend Server                    │
│  ┌─────────────────────────────────────────────┐   │
│  │  Auth | Classify | Recommendations | History │   │
│  └─────────────────────────────────────────────┘   │
└──────┬──────────────────────────┬──────────────────┘
       │                          │
       ▼                          ▼
┌─────────────────┐    ┌──────────────────────┐
│  Supabase DB    │    │  ML Models           │
│  (PostgreSQL)   │    │  - CNN (PyTorch)     │
│  - Users        │    │  - CBF (scikit-learn)│
│  - Products     │    └──────────────────────┘
│  - History      │
│  - Metadata     │
└─────────────────┘
```

### Frontend Stack (Flutter)
- **Framework**: Flutter 3.10.7+
- **Language**: Dart
- **State Management**: Local widget state management
- **Database**: Local storage via SharedPreferences (for cache)
- **Image Processing**: image_picker, Device Preview
- **Backend Communication**: http, supabase_flutter
- **Utilities**: intl (internationalization), path_provider, aiofiles
- **ML On-Device**: PyTorch Lite (pytorch_lite) for CNN inference

### Backend Stack (FastAPI)
- **Framework**: FastAPI 0.111.0
- **Server**: Uvicorn 0.29.0
- **Language**: Python 3.10.7+
- **Database**: PostgreSQL with asyncpg (async support)
- **ORM/Query**: SQLAlchemy (if needed) + Supabase client
- **Authentication**: JWT with python-jose
- **Password Hashing**: Passlib with bcrypt
- **ML Frameworks**: PyTorch 2.3.0, scikit-learn 1.4.2
- **Data Processing**: NumPy, Pandas, Pillow
- **File Handling**: aiofiles for async file operations
- **API Validation**: Pydantic 2.7.1+

### Database
- **Primary**: Supabase (PostgreSQL-based cloud database)
- **Authentication**: Supabase Auth (built-in user management)
- **Key Tables**: users, products, classification_results, face_captures, cbf_metadata, history_scans

### ML Models
- **CNN Model**: MobileNetV3-Small fine-tuned on skin type classification
  - Input: 224x224 RGB images
  - Output: 5 skin type classes (oily, dry, normal, combination, sensitive)
  - Format: PyTorch (.ptl - TorchScript format)
  - Location: `assets/models/cnn/mobilenetv3_skintype_90.ptl`

- **CBF Model**: Content-Based Filtering using TF-IDF vectorization
  - Input: Skin type + concerns (text)
  - Output: Ranked product recommendations
  - Format: scikit-learn joblib (.jotlib)
  - Location: `jelita_backend/assets/models/cbf/cbf_model_22june.jotlib`

---

## System Components

### 1. Frontend Components (Flutter)

#### Screen Structure
```
lib/
├── features/
│   ├── splash/               # Splash screen & initial setup
│   ├── authentication/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── forgotpassword_screen.dart
│   ├── home/                # Main home/dashboard
│   ├── symptoms/            # Symptom/concern selection
│   ├── result/              # Display skin type results
│   ├── recommendation/      # Show product recommendations
│   ├── history/             # View scan history
│   └── profile/             # User profile & settings
│
├── data/
│   ├── models/
│   │   ├── product_model.dart           # Product data structure
│   │   ├── skin_result_models.dart      # Skin scan results
│   │   └── recommendation_model.dart    # Recommendation structure
│   └── repositories/
│       ├── skin_repositories.dart       # Skin classification API calls
│       ├── recommendation_repositories.dart  # Get recommendations
│       └── history_repository.dart      # History management
│
├── widgets/                 # Reusable UI components
├── routes/
│   └── app_routes.dart      # Navigation routing
├── src/
│   └── constant/            # App-wide constants, themes, strings
└── main.dart               # App entry point
```

#### Key Screens

**1. Splash Screen (`features/splash/`)**
- Initial app loading state
- Authentication check (token validation)
- Navigation to login/home based on auth status

**2. Authentication Screens (`features/authentication/`)**
- **Login**: Email/password authentication with JWT token retrieval
- **Signup**: User registration with validation (email format, password strength)
- **Forgot Password**: Password recovery flow

**3. Home Screen (`features/home/`)**
- Dashboard with quick actions
- Option to start new skin scan
- Quick access to history and recommendations
- User greeting with profile info

**4. Symptoms Screen (`features/symptoms/`)**
- Display checklist of common skin concerns:
  - Acne
  - Dryness
  - Oiliness
  - Sensitivity
  - Redness
  - Wrinkles
  - Dark spots
  - Etc.
- Users can multi-select concerns
- Navigation to camera for photo capture or image selection

**5. Result Screen (`features/result/`)**
- Display CNN prediction results:
  - Detected skin type (with visual indicator)
  - Confidence score (0-100%)
  - Probability distribution for all 5 skin types
  - User-selected symptoms/concerns
- Option to proceed to recommendations or view history

**6. Recommendation Screen (`features/recommendation/`)**
- Display product recommendations organized by category:
  - Facial Wash
  - Toner
  - Moisturizer
  - Sunscreen
- Each product card shows:
  - Product name & brand
  - Category
  - Price range
  - Suitable skin types
  - Key ingredients
  - Usage instructions
  - Score/match percentage
- Ability to view more details or open product link

**7. History Screen (`features/history/`)**
- List of user's previous scans with pagination (20 per page)
- Each history item shows:
  - Scan date & time
  - Skin type detected
  - Confidence score
  - Thumbnail of scanned image
  - Click to view full details
- Ability to delete individual scans or all history

**8. Profile Screen (`features/profile/`)**
- User information display:
  - Full name
  - Email
  - Account creation date
- Options:
  - Edit profile
  - Account security settings
  - Logout

### 2. Backend Components (FastAPI)

#### Project Structure
```
jelita_backend/
├── app/
│   ├── main.py                    # FastAPI app initialization & lifespan
│   ├── api/v1/
│   │   ├── router.py             # Route aggregator
│   │   └── endpoints/
│   │       ├── auth.py           # Authentication endpoints
│   │       ├── classify.py       # Skin classification
│   │       ├── recommendations.py # Product recommendations
│   │       ├── history.py        # Scan history management
│   │       └── health.py         # Health check
│   │
│   ├── core/
│   │   ├── config.py             # Configuration from .env
│   │   └── security.py           # JWT, password hashing, auth
│   │
│   ├── db/
│   │   └── database.py           # Supabase connection setup
│   │
│   ├── models/                   # SQLAlchemy ORM models (if needed)
│   │   └── history.py
│   │
│   ├── schemas/                  # Pydantic request/response models
│   │   ├── auth_schema.py
│   │   ├── history_schema.py
│   │   └── product_schema.py
│   │
│   ├── services/                 # Business logic
│   │   ├── cnn_service.py       # CNN model loading & inference
│   │   ├── cbf_service.py       # CBF recommendation logic
│   │   ├── user_service.py      # User CRUD operations
│   │   └── history_service.py   # History management
│   │
│   └── utils/
│       └── file_utils.py        # File upload & validation
│
├── database/
│   └── setup.sql               # SQL schema (legacy, using Supabase now)
│
├── ml_models/                  # ML model files directory
│   ├── cbf/
│   └── cnn/
│
├── uploads/
│   └── photos/                 # User uploaded images storage
│
├── assets/
│   └── models/                 # ML model files
│       ├── cnn/
│       │   └── mobilenetv3_skintype_90.ptl
│       └── cbf/
│           └── cbf_model_22june.jotlib
│
├── .env.example               # Environment variables template
├── requirements.txt           # Python dependencies
├── run.sh                      # Startup script
└── README.md                   # Setup instructions
```

---

## Frontend (Flutter) Application

### 1. Data Models

#### ProductModel
```dart
class ProductModel {
  String id;               // Unique product ID (UUID from Supabase)
  String name;             // Product name
  String brand;            // Brand name
  String category;         // Category: facial_wash, toner, moisturizer, sunscreen
  String description;      // Product description
  List<String> suitableSkinTypes;  // Skin types this product is suitable for
  List<String> concerns;   // Keywords/ingredients/concerns
  List<String> ingredients; // Active ingredients
  List<String> usageSteps; // How to use steps
  String priceRange;       // Price range (e.g., "100K-200K")
  String? imageUrl;        // Product image URL
  String? suitableFor;     // Additional suitable-for info
}
```

#### SkinResultModel
```dart
class SkinResultModel {
  String skinType;                    // Detected skin type (oily/dry/normal/combination/sensitive)
  double confidence;                  // Confidence score (0.0-1.0)
  String description;                 // Description of skin type
  List<String> idealIngredients;      // Recommended ingredients
  List<String> concerns;              // Detected/selected concerns
  List<String> recommendations;       // Product recommendations list
  Map<String, double> probabilities;  // All skin type probabilities
  String imagePath;                   // Path to scanned image
  DateTime createdAt;                 // Scan timestamp
  List<String> symptoms;              // Selected symptoms
}
```

#### RecommendationModel
```dart
class RecommendationModel {
  List<ProductModel> facialWash;
  List<ProductModel> toner;
  List<ProductModel> moisturizer;
  List<ProductModel> sunscreen;
  String skinType;
  List<String> concerns;
}
```

### 2. API Data Repositories

#### SkinRepository
**Endpoints Called:**
- `POST /api/v1/classify/` - Upload photo for classification
- `POST /api/v1/classify/guest` - Guest classification (no auth)

**Methods:**
- `classifyImage(File imageFile, List<String> concerns)` - Send image + concerns to backend
- `predictSkinType(File imageFile)` - Guest skin type prediction

**Response Handling:**
- CNN prediction results with confidence & probabilities
- Image storage URL from backend
- History scan ID for future reference

#### RecommendationRepository
**Endpoints Called:**
- `POST /api/v1/recommendations/` - Get product recommendations
- `POST /api/v1/recommendations/guest` - Guest recommendations

**Methods:**
- `getRecommendations(String skinType, List<String> concerns)` - Fetch recommendations
- `getGuestRecommendations(String skinType, List<String> concerns)`

**Response Handling:**
- Products organized by category (facial_wash, toner, moisturizer, sunscreen)
- Product details including match score

#### HistoryRepository
**Endpoints Called:**
- `GET /api/v1/history/{user_id}` - Get user's scan history
- `GET /api/v1/history/{user_id}/{scan_id}` - Get specific scan details
- `POST /api/v1/history/` - Create new history entry
- `DELETE /api/v1/history/{user_id}/{scan_id}` - Delete single history
- `DELETE /api/v1/history/{user_id}` - Delete all history

**Methods:**
- `getUserHistory(UUID userId, {int limit, int offset})` - Fetch user's history with pagination
- `getHistoryDetail(UUID userId, int scanId)` - Get detailed history entry
- `deleteHistory(UUID userId, int scanId)` - Delete specific history entry
- `deleteAllHistory(UUID userId)` - Delete entire user history

### 3. Application Flow

#### User Journey: New User (Skin Classification)

```
SplashScreen
    ↓ (Check auth token)
    ├─→ [No token] → LoginScreen
    │       ↓
    │   SignupScreen (Register)
    │       ↓
    │   [JWT Token obtained]
    │
    ├─→ [Token exists] → HomeScreen
            ↓
        [User clicks "Scan Skin"]
            ↓
        SkinSymptomsScreen
            ├─→ [Select symptoms/concerns]
            ├─→ [Take or select photo]
            ↓
        [Upload to backend]
            ↓
        ResultScreen
            ├─→ Display CNN results (skin type, confidence, probabilities)
            ├─→ Display selected symptoms
            ↓
        RecommendationScreen
            ├─→ Display recommended products by category
            ├─→ Show match scores
            ↓
        [Save to history automatically]
            ↓
        [Option to view history or start new scan]
```

#### User Journey: View History

```
HomeScreen
    ↓
[Click "View History"]
    ↓
HistoryScreen
    ├─→ Load paginated history (20 items per page)
    ├─→ Display each scan: date, skin type, confidence, image thumbnail
    ├─→ [Tap item] → ResultScreen (show past results)
    ├─→ [Delete item] → Confirm & remove from history
    ├─→ [Delete all] → Confirm & clear all history
```

---

## Backend (FastAPI) Services

### 1. API Endpoints

#### Authentication Endpoints (`/api/v1/auth`)

**POST `/auth/register`**
- **Purpose**: User registration
- **Request**:
  ```json
  {
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "securePassword123"
  }
  ```
- **Response** (201 Created):
  ```json
  {
    "access_token": "eyJhbGc...",
    "user": {
      "id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "is_active": true,
      "created_at": "2026-06-25T10:30:00Z"
    }
  }
  ```
- **Error Cases**:
  - 400: Email already registered
  - 400: Invalid email format
  - 400: Weak password

**POST `/auth/login`**
- **Purpose**: User login
- **Request**:
  ```json
  {
    "email": "john@example.com",
    "password": "securePassword123"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "access_token": "eyJhbGc...",
    "user": {
      "id": "uuid",
      "full_name": "John Doe",
      "email": "john@example.com",
      "is_active": true,
      "created_at": "2026-06-25T10:30:00Z"
    }
  }
  ```
- **Error Cases**:
  - 401: Email not found or password incorrect

**GET `/auth/me`**
- **Purpose**: Get current user profile
- **Authentication**: Required (Bearer token)
- **Response** (200 OK):
  ```json
  {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com",
    "is_active": true,
    "created_at": "2026-06-25T10:30:00Z"
  }
  ```

**POST `/auth/change-password`**
- **Purpose**: Change user password
- **Authentication**: Required
- **Request**:
  ```json
  {
    "current_password": "oldPassword123",
    "new_password": "newPassword456"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "success": true,
    "message": "Password berhasil diubah"
  }
  ```
- **Error Cases**:
  - 401: Current password incorrect

#### Classification Endpoints (`/api/v1/classify`)

**POST `/classify/`** (Authenticated)
- **Purpose**: Upload photo & get skin classification + recommendations
- **Authentication**: Required (Bearer token)
- **Request**: multipart/form-data
  ```
  photo: <binary image file>
  concerns: ["acne", "oiliness"]  (JSON array string)
  ```
- **Response** (200 OK):
  ```json
  {
    "skin_type": "oily",
    "confidence": 0.92,
    "all_scores": {
      "oily": 0.92,
      "normal": 0.05,
      "dry": 0.02,
      "combination": 0.01,
      "sensitive": 0.00
    },
    "image_url": "uploads/photos/scans/2026-06-25_12345.jpg",
    "history_id": 42
  }
  ```
- **Processing Steps**:
  1. Save uploaded photo to storage
  2. Run CNN inference on image
  3. Get CBF recommendations based on skin type + concerns
  4. Save to history_scans table
  5. Return results
- **Error Cases**:
  - 400: No file provided
  - 413: File size exceeds 5MB
  - 415: Invalid image format
  - 401: Unauthorized (invalid token)

**POST `/classify/guest`**
- **Purpose**: Classify skin without authentication
- **Authentication**: Not required
- **Request**: multipart/form-data
  ```
  photo: <binary image file>
  ```
- **Response** (200 OK):
  ```json
  {
    "skin_type": "oily",
    "confidence": 0.92,
    "all_scores": {
      "oily": 0.92,
      "normal": 0.05,
      "dry": 0.02,
      "combination": 0.01,
      "sensitive": 0.00
    },
    "image_url": "uploads/photos/guest/2026-06-25_12345.jpg"
  }
  ```
- **Note**: Results not saved to user history

#### Recommendations Endpoints (`/api/v1/recommendations`)

**POST `/recommendations/`** (Authenticated)
- **Purpose**: Get product recommendations based on skin type & concerns
- **Authentication**: Required
- **Request**:
  ```json
  {
    "skin_type": "oily",
    "concerns": ["acne", "sebum"],
    "top_n": 5
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "skin_type": "oily",
    "concerns": ["acne", "sebum"],
    "recommendations": {
      "facial_wash": [
        {
          "id": "p1",
          "name": "Cleansing Foam",
          "brand": "BrandA",
          "category": "facial_wash",
          "description": "...",
          "skin_types": ["oily"],
          "concerns": ["acne"],
          "score": 0.89
        }
        // ... up to top_n products
      ],
      "toner": [...],
      "moisturizer": [...],
      "sunscreen": [...]
    },
    "total_products_analyzed": 156
  }
  ```
- **Logic**:
  - Query CBF metadata for TF-IDF vocabulary
  - Build query vector from skin_type + concerns
  - Calculate cosine similarity with all products
  - Return top_n products per category
  - Filter by skin type compatibility

**POST `/recommendations/guest`**
- **Purpose**: Get recommendations without authentication
- **Authentication**: Not required
- **Request/Response**: Same as authenticated endpoint
- **Difference**: No user context, just based on provided parameters

#### History Endpoints (`/api/v1/history`)

**GET `/history/{user_id}`**
- **Purpose**: Get user's scan history (paginated)
- **Authentication**: Required (caller must be same user)
- **Query Parameters**:
  - `limit` (int, default=20): Items per page
  - `offset` (int, default=0): Pagination offset
- **Response** (200 OK):
  ```json
  {
    "message": "success",
    "data": [
      {
        "id": 42,
        "user_id": "uuid",
        "skin_type": "oily",
        "cnn_confidence": 0.92,
        "concerns": ["acne", "oiliness"],
        "image_url": "uploads/photos/scans/...",
        "recommendations_snapshot": [
          {
            "id": "p1",
            "name": "Cleanser",
            "category": "facial_wash"
          }
        ],
        "created_at": "2026-06-25T10:30:00Z"
      },
      // ... more history items
    ]
  }
  ```
- **Error Cases**:
  - 401: Unauthorized (different user)
  - 500: Database error

**GET `/history/{user_id}/{scan_id}`**
- **Purpose**: Get specific history scan details
- **Authentication**: Required
- **Response** (200 OK):
  ```json
  {
    "message": "success",
    "data": {
      "id": 42,
      "user_id": "uuid",
      "skin_type": "oily",
      "cnn_confidence": 0.92,
      "concerns": ["acne"],
      "image_url": "uploads/photos/scans/2026-06-25_12345.jpg",
      "recommendations_snapshot": [
        {
          "id": "p1",
          "name": "Cleanser",
          "brand": "BrandA",
          "category": "facial_wash",
          "description": "...",
          "skin_types": ["oily"],
          "price_range": "100K-150K"
        }
      ],
      "created_at": "2026-06-25T10:30:00Z"
    }
  }
  ```
- **Error Cases**:
  - 404: History not found or doesn't belong to user
  - 401: Unauthorized

**POST `/history/`**
- **Purpose**: Create new history entry
- **Authentication**: Required
- **Request**:
  ```json
  {
    "user_id": "uuid",
    "skin_type": "oily",
    "cnn_confidence": 0.92,
    "concerns": ["acne"],
    "image_url": "uploads/photos/scans/...",
    "recommendations_snapshot": [...]
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "message": "success",
    "data": {
      "id": 42,
      ...
    }
  }
  ```

**DELETE `/history/{user_id}/{scan_id}`**
- **Purpose**: Delete single history entry
- **Authentication**: Required
- **Response** (200 OK):
  ```json
  {
    "message": "deleted successfully"
  }
  ```
- **Error Cases**:
  - 404: History not found

**DELETE `/history/{user_id}`**
- **Purpose**: Delete all user history
- **Authentication**: Required
- **Response** (200 OK):
  ```json
  {
    "message": "success",
    "deleted_count": 25
  }
  ```

#### Health Check Endpoints

**GET `/health`**
- **Purpose**: Health check
- **Authentication**: Not required
- **Response** (200 OK):
  ```json
  {
    "status": "ok"
  }
  ```

**GET `/`**
- **Purpose**: Root endpoint with app info
- **Response** (200 OK):
  ```json
  {
    "app": "Jelita Skincare API",
    "version": "1.0.0",
    "status": "running",
    "docs": "/docs"
  }
  ```

### 2. Service Layer

#### CNNService (`services/cnn_service.py`)
**Responsibility**: Skin type classification using MobileNetV3

**Key Functions**:
- `load_cnn_model()` - Load PyTorch model from disk
- `_create_default_model()` - Create default MobileNetV3-Small
- `predict_skin_type(image_bytes) → (skin_type, confidence, all_scores)` - Inference on image

**Model Details**:
- **Architecture**: MobileNetV3-Small (efficient for mobile)
- **Input**: 224×224 RGB images
- **Output**: 5 classes (probabilities normalized with softmax)
- **Classes**:
  - 0: oily (Kulit Berminyak)
  - 1: dry (Kulit Kering)
  - 2: normal (Kulit Normal)
  - 3: combination (Kulit Kombinasi)
  - 4: sensitive (Kulit Sensitif)

**Preprocessing**:
- Resize to 224×224
- Convert to RGB tensor
- Normalize: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]

**Error Handling**:
- If model not found, uses untrained default MobileNetV3
- Logs warning but continues operation
- Returns fallback predictions

#### CBFService (`services/cbf_service.py`)
**Responsibility**: Content-Based Filtering product recommendations

**Key Functions**:
- `load_metadata()` - Load TF-IDF vocabulary & IDF from Supabase
- `build_product_cache()` - Load all active products from Supabase
- `_build_query_text(skin_type, concerns)` - Convert input to query string
- `_build_query_vector(text)` - Create TF-IDF vector from text
- `get_recommendations(skin_type, concerns, top_n)` - Get recommended products

**How It Works**:
1. **Query Building**:
   - Convert skin_type to descriptive terms (e.g., "oily" → "oily acne sebum oil")
   - Combine with user concerns
   - Result: query text like "oily acne sebum oil breakout"

2. **Vectorization**:
   - Split query text into tokens
   - Look up each token in vocabulary
   - Count term frequencies
   - Multiply by IDF scores to get TF-IDF vector

3. **Similarity Calculation**:
   - Calculate cosine similarity between query vector and all product vectors
   - Product vectors stored in database (pre-computed)

4. **Result Ranking**:
   - Sort by similarity score (descending)
   - Filter products suitable for skin type
   - Return top_n per category

**Global Cache**:
```python
_product_cache: List[Dict]       # All products in memory
_product_matrix: np.ndarray      # Vectorized products for fast similarity
_vocab: Dict[str, int]           # TF-IDF vocabulary
_idf: np.ndarray                 # IDF scores per term
```

**Database Integration**:
- Products loaded from `products` table via Supabase
- Metadata loaded from `cbf_metadata` table
- Updates on server startup (lifespan event)

#### UserService (`services/user_service.py`)
**Responsibility**: User CRUD operations

**Key Functions**:
- `get_user_by_email(email)` - Fetch user by email
- `get_user_by_id(user_id)` - Fetch user by UUID
- `create_user(data)` - Register new user
- `authenticate_user(email, password)` - Login validation
- `update_user_password(user_id, new_hash)` - Change password

**Data Flow**:
- Uses Supabase client for all operations
- Passwords hashed with bcrypt (never stored plain)
- All async/await for non-blocking database access

#### HistoryService (`services/history_service.py`)
**Responsibility**: Scan history management

**Key Functions**:
- `create_history_scan(user_id, data)` - Save new scan result
- `get_user_history(user_id, limit, offset)` - Fetch paginated history
- `get_history_by_id(scan_id, user_id)` - Get specific history
- `delete_history_scan(scan_id, user_id)` - Delete one scan
- `delete_all_user_history(user_id)` - Clear all user history

**Linked Resources**:
- Optional face_capture_id (links to face_captures table if image saved)
- Recommendations snapshot (JSON of products at time of scan)

### 3. Security Layer

#### Authentication (`core/security.py`)

**JWT Token Management**:
- **Algorithm**: HS256
- **Secret Key**: Configured in .env (minimum 256-bit)
- **Expiration**: 86400 minutes (≈60 days)
- **Payload**: `{"sub": user_id, "exp": expiration_timestamp}`

**Functions**:
- `create_access_token(data)` - Generate JWT token
- `get_current_user(token)` - Validate token and extract user

**Password Security**:
- **Hashing**: Passlib with bcrypt
- **Salting**: Automatic in bcrypt (rounds: 12)
- **Verification**: Constant-time comparison

**Middleware**:
- CORS enabled for all origins (configurable)
- Bearer token validation on protected endpoints

---

## Machine Learning Services

### 1. CNN Skin Type Classification

#### Model Specifications
- **Framework**: PyTorch
- **Architecture**: MobileNetV3-Small
- **Task**: Multi-class classification (5 skin types)
- **Input**: 224×224 RGB images
- **Training Data**: Annotated facial images for each skin type
- **Performance**: ~90% accuracy on test set (filename: mobilenetv3_skintype_90.ptl)

#### Inference Pipeline

```
User Photo
    ↓
Save to disk
    ↓
Read as bytes
    ↓
PIL.Image.open() → RGB conversion
    ↓
Resize to 224×224
    ↓
Normalize: ImageNet stats
    ↓
Convert to tensor: [1, 3, 224, 224]
    ↓
CNN forward pass
    ↓
Output logits (5 values)
    ↓
Softmax → probabilities (sum = 1.0)
    ↓
Argmax → predicted class index
    ↓
Map to skin type label
    ↓
Return: (skin_type, confidence, all_scores)
```

#### Confidence Scoring
- `confidence` = maximum probability from softmax output
- Range: 0.0 to 1.0
- Example: For output [0.92, 0.05, 0.02, 0.01, 0.00]
  - `skin_type` = "oily" (argmax = 0)
  - `confidence` = 0.92

#### Classes & Mapping
```python
SKIN_LABELS = {
    0: "oily",
    1: "dry",
    2: "normal",
    3: "combination",
    4: "sensitive",
}

# Indonesian translations
SKIN_LABELS_ID = {
    "oily": "Kulit Berminyak",
    "dry": "Kulit Kering",
    "normal": "Kulit Normal",
    "combination": "Kulit Kombinasi",
    "sensitive": "Kulit Sensitif",
}
```

### 2. Content-Based Filtering (CBF) Recommendations

#### TF-IDF Vectorization

**TF (Term Frequency)**:
```
TF(term, document) = count of term in document
```

**IDF (Inverse Document Frequency)**:
```
IDF(term) = log(total documents / documents containing term)
```

**TF-IDF**:
```
TF-IDF(term) = TF(term) × IDF(term)
```

#### Query Processing Example
**Input**: 
- Skin type: "oily"
- Concerns: ["acne", "sebum"]

**Query Text Construction**:
```
"oily acne sebum oil" 
  ↑       ↑     ↑    ↑
skin_type concern concern mapping
```

**Vectorization**:
- For each token in query text:
  - If token in vocabulary → get index
  - Add term frequency: vec[index] += 1.0
- Multiply entire vector by IDF scores
- Normalize (optional L2 normalization)

#### Recommendation Scoring
**Cosine Similarity**:
```
similarity(query, product) = dot(query_vec, product_vec) / (norm(query_vec) × norm(product_vec))
range: -1.0 to 1.0 (typically 0.0 to 1.0 for positive features)
```

**Result Filtering**:
1. Calculate similarity scores for all products
2. Filter by skin type compatibility
3. Sort by similarity (descending)
4. Group by category
5. Return top_n per category

#### Product Vector Storage
- Pre-computed TF-IDF vectors stored in database
- `products.tfidf_vector` column (array/JSON)
- Updated when product data changes
- Loaded into memory at startup for fast inference

---

## Database Schema & Structure

### Tables Overview

#### 1. users
```sql
CREATE TABLE users (
  id              UUID PRIMARY KEY,           -- Auto-generated UUID
  full_name       VARCHAR(100) NOT NULL,
  email           VARCHAR(150) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,     -- bcrypt hash
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ
);
```

**Indexes**: `idx_users_email` on email column (fast login lookup)

**Relationships**:
- One-to-Many: users → classification_results
- One-to-Many: users → face_captures

#### 2. products
```sql
CREATE TABLE products (
  id              UUID PRIMARY KEY,
  product_name    VARCHAR(255) NOT NULL,
  brand           VARCHAR(150),
  category        VARCHAR(50) NOT NULL,       -- facial_wash, toner, moisturizer, sunscreen
  description     TEXT,                       -- Raw description
  description_clean TEXT,                     -- Cleaned for display
  how_to_use      TEXT,                       -- Usage instructions
  suitable_for    TEXT,                       -- Additional suitability info
  ingredients     TEXT or JSONB,              -- Active ingredients (comma-separated or array)
  image_url       VARCHAR(500),               -- Product image
  url             VARCHAR(500),               -- Link to product page
  skin_types      JSONB,                      -- ["oily", "normal"] - suitable skin types
  concerns        JSONB,                      -- Keywords/ingredients
  tfidf_vector    FLOAT8[],                   -- Pre-computed TF-IDF vector for CBF
  is_active       BOOLEAN DEFAULT TRUE,       -- Soft delete flag
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ
);
```

**Indexes**: 
- `idx_products_category` on category
- `idx_products_name` on product_name
- `idx_products_active` on is_active

**Data Considerations**:
- `concerns` column currently contains ingredients/keywords (not user skin concerns)
- Used for CBF vectorization
- Updated when product data refreshed

#### 3. classification_results
```sql
CREATE TABLE classification_results (
  id                      SERIAL PRIMARY KEY,
  user_id                 UUID NOT NULL REFERENCES users(id),
  skin_type               VARCHAR(50) NOT NULL,    -- oily/dry/normal/combination/sensitive
  confidence_score        FLOAT,                   -- 0.0-1.0
  detected_symptoms       JSONB DEFAULT '[]',     -- ["acne", "dryness"]
  concerns                JSONB DEFAULT '[]',     -- User-selected concerns
  description             TEXT,                   -- Description of results
  probabilities           JSONB DEFAULT '{}',     -- All 5 skin type probabilities
  recommendations         JSONB DEFAULT '[]',     -- Product recommendations at time of scan
  ideal_ingredients       JSONB DEFAULT '[]',     -- Recommended ingredients
  face_capture_id         UUID REFERENCES face_captures(id),
  created_at              TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
- `idx_class_user_id` on user_id
- `idx_class_created` on created_at DESC (recent first)

**Historical Data**:
- Snapshot of all relevant data at time of scan
- Allows viewing results even if products/recommendations change later

#### 4. face_captures
```sql
CREATE TABLE face_captures (
  id                        UUID PRIMARY KEY,
  device_id                 VARCHAR(255),         -- Device identifier
  image_url                 VARCHAR(500),         -- Uploaded image URL
  storage_path              TEXT,                 -- Storage path in system
  is_consented_for_training BOOLEAN DEFAULT FALSE, -- GDPR/privacy consent
  created_at                TIMESTAMPTZ DEFAULT NOW()
);
```

**Purpose**:
- Store face images separately
- Enable data collection for ML training (with consent)
- Linked to classification_results via face_capture_id

#### 5. cbf_metadata
```sql
CREATE TABLE cbf_metadata (
  id       SERIAL PRIMARY KEY,
  key      VARCHAR(100) UNIQUE,              -- "tfidf_vocab", "idf_scores", etc.
  value    JSONB,                            -- Serialized data
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example: tfidf_vocab entry
{
  "key": "tfidf_vocab",
  "value": {
    "vocabulary": ["acne", "sebum", "oil", "dry", "sensitive", ...],
    "idf": [2.5, 2.3, 2.8, 1.9, 2.2, ...],
    "version": "1.0",
    "updated": "2026-06-20"
  }
}
```

**Purpose**:
- Store ML model metadata
- Vocabulary & IDF scores for TF-IDF vectorization
- Versioning for model updates

#### 6. history_scans (Legacy)
```sql
CREATE TABLE history_scans (
  id                      SERIAL PRIMARY KEY,
  user_id                 INTEGER REFERENCES users(id),
  skin_type               VARCHAR(50),
  cnn_confidence          FLOAT,
  concerns                JSONB,
  image_url               VARCHAR(500),
  recommendations_snapshot JSONB,
  created_at              TIMESTAMPTZ DEFAULT NOW()
);
```

**Status**: Currently using `classification_results` instead. This table may be deprecated.

---

## Data Flow & User Journeys

### Journey 1: New User Registration & Skin Analysis

```
┌─ USER (Flutter App)
│
├─ [1] Tap "Sign Up"
│       ↓
│       POST /auth/register
│       {full_name, email, password}
│       ↓ (FastAPI validates, hashes password)
│       ↑ Returns JWT token + user data
│       └─ Token stored in SharedPreferences
│
├─ [2] Navigate to Home
│       └─ Dashboard loaded
│
├─ [3] Tap "Scan Skin"
│       ↓
│       Navigate to SkinSymptomsScreen
│       └─ Display symptom checklist
│
├─ [4] Select symptoms (e.g., acne, oiliness)
│       └─ Stored in local state
│
├─ [5] Tap "Take Photo" or "Gallery"
│       ↓
│       Camera/Image picker → crop/confirm
│       └─ Image buffer stored in memory
│
├─ [6] Tap "Analyze"
│       ↓
│       POST /classify/
│       {
│         photo: <binary image>,
│         concerns: ["acne", "oiliness"]
│       }
│       Header: Authorization: Bearer {token}
│
│ ┌─ BACKEND (FastAPI)
│ │
│ ├─ [6a] Receive multipart image
│ │        └─ Save to uploads/photos/scans/
│ │
│ ├─ [6b] Run CNN inference
│ │        └─ Load model, preprocess, forward pass
│ │           Result: (skin_type, confidence, all_scores)
│ │
│ ├─ [6c] Get CBF recommendations
│ │        └─ Query CBF with (skin_type, concerns)
│ │           Result: products by category
│ │
│ ├─ [6d] Save to history
│ │        ├─ Create face_capture entry (if consented)
│ │        └─ Create classification_results entry
│ │
│ └─ [6e] Return response
│         └─ {skin_type, confidence, all_scores, image_url, history_id}
│
├─ [7] Receive response
│       └─ Navigate to ResultScreen
│
├─ [8] Display results
│       ├─ Detected skin type + confidence
│       ├─ Probability distribution graph
│       └─ Selected symptoms
│
├─ [9] Tap "Get Recommendations"
│       ↓
│       Navigate to RecommendationScreen
│       └─ Display products by category
│
├─ [10] View product details
│        └─ Tap product → open external link or show modal
│
└─ [11] Tap "View History" or "New Scan"
        ├─ History: Navigate to HistoryScreen
        └─ New Scan: Loop back to step [3]
```

### Journey 2: View Scan History

```
USER (Flutter App)
│
├─ [1] Navigate to HistoryScreen
│
├─ [2] Load history (on mount)
│       ↓
│       GET /history/{user_id}?limit=20&offset=0
│
│ ┌─ BACKEND
│ │ ├─ Query classification_results table
│ │ ├─ Order by created_at DESC
│ │ └─ Return JSON array
│
├─ [3] Display paginated list
│       ├─ Scan date, skin type, confidence
│       └─ Thumbnail of image
│
├─ [4] Tap item
│       ├─ If local cached: display cached
│       └─ If not: GET /history/{user_id}/{scan_id}
│
├─ [5] Display ResultScreen (from history)
│       └─ Show all details from snapshot
│
├─ [6] Delete single item (optional)
│       ↓
│       DELETE /history/{user_id}/{scan_id}
│
│ ┌─ BACKEND
│ │ └─ Delete classification_results row
│
├─ [7] Update UI (remove from list)
│
├─ [8] Delete all history (optional)
│       ↓
│       DELETE /history/{user_id}
│
│ ┌─ BACKEND
│ │ └─ Delete all rows for user_id
│
└─ [9] Confirm + update UI
```

### Journey 3: Guest Classification (No Login)

```
USER
│
├─ [1] Tap "Try as Guest" on splash screen
│
├─ [2] Navigate directly to SkinSymptomsScreen
│
├─ [3] Select symptoms, take/select photo
│
├─ [4] Tap "Analyze"
│       ↓
│       POST /classify/guest
│       {photo: <binary image>}
│       └─ No Authorization header needed
│
│ ┌─ BACKEND
│ │ ├─ Run CNN inference
│ │ ├─ Get recommendations
│ │ └─ Save to guest uploads (no history saved)
│
├─ [5] Display results
│
├─ [6] Tap "Sign Up to Save Results"
│       └─ Navigate to SignupScreen
│           └─ After signup, loop to authenticated journey
│
└─ [7] Or exit without saving
```

---

## API Endpoints Reference

### Complete Endpoint List

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/auth/register` | ❌ | Register new user |
| POST | `/auth/login` | ❌ | User login |
| GET | `/auth/me` | ✅ | Get current user profile |
| POST | `/auth/change-password` | ✅ | Change user password |
| POST | `/classify/` | ✅ | Classify skin + save history |
| POST | `/classify/guest` | ❌ | Classify skin (no save) |
| POST | `/recommendations/` | ✅ | Get recommendations |
| POST | `/recommendations/guest` | ❌ | Get recommendations (guest) |
| GET | `/recommendations/db-test` | ❌ | Test database connection |
| POST | `/history/` | ✅ | Create history entry |
| GET | `/history/{user_id}` | ✅ | Get user history (paginated) |
| GET | `/history/{user_id}/{scan_id}` | ✅ | Get specific history |
| DELETE | `/history/{user_id}/{scan_id}` | ✅ | Delete one history |
| DELETE | `/history/{user_id}` | ✅ | Delete all history |
| GET | `/health` | ❌ | Health check |
| GET | `/` | ❌ | Root/info endpoint |

### Request/Response Examples

See API Endpoints section above for detailed examples.

---

## Authentication & Security

### JWT Token Flow

**1. Login/Register**:
```
User credentials → POST /auth/register or /auth/login
                 ↓
Backend validates → hash password (bcrypt)
                 ↓
User found/created → success
                 ↓
Backend creates JWT:
{
  "sub": "user-uuid",
  "exp": 1700000000,  (timestamp + 86400 minutes)
  "iat": 1600000000   (issued at)
}
Signed with SECRET_KEY (HS256)
                 ↓
Return to client: {access_token, user_data}
```

**2. Subsequent Requests**:
```
Client includes: Authorization: Bearer {access_token}
                 ↓
Backend validates:
  - Verify signature (SECRET_KEY)
  - Check expiration
  - Extract user_id from "sub"
                 ↓
If valid → proceed (inject current_user)
If invalid → 401 Unauthorized
```

### Password Security

**Registration**:
```
Plain password from user
       ↓
Validate length/complexity (in request schema)
       ↓
Passlib bcrypt hashing:
  - Generate salt (random)
  - Hash with 12 rounds
  - Result: $2b$12$...(60 chars)
       ↓
Store in users.hashed_password
```

**Login**:
```
User provides password
       ↓
Fetch user by email
       ↓
Compare with bcrypt.verify(plain, hash)
       ↓
Constant-time comparison (prevents timing attacks)
       ↓
Success/Failure
```

**Change Password**:
```
User provides: current_password, new_password
       ↓
Verify current password (like login)
       ↓
Hash new password
       ↓
Update users.hashed_password
```

### CORS Configuration

**Current**: Allow all origins (`allow_origins=["*"]`)

```python
# In main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # ⚠️ Permissive for development
    allow_credentials=True,      # Allow cookies/auth headers
    allow_methods=["*"],         # All HTTP methods
    allow_headers=["*"],         # All headers
)
```

**Production Recommendation**:
```python
allow_origins=[
    "https://your-frontend-domain.com",
    "https://www.your-frontend-domain.com",
]
```

### File Upload Security

**Validation** (in `utils/file_utils.py`):
- File size check: Max 5MB (configurable in .env)
- Content-type validation: Only images (jpg, png, webp)
- Re-encode on save (prevent malicious files)

**Storage**:
- Save to `uploads/photos/{subfolder}/`
- Filename: timestamp-based (prevents collision)
- Served via HTTP (implement access control if needed)

---

## Configuration & Deployment

### Environment Variables (.env)

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_public_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# App
APP_NAME=Jelita Skincare API
APP_VERSION=1.0.0
DEBUG=True

# Database (optional, for legacy PostgreSQL)
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/jelita

# JWT
SECRET_KEY=<generate 256-bit hex string>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=86400

# File Upload
UPLOAD_DIR=uploads/photos
MAX_FILE_SIZE_MB=5

# ML Models
CNN_MODEL_PATH=assets/models/cnn/mobilenetv3_skintype_90.ptl
CBF_MODEL_PATH=jelita_backend/assets/models/cbf/cbf_model_22june.jotlib

# SMTP (for password reset email - not yet implemented)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@jelita.com
SMTP_FROM_NAME=Jelita Skincare

# CORS
ALLOWED_ORIGINS=http://localhost,http://10.0.2.2
```

### Backend Setup Steps

**1. Clone Repository**
```bash
git clone <repository>
cd jelita_backend
```

**2. Create Virtual Environment**
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Mac/Linux
python -m venv venv
source venv/bin/activate
```

**3. Install Dependencies**
```bash
pip install -r requirements.txt
```

**4. Configure .env**
```bash
cp .env.example .env
# Edit .env with your Supabase credentials & settings
```

**5. Run Backend**
```bash
# Using run.sh
bash run.sh

# Or directly
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**Server Startup**:
- Loads CNN model into memory
- Loads CBF metadata & vocabulary from Supabase
- Builds product cache
- Prints diagnostic info
- Listens on http://0.0.0.0:8000

### Flutter Setup Steps

**1. Install Flutter SDK**
- Download from https://flutter.dev/docs/get-started/install

**2. Clone Repository**
```bash
git clone <repository>
cd skripsi-jelita
```

**3. Get Dependencies**
```bash
flutter pub get
```

**4. Configure API Constants**
```dart
// lib/src/constant/api_constant.dart
class ApiConstants {
  static const String BASE_URL = "http://your-backend:8000/api/v1";
  // ...
}
```

**5. Run on Emulator/Device**
```bash
# List connected devices
flutter devices

# Run
flutter run

# Or specify device
flutter run -d <device-id>
```

### Docker Deployment (Optional)

**Backend Dockerfile** (proposed):
```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Build & Run**:
```bash
docker build -t jelita-backend .
docker run -p 8000:8000 --env-file .env jelita-backend
```

---

## Error Handling & Logging

### Backend Error Handling

**Global Exception Handler** (in main.py):
```python
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),
            "detail": traceback.format_exc(),
        }
    )
```

**HTTP Exceptions**:
```python
# 400 Bad Request
HTTPException(status_code=400, detail="Invalid input")

# 401 Unauthorized
HTTPException(status_code=401, detail="Invalid credentials")

# 404 Not Found
HTTPException(status_code=404, detail="Resource not found")

# 500 Server Error
HTTPException(status_code=500, detail="Server error")
```

**Specific Errors**:

| Scenario | Status | Message |
|----------|--------|---------|
| Missing JWT token | 403 | Unauthorized |
| Invalid JWT | 401 | Invalid credentials |
| Expired JWT | 401 | Token expired |
| Email already registered | 400 | Email sudah terdaftar |
| Wrong password | 401 | Email atau password salah |
| File too large | 413 | File size exceeds limit |
| Invalid image format | 415 | Unsupported media type |
| No file uploaded | 400 | No file part |
| History not found | 404 | History tidak ditemukan |
| Database error | 500 | Error {operation}: {detail} |

### Logging Strategy

**Current**:
- Print statements to console for development
- Startup events logged: CNN load, CBF load, product cache load
- Error tracebacks printed to stdout

**Recommended Production Setup**:
```python
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# File handler
fh = logging.FileHandler('app.log')
fh.setLevel(logging.INFO)

# Formatter
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
fh.setFormatter(formatter)

logger.addHandler(fh)

# Usage
logger.info("CNN model loaded")
logger.error(f"Failed to load model: {exc}", exc_info=True)
```

---

## Third-Party Integrations

### 1. Supabase (Database & Auth)

**Purpose**:
- PostgreSQL database hosting
- User authentication (JWT tokens)
- File storage (for images)
- Real-time capabilities (optional)

**Endpoints Used**:
- `table().select().execute()` - Query data
- `table().insert().execute()` - Insert records
- `table().update().execute()` - Update records
- `table().delete().execute()` - Delete records

**Configuration**:
```python
from supabase import create_client

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

supabase_admin = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # For admin operations
)
```

### 2. PyTorch (ML Framework)

**Purpose**:
- CNN model loading & inference
- Tensor operations

**Usage**:
```python
import torch
from torchvision import models, transforms

# Load model
model = torch.jit.load("model.ptl")
model.eval()

# Inference
with torch.no_grad():
    output = model(tensor)
    probs = torch.softmax(output, dim=1)
```

### 3. scikit-learn (ML Utilities)

**Purpose**:
- Cosine similarity calculation
- TF-IDF support

**Usage**:
```python
from sklearn.metrics.pairwise import cosine_similarity

similarity = cosine_similarity([query_vec], [product_vec])
```

### 4. Device Preview (Flutter)

**Purpose**:
- Multi-device preview during development
- Test responsive UI

**Configuration**:
```dart
DevicePreview(
    enabled: true,  // Set to false in production
    builder: (context) => const MyApp(),
)
```

### 5. Image Picker (Flutter)

**Purpose**:
- Camera access for photo capture
- Gallery access for image selection

**Usage**:
```dart
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.camera);
```

---

## Future Enhancements & Roadmap

### Phase 2 (Recommended)
- [ ] Password reset via email (SMTP configured)
- [ ] Push notifications for product launches
- [ ] Social sharing (scan results)
- [ ] Favorite products list
- [ ] Product comparison tool
- [ ] Skin routine recommendations
- [ ] Real-time notifications
- [ ] Dark mode UI
- [ ] Multi-language support

### Phase 3
- [ ] Advanced ML:
  - Facial feature detection (acne locations)
  - Skin texture analysis
  - Age estimation
  - Personalized ingredient preferences
- [ ] Loyalty program
- [ ] E-commerce integration
- [ ] Dermatologist consultation booking
- [ ] Community forums

### Technical Debt
- [ ] Add comprehensive logging
- [ ] Implement caching (Redis)
- [ ] Add rate limiting on API endpoints
- [ ] Database query optimization
- [ ] Add unit & integration tests
- [ ] API documentation (OpenAPI/Swagger)
- [ ] CI/CD pipeline setup
- [ ] Performance monitoring
- [ ] Security audit

---

## Troubleshooting & Common Issues

### Backend Issues

**Issue**: CNN model not loading
- **Cause**: Model file path incorrect or file corrupted
- **Solution**: 
  - Check `CNN_MODEL_PATH` in .env
  - Verify file exists and is readable
  - Check file size (should be ~10-50MB)
  - Fallback: uses untrained model (logs warning)

**Issue**: CBF metadata not loading
- **Cause**: cbf_metadata table empty or metadata malformed
- **Solution**:
  - Verify Supabase `cbf_metadata` table exists
  - Check `tfidf_vocab` entry format
  - Rebuild vocabulary using training pipeline

**Issue**: Slow recommendations
- **Cause**: Large product cache, slow Supabase connection
- **Solution**:
  - Filter inactive products (is_active=True)
  - Add pagination to recommendations
  - Consider caching with Redis

### Frontend Issues

**Issue**: Image upload fails
- **Cause**: File too large, invalid format, network error
- **Solution**:
  - Check file size (< 5MB)
  - Use JPG or PNG format
  - Verify backend is running
  - Check CORS headers

**Issue**: JWT token expired
- **Cause**: Token older than 86400 minutes
- **Solution**:
  - Implement token refresh endpoint (recommended)
  - User needs to log in again
  - Store token with expiration info

**Issue**: Classification always shows same skin type
- **Cause**: Model untrained or not loaded correctly
- **Solution**:
  - Train CNN model on diverse dataset
  - Verify model file integrity
  - Test with various face images

---

## Appendix: Key Files Reference

### Frontend Key Files
- **Entry Point**: `lib/main.dart`
- **Routes**: `lib/routes/app_routes.dart`
- **Models**: `lib/data/models/*.dart`
- **Repositories**: `lib/data/repositories/*.dart`
- **Screens**: `lib/features/*/`
- **Constants**: `lib/src/constant/*.dart`

### Backend Key Files
- **Entry Point**: `jelita_backend/app/main.py`
- **API Endpoints**: `jelita_backend/app/api/v1/endpoints/`
- **Services**: `jelita_backend/app/services/`
- **Schemas**: `jelita_backend/app/schemas/`
- **Security**: `jelita_backend/app/core/security.py`
- **Database**: `jelita_backend/app/db/database.py`
- **Config**: `jelita_backend/app/core/config.py`

### Configuration Files
- **Flutter**: `pubspec.yaml`, `analysis_options.yaml`
- **Backend**: `requirements.txt`, `.env.example`
- **Database**: `jelita_backend/database/setup.sql`

---

## Document Maintenance

**Last Updated**: June 25, 2026  
**Next Review**: September 2026  
**Maintained By**: Development Team  

### Version History
- **v1.0.0** (June 2026): Initial comprehensive specification document
  - Complete system architecture documentation
  - All API endpoints documented
  - ML services explained in detail
  - Database schema fully documented
  - User journeys and data flows illustrated

---

## Contact & Support

For system-related questions or issues:
- **Backend Issues**: Check `jelita_backend/README.md`
- **Frontend Issues**: Check Flutter documentation and pubspec.yaml
- **ML Model Issues**: Verify model files and check cnn_service.py / cbf_service.py
- **Database Issues**: Check Supabase dashboard

---

**END OF DOCUMENT**

---

*This document serves as a complete handover guide. All logic, features, definitions, and system specifications are documented here to enable seamless transition to another developer or team.*
