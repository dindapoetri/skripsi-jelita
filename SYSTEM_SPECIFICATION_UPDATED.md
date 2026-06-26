# JELITA Skincare System - Specification & Developer Handover

**Version:** 2.0 (Concise + Implementation Details)  
**Updated:** June 26, 2026  
**For:** New developers taking over the project

---

## 🎯 EXECUTIVE SUMMARY

**Jelita** is an AI-powered skincare recommendation app that:
- **Classifies skin type** from facial photos using CNN (MobileNetV3) → 5 types: oily, dry, normal, combination, acne
- **Recommends products** based on skin type + user concerns via Content-Based Filtering (CBF) with TF-IDF
- **Saves user history** for tracking previous scans and results
- **Works offline** (CNN runs on-device via PyTorch Lite in Flutter)

**Tech Stack:**
- **Frontend:** Flutter (Dart) - Mobile app (iOS/Android)
- **Backend:** FastAPI (Python) - REST API
- **Database:** Supabase (PostgreSQL)
- **ML:** PyTorch (CNN) + scikit-learn (CBF)

**Key Repositories:**
- Frontend code: `lib/` (Dart)
- Backend code: `jelita_backend/app/` (Python)
- Models: `assets/models/` (CNN .ptl, CBF .jotlib)

---

## 📊 QUICK REFERENCE

### System Flow (One-Page Overview)

```
USER (Flutter App)
    ↓ [Select symptoms + take photo]
    ↓
POST /classify/ (with image + concerns)
    ↓ (Backend)
    ├─→ CNN inference (predict skin type)
    ├─→ CBF search (find matching products)
    ├─→ Save to database
    └─→ Return results
    ↓
Display results + recommendations to user
    ↓
Save to history automatically
```

### Key Technologies & Versions

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Mobile | Flutter | 3.10.7+ | Cross-platform app |
| Backend | FastAPI | 0.111.0 | REST API server |
| ML (Classification) | PyTorch | 2.3.0 | Skin type CNN |
| ML (Recommendations) | scikit-learn | 1.4.2 | TF-IDF similarity |
| Database | Supabase/PostgreSQL | Latest | Cloud database |
| Python Runtime | Python | 3.10.7+ | Backend runtime |
| Dart/Flutter Runtime | Dart | 3.10.7+ | Mobile runtime |

### All API Endpoints

| Method | Endpoint | Auth | What it does |
|--------|----------|------|-------------|
| POST | `/auth/register` | ❌ | Create account |
| POST | `/auth/login` | ❌ | Get JWT token |
| GET | `/auth/me` | ✅ | Get user profile |
| POST | `/auth/change-password` | ✅ | Update password |
| POST | `/classify/` | ✅ | Classify skin + save |
| POST | `/classify/guest` | ❌ | Classify without saving |
| POST | `/recommendations/` | ✅ | Get product recommendations |
| POST | `/recommendations/guest` | ❌ | Guest recommendations |
| POST | `/history/` | ✅ | Create history entry |
| GET | `/history/{user_id}` | ✅ | Get user's scan history (paginated) |
| GET | `/history/{user_id}/{scan_id}` | ✅ | Get specific scan details |
| DELETE | `/history/{user_id}/{scan_id}` | ✅ | Delete one scan |
| DELETE | `/history/{user_id}` | ✅ | Delete all history |
| GET | `/health` | ❌ | Health check |
| GET | `/` | ❌ | API info |

### Database Tables

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `users` | User accounts | id, email, hashed_password, full_name |
| `products` | Skincare products | id, name, brand, category, skin_types, tfidf_vector |
| `classification_results` | Scan history | id, user_id, skin_type, confidence_score, created_at |
| `face_captures` | Uploaded photos | id, image_url, storage_path, is_consented_for_training |
| `cbf_metadata` | ML vocab/IDF | key (tfidf_vocab), value (JSON) |

---

## 🔧 IMPLEMENTATION DETAILS

### 1. Frontend (Flutter) - Core Implementation

#### Project Structure
```
lib/
├── main.dart                    # App entry + Supabase init
├── features/
│   ├── splash/                  # Startup & auth check
│   ├── authentication/          # Login/signup screens
│   ├── home/                    # Dashboard
│   ├── symptoms/                # Concern selection + camera
│   ├── result/                  # Display CNN results
│   ├── recommendation/          # Show products
│   └── history/                 # View past scans
├── data/
│   ├── models/                  # Data classes (product, skin_result)
│   └── repositories/            # API calls
├── routes/app_routes.dart       # Navigation
└── src/constant/                # Config, themes, strings
```

#### Key Models

**ProductModel** (lib/data/models/product_model.dart):
```dart
class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;           // facial_wash, toner, moisturizer, sunscreen
  final List<String> suitableSkinTypes;
  final List<String> concerns;     // Ingredients/keywords
  final String? imageUrl;
}
```

**SkinResultModel** (lib/data/models/skin_result_models.dart):
```dart
class SkinResultModel {
  final String skinType;           // oily, dry, normal, combination, acne
  final double confidence;         // 0.0 - 1.0
  final Map<String, double> probabilities;  // All 5 types with scores
  final List<String> concerns;     // User-selected symptoms
  final String imagePath;
  final DateTime createdAt;
}
```

#### User Flow Implementation

```dart
// 1. Splash Screen checks auth
if (token exists & valid) → Home Screen
else → Login Screen

// 2. After login → Home Screen with quick-start buttons
[Scan Skin] button → SkinSymptomsScreen

// 3. Symptoms Screen
- Show checklist: acne, dryness, oiliness, sensitivity, etc.
- Multi-select allowed
- Camera/Gallery picker
→ Send to backend

// 4. Receive results → ResultScreen
- Display detected skin type + confidence
- Show probability bars (all 5 types)
- Show selected concerns
[Get Recommendations] button

// 5. RecommendationScreen
- Group products by: facial_wash, toner, moisturizer, sunscreen
- Show match score for each product
- Tap product → open link or details

// 6. HistoryScreen
- Paginated list of past scans (20 per page)
- Tap item → view full results
- Swipe to delete individual scan
- Delete all option
```

#### Repository Layer Example (skin_repositories.dart)
```dart
class SkinRepository {
  // Classify skin for authenticated user
  Future<SkinResultModel> classifyImage(
    File imageFile,
    List<String> concerns,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.BASE_URL}/classify/'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['concerns'] = jsonEncode(concerns);
    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      imageFile.path,
    ));

    final response = await request.send();
    // Parse CNNPredictResponse with skin_type, confidence, all_scores
    return SkinResultModel.fromMap(jsonDecode(response.body));
  }

  // Guest classification (no auth)
  Future<SkinResultModel> classifyImageGuest(File imageFile) async {
    // Same as above but POST to /classify/guest
  }
}
```

---

### 2. Backend (FastAPI) - Core Implementation

#### Project Structure
```
jelita_backend/app/
├── main.py                       # FastAPI init + lifespan events
├── api/v1/
│   ├── endpoints/
│   │   ├── auth.py               # Register, login, profile
│   │   ├── classify.py           # CNN + recommendations
│   │   ├── history.py            # Scan history CRUD
│   │   └── recommendations.py    # CBF recommendations
│   └── router.py                 # Route aggregator
├── services/
│   ├── cnn_service.py            # CNN inference
│   ├── cbf_service.py            # CBF recommendations logic
│   ├── user_service.py           # User CRUD
│   └── history_service.py        # History management
├── schemas/                      # Pydantic request/response models
├── core/
│   ├── config.py                 # .env configuration
│   └── security.py               # JWT + password hashing
├── db/database.py                # Supabase connection
└── utils/file_utils.py           # File upload handling
```

#### Actual Code: Classification Endpoint (classify.py)

```python
@router.post("/", response_model=CNNPredictResponse)
async def classify_and_save(
    photo: UploadFile = File(...),
    concerns: str = Form(default="[]"),
    current_user: dict = Depends(get_current_user),
):
    # 1. Save image
    image_url, image_bytes = await save_upload_photo(photo, subfolder="scans")

    # 2. Run CNN
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    # 3. Parse concerns
    try:
        concerns_list = json.loads(concerns)
    except:
        concerns_list = []

    # 4. Get recommendations
    recs = await get_recommendations(
        skin_type=skin_type,
        concerns=concerns_list,
        top_n=5,
    )

    # 5. Save to database
    history = await create_history_scan(
        user_id=current_user["id"],
        data={
            "skin_type": skin_type,
            "cnn_confidence": confidence,
            "concerns": concerns_list,
            "image_url": image_url,
            "recommendations_snapshot": [...],
        }
    )

    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
        image_url=image_url,
        history_id=history.get("id"),
    )

@router.post("/guest", response_model=CNNPredictResponse)
async def classify_guest(photo: UploadFile = File(...)):
    # Same as above but NO history save
    _, image_bytes = await save_upload_photo(photo, subfolder="guest")
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)
    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
    )
```

#### Actual Code: CNN Service (cnn_service.py)

```python
import torch
from torchvision import transforms, models
from PIL import Image
import numpy as np

# Skin type labels
SKIN_LABELS = {
    0: "oily",
    1: "dry",
    2: "normal",
    3: "combination",
    4: "acne",
}

# Image preprocessing (same as Flutter training)
TRANSFORM = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    ),
])

_model = None

def load_cnn_model():
    """Load MobileNetV3 model from .ptl (TorchScript format)"""
    global _model
    model_path = settings.CNN_MODEL_PATH
    
    if not os.path.exists(model_path):
        raise RuntimeError(f"Model not found: {model_path}")
    
    try:
        _model = torch.jit.load(model_path, map_location="cpu")
        _model.eval()
        print(f"[CNN] Model loaded from {model_path}")
    except Exception as e:
        print(f"[CNN] Error: {e}")
        raise

def predict_skin_type(image_bytes: bytes) -> tuple[str, float, dict]:
    """
    Predict skin type from image bytes.
    
    Returns:
        skin_type: "oily" | "dry" | "normal" | "combination" | "acne"
        confidence: 0.0-1.0 (confidence of prediction)
        all_scores: {skin_type: score, ...} for all 5 types
    """
    global _model
    if _model is None:
        load_cnn_model()

    # Decode image
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    tensor = TRANSFORM(image).unsqueeze(0)  # [1, 3, 224, 224]

    # Inference
    with torch.no_grad():
        output = _model(tensor)
        probabilities = torch.softmax(output, dim=1).squeeze()

    # Get prediction
    probs = probabilities.numpy()
    pred_idx = int(np.argmax(probs))
    skin_type = SKIN_LABELS[pred_idx]
    confidence = float(probs[pred_idx])

    all_scores = {
        SKIN_LABELS[i]: float(probs[i])
        for i in range(len(SKIN_LABELS))
    }

    return skin_type, confidence, all_scores
```

#### Actual Code: CBF Service (cbf_service.py)

```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from app.db.database import supabase_admin

# Global cache (loaded at startup)
_product_cache = []
_product_matrix = None
_vocab = {}
_idf = None

async def load_metadata():
    """Load TF-IDF vocabulary from Supabase cbf_metadata table"""
    global _vocab, _idf
    
    res = supabase_admin.table("cbf_metadata") \
        .select("key, value") \
        .execute()
    
    for item in res.data:
        if item.get("key") == "tfidf_vocab":
            payload = json.loads(item.get("value"))
            vocab_list = payload.get("vocabulary", [])
            idf_list = payload.get("idf", [])
            
            _vocab = {token: idx for idx, token in enumerate(vocab_list)}
            _idf = np.array(idf_list, dtype=float)
            print(f"[CBF] Vocab loaded: {len(_vocab)} terms, {len(_idf)} IDF scores")

async def build_product_cache():
    """Load all products from Supabase into memory"""
    global _product_cache, _product_matrix
    
    PAGE_SIZE = 1000
    offset = 0
    all_products = []
    
    # Paginate through products
    while True:
        res = supabase_admin.table("products") \
            .select("id, product_name, brand, category, url, skin_types, tfidf_vector") \
            .eq("is_active", True) \
            .range(offset, offset + PAGE_SIZE - 1) \
            .execute()
        
        rows = res.data or []
        all_products.extend(rows)
        
        if len(rows) < PAGE_SIZE:
            break
        offset += PAGE_SIZE
    
    # Filter products with vectors
    _product_cache = [
        {
            "id": p["id"],
            "name": p.get("product_name", ""),
            "brand": p.get("brand", ""),
            "category": p.get("category", ""),
            "skin_types": p.get("skin_types") or [],
            "vector": p.get("tfidf_vector"),
        }
        for p in all_products
        if p.get("tfidf_vector")
    ]
    
    # Create matrix for fast similarity calculation
    _product_matrix = np.array(
        [p["vector"] for p in _product_cache],
        dtype=float
    )
    print(f"[CBF] Loaded {len(_product_cache)} products")

def _build_query_vector(skin_type: str, concerns: List[str]) -> np.ndarray:
    """Convert skin type + concerns to TF-IDF vector"""
    if not _vocab or _idf is None:
        raise RuntimeError("CBF metadata not loaded")
    
    # Map skin type to descriptive terms
    skin_map = {
        "normal": "normal balanced skin",
        "oily": "oily acne sebum oil",
        "dry": "dry dehydrated moisture",
        "combination": "combination mixed skin",
        "acne": "acne breakout pimple",
    }
    
    # Combine skin type + concerns into query text
    query_text = f"{skin_map.get(skin_type, skin_type)} {' '.join(concerns)}".lower()
    
    # Create TF-IDF vector
    vec = np.zeros(len(_vocab), dtype=float)
    for token in query_text.split():
        if token in _vocab:
            vec[_vocab[token]] += 1.0
    
    vec = vec * _idf  # Multiply by IDF scores
    
    # Normalize
    norm = np.linalg.norm(vec)
    if norm > 0:
        vec = vec / norm
    
    return vec

async def get_recommendations(
    skin_type: str,
    concerns: List[str],
    top_n: int = 5,
) -> RecommendationResponse:
    """Get recommended products using cosine similarity"""
    
    query_vec = _build_query_vector(skin_type, concerns)
    
    # Calculate similarity with all products
    similarities = cosine_similarity([query_vec], _product_matrix)[0]
    
    # Get top products per category
    recommendations = {
        "facial_wash": [],
        "toner": [],
        "moisturizer": [],
        "sunscreen": [],
    }
    
    for idx in np.argsort(-similarities):  # Sort by descending similarity
        product = _product_cache[idx]
        category = product["category"]
        
        # Only add if category exists and product is suitable for skin type
        if category in recommendations:
            if skin_type in product["skin_types"]:
                recommendations[category].append({
                    "id": product["id"],
                    "name": product["name"],
                    "brand": product["brand"],
                    "score": float(similarities[idx]),
                })
            
            # Stop if we have enough for this category
            if len(recommendations[category]) >= top_n:
                pass
    
    return RecommendationResponse(**recommendations)
```

#### Authentication Implementation (security.py)

```python
from passlib.context import CryptContext
from python_jose import JWTError, jwt
from datetime import datetime, timedelta
from app.core.config import settings

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash password with bcrypt (12 rounds)"""
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    """Verify plain password against bcrypt hash (constant-time)"""
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict) -> str:
    """Create JWT token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """Validate JWT and return current user"""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user = await get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user
```

---

### 3. Database Schema (Supabase)

#### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email);
```

#### Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name VARCHAR(255) NOT NULL,
  brand VARCHAR(150),
  category VARCHAR(50),  -- facial_wash, toner, moisturizer, sunscreen
  description TEXT,
  description_clean TEXT,
  how_to_use TEXT,
  suitable_for TEXT,
  ingredients TEXT,
  image_url VARCHAR(500),
  url VARCHAR(500),
  skin_types JSONB,  -- ["oily", "normal"]
  concerns JSONB,    -- ["acne", "sebum"]
  tfidf_vector FLOAT8[],  -- Pre-computed TF-IDF vector
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(is_active);
```

#### Classification Results Table
```sql
CREATE TABLE classification_results (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  skin_type VARCHAR(50) NOT NULL,
  confidence_score FLOAT,
  detected_symptoms JSONB DEFAULT '[]',
  concerns JSONB DEFAULT '[]',
  description TEXT,
  probabilities JSONB,  -- {"oily": 0.92, "dry": 0.05, ...}
  recommendations JSONB,
  ideal_ingredients JSONB,
  face_capture_id UUID REFERENCES face_captures(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_class_user_id ON classification_results(user_id);
CREATE INDEX idx_class_created ON classification_results(created_at DESC);
```

#### Face Captures Table
```sql
CREATE TABLE face_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(255),
  image_url VARCHAR(500),
  storage_path TEXT,
  is_consented_for_training BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### CBF Metadata Table
```sql
CREATE TABLE cbf_metadata (
  id SERIAL PRIMARY KEY,
  key VARCHAR(100) UNIQUE,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example: Insert TF-IDF vocabulary
INSERT INTO cbf_metadata (key, value) VALUES (
  'tfidf_vocab',
  '{
    "vocabulary": ["acne", "sebum", "oil", "dry", "sensitive", ...],
    "idf": [2.5, 2.3, 2.8, 1.9, 2.2, ...],
    "version": "1.0"
  }'
);
```

---

### 4. ML Implementation Details

#### CNN Skin Classification Pipeline

**Preprocessing:**
```
Input Image (any size, format)
    ↓
Decode to RGB (PIL)
    ↓
Resize to 224×224 pixels
    ↓
Convert to tensor: [1, 3, 224, 224]
    ↓
Normalize: (pixel - mean) / std
  mean = [0.485, 0.456, 0.406]
  std = [0.229, 0.224, 0.225]
    ↓
Model forward pass
```

**Model:**
- Architecture: MobileNetV3-Small (efficient, 2.1M parameters)
- Input: 224×224×3 RGB image
- Output: 5 logits (one per skin type)
- Classes:
  - 0: oily (Kulit Berminyak)
  - 1: dry (Kulit Kering)
  - 2: normal (Kulit Normal)
  - 3: combination (Kulit Kombinasi)
  - 4: acne (Kulit Berjerawat)

**Inference:**
```python
logits = model(tensor)                    # [1, 5]
probabilities = softmax(logits, dim=1)   # [1, 5] sum=1.0
confidence = max(probabilities)          # scalar 0.0-1.0
skin_type = argmax(probabilities)        # 0-4
```

**Model File:**
- Format: TorchScript (.ptl) - serialized Python model
- Location: `assets/models/cnn/mobilenetv3_skintype_90.ptl`
- Name "90" = ~90% accuracy on test set
- Size: ~10-15 MB

#### CBF Recommendations Algorithm

**TF-IDF Vectorization:**
```
Query = {skin_type, concerns}

Step 1: Map to text
  "oily" + ["acne", "sebum"] 
  → "oily acne sebum oil acne breakout"

Step 2: Tokenize
  tokens = ["oily", "acne", "sebum", "oil", "breakout", ...]

Step 3: Term frequency (TF)
  For each token:
    vec[vocab_index[token]] += count

Step 4: Multiply by IDF
  vec *= idf_scores

Step 5: Normalize (L2)
  vec = vec / ||vec||
```

**Recommendation Scoring:**
```
similarity(query, product) = dot(query_vec, product_vec)
                           = cosine similarity [0.0, 1.0]

Top_N = Sort products by similarity (descending)
        Filter by skin_type compatibility
        Group by category
        Return top_n per category
```

**Example:**
```
Query: skin_type="oily", concerns=["acne"]
Generated text: "oily acne sebum oil acne breakout"

Products in database (pre-computed vectors):
  Product A (facial wash): similarity = 0.87 ✓
  Product B (moisturizer): similarity = 0.45 ✗ (not for oily)
  Product C (toner): similarity = 0.76 ✓

Result: 
  facial_wash: [Product A with score 0.87]
  toner: [Product C with score 0.76]
```

---

## 📱 FRONTEND IMPLEMENTATION WALKTHROUGH

### Screen: Symptoms Selection (`features/symptoms/skin_symptoms_screen.dart`)

**UI Flow:**
```
┌─────────────────────────────────┐
│ Select Your Skin Concerns       │
├─────────────────────────────────┤
│                                 │
│ ☐ Acne & Breakouts             │
│ ☐ Dryness & Dehydration        │
│ ☐ Excess Oil & Sebum           │
│ ☐ Sensitivity & Redness        │
│ ☐ Dark Spots & Hyperpigmentation│
│ ☐ Wrinkles & Aging             │
│                                 │
├─────────────────────────────────┤
│ [   TAKE PHOTO   ] [  GALLERY  ] │
└─────────────────────────────────┘
```

**Implementation:**
```dart
// State management for selected concerns
List<String> selectedConcerns = [];

// Checkbox listener
onChanged: (bool? value) {
  setState(() {
    if (value == true) {
      selectedConcerns.add(concern);
    } else {
      selectedConcerns.remove(concern);
    }
  });
}

// Camera button
onPressed: () async {
  final image = await ImagePicker().pickImage(source: ImageSource.camera);
  if (image != null) {
    // Send to classify endpoint
    _classifyImage(File(image.path), selectedConcerns);
  }
}
```

### Screen: Results Display (`features/result/result_screen.dart`)

**UI Flow:**
```
┌──────────────────────────────────────────┐
│ Your Skin Type Result                    │
├──────────────────────────────────────────┤
│                                          │
│ 🔍 Detected: Oily Skin                  │
│    Confidence: 92%                       │
│                                          │
│ Probability Distribution:                │
│ Oily         ███████████████░ 92%       │
│ Dry          ░░░░░░░░░░░░░░░░  2%       │
│ Normal       ░░░░░░░░░░░░░░░░  4%       │
│ Combination  ░░░░░░░░░░░░░░░░  1%       │
│ Acne         ░░░░░░░░░░░░░░░░  1%       │
│                                          │
│ Your Concerns:                           │
│ • Acne & Breakouts                      │
│ • Excess Oil & Sebum                    │
│                                          │
├──────────────────────────────────────────┤
│  [GET RECOMMENDATIONS]  [VIEW HISTORY]  │
└──────────────────────────────────────────┘
```

**Code:**
```dart
class ResultScreen extends StatelessWidget {
  final SkinResultModel result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      body: Column(
        children: [
          // Skin type card
          Card(
            child: Column(
              children: [
                Text(
                  'Detected: ${result.skinType.toUpperCase()}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Confidence: ${result.confidenceLabel}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          
          // Probability bars
          ...result.probabilities.entries.map((e) => 
            ProbabilityBar(
              label: e.key,
              value: e.value,
            ),
          ),
          
          // Concerns list
          Text('Your Concerns:'),
          ...result.concerns.map((c) => Text('• $c')),
          
          // Buttons
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/recommendation',
              arguments: {'result': result},
            ),
            child: Text('Get Recommendations'),
          ),
        ],
      ),
    );
  }
}
```

### Screen: Recommendations (`features/recommendation/recommendation_screen.dart`)

**UI Flow:**
```
┌──────────────────────────────────────────┐
│ Recommended Products for Oily Skin       │
├──────────────────────────────────────────┤
│ FACIAL WASH                              │
│ ┌──────────────────────────────────────┐ │
│ │ 🧴 Cleansing Foam                   │ │
│ │    Brand: ProductCare                │ │
│ │    Suitable: Oily, Acne-Prone       │ │
│ │    Match: 87% ✓                     │ │
│ │    [MORE DETAILS]                   │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ TONER                                    │
│ ┌──────────────────────────────────────┐ │
│ │ 🧪 Acne Control Toner               │ │
│ │    Brand: SkinCare+                  │ │
│ │    Suitable: Oily                    │ │
│ │    Match: 76% ✓                     │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ MOISTURIZER                              │
│ ┌──────────────────────────────────────┐ │
│ │ 💧 Lightweight Hydrator              │ │
│ │    Brand: AquaCare                   │ │
│ │    Suitable: Oily, Combination       │ │
│ │    Match: 72% ✓                     │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ SUNSCREEN                                │
│ ┌──────────────────────────────────────┐ │
│ │ ☀️ Oil-Control Sunscreen SPF50       │ │
│ │    Brand: SunGuard                   │ │
│ │    Suitable: Oily, Sensitive         │ │
│ │    Match: 68% ✓                     │ │
│ └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

---

## 🔌 BACKEND API USAGE EXAMPLES

### Example 1: Complete User Journey (Register → Classify → Get History)

**1. Register:**
```bash
POST /auth/register
Content-Type: application/json

{
  "full_name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123"
}

Response (201):
{
  "access_token": "eyJhbGc...",
  "user": {
    "id": "uuid-123",
    "full_name": "John Doe",
    "email": "john@example.com",
    "created_at": "2026-06-26T10:00:00Z"
  }
}
```

**2. Classify Skin:**
```bash
POST /classify/
Authorization: Bearer eyJhbGc...
Content-Type: multipart/form-data

photo: <binary image file>
concerns: ["acne", "oiliness"]

Response:
{
  "skin_type": "oily",
  "confidence": 0.92,
  "all_scores": {
    "oily": 0.92,
    "dry": 0.02,
    "normal": 0.04,
    "combination": 0.01,
    "acne": 0.01
  },
  "image_url": "uploads/photos/scans/20260626_1234567890.jpg",
  "history_id": 42
}
```

**3. Get Recommendations:**
```bash
POST /recommendations/
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{
  "skin_type": "oily",
  "concerns": ["acne", "oiliness"],
  "top_n": 5
}

Response:
{
  "skin_type": "oily",
  "concerns": ["acne", "oiliness"],
  "recommendations": {
    "facial_wash": [
      {
        "id": "prod-1",
        "name": "Acne Cleansing Foam",
        "brand": "BrandA",
        "category": "facial_wash",
        "score": 0.87
      }
    ],
    "toner": [...],
    "moisturizer": [...],
    "sunscreen": [...]
  }
}
```

**4. View History:**
```bash
GET /history/uuid-123?limit=20&offset=0
Authorization: Bearer eyJhbGc...

Response:
{
  "message": "success",
  "data": [
    {
      "id": 42,
      "user_id": "uuid-123",
      "skin_type": "oily",
      "cnn_confidence": 0.92,
      "concerns": ["acne", "oiliness"],
      "image_url": "uploads/photos/scans/...",
      "created_at": "2026-06-26T10:05:00Z"
    }
  ]
}
```

---

## ⚙️ SETUP & DEPLOYMENT

### Backend Setup (5 steps)

```bash
# 1. Clone & navigate
git clone <repo>
cd jelita_backend

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure .env
cp .env.example .env
# Edit .env with Supabase credentials

# 5. Run server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Server startup will:
# - Load CNN model into memory
# - Load CBF vocabulary from Supabase
# - Build product cache
# - Print diagnostics
# - Listen on http://localhost:8000
```

**Startup Output:**
```
==================================================
  Jelita Skincare API v1.0.0
==================================================
[ML] Loading CNN model...
[CNN] TorchScript model loaded from assets/models/cnn/mobilenetv3_skintype_90.ptl
[CBF] Loading metadata (vocab + idf)...
[CBF] metadata loaded: vocab=5000, idf=5000
[CBF] Building product cache dari Supabase...
[CBF] fetched page offset=0, rows=1000, total_so_far=1000
[CBF] products loaded: 856 (dari total 1000 baris ter-fetch)
[APP] Server siap 🚀
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Frontend Setup (5 steps)

```bash
# 1. Clone & navigate
git clone <repo>
cd skripsi-jelita

# 2. Get dependencies
flutter pub get

# 3. Configure API constants (lib/src/constant/api_constant.dart)
class ApiConstants {
  static const String BASE_URL = "http://your-backend:8000/api/v1";
}

# 4. Configure Supabase (lib/main.dart)
await Supabase.initialize(
  url: SupabaseConfig.url,
  anonKey: SupabaseConfig.anonKey,
);

# 5. Run app
flutter run
# Or specify device
flutter run -d <device-id>
```

### Environment Variables (.env)

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_public_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# JWT
SECRET_KEY=<generate 256-bit hex>
ACCESS_TOKEN_EXPIRE_MINUTES=86400  # ~60 days

# File Upload
UPLOAD_DIR=uploads/photos
MAX_FILE_SIZE_MB=5

# ML Models
CNN_MODEL_PATH=assets/models/cnn/mobilenetv3_skintype_90.ptl
CBF_MODEL_PATH=jelita_backend/assets/models/cbf/cbf_model_22june.jotlib

# Debug
DEBUG=True
APP_NAME=Jelita Skincare API
APP_VERSION=1.0.0
```

---

## 🐛 TROUBLESHOOTING

### Backend Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| CNN model not loading | File path wrong, corrupted | Check `CNN_MODEL_PATH` in .env; verify file exists |
| CBF recommendations slow | Large product cache | Filter inactive products; implement caching |
| Database connection error | Supabase credentials wrong | Check SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY |
| File upload fails | File too large, wrong format | Max 5MB; JPG/PNG only |
| JWT token invalid | Token expired or malformed | Re-login to get new token |

### Frontend Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Classification always same type | Model untrained | Train CNN on diverse data; verify model file |
| Camera permission denied | Permissions not granted | Add permissions in AndroidManifest.xml (Android) or Info.plist (iOS) |
| Image upload fails | Network error | Verify backend running; check CORS |
| History not showing | User_id mismatch | Ensure correct user token; check database |

---

## 🚀 KEY TAKEAWAYS FOR NEXT DEVELOPER

### What You MUST Know

1. **CNN Inference**: Happens in `cnn_service.py`. Input: image bytes → Output: skin_type, confidence, probabilities
2. **CBF Recommendations**: TF-IDF based in `cbf_service.py`. Query text is built from skin_type + concerns
3. **JWT Auth**: All protected endpoints need `Authorization: Bearer {token}` header
4. **Database**: Uses Supabase (PostgreSQL). Products pre-computed with TF-IDF vectors
5. **Flutter Models**: `SkinResultModel` holds results; `ProductModel` holds product data; `RecommendationModel` groups by category

### Code Entry Points

- **Mobile app starts**: `lib/main.dart` → `SplashScreen`
- **Backend starts**: `jelita_backend/app/main.py` → FastAPI lifespan events
- **Classification happens**: POST `/classify/` endpoint → runs CNN then CBF
- **Auth happens**: JWT in `core/security.py` → verified on every protected endpoint

### Common Tasks

- **Add new skin type**: Update `SKIN_LABELS` in `cnn_service.py` (need retraining)
- **Add new product**: Insert into Supabase `products` table with pre-computed `tfidf_vector`
- **Change CNN model**: Replace file at `CNN_MODEL_PATH` in .env
- **Update recommendations algorithm**: Modify `get_recommendations()` in `cbf_service.py`
- **Add new screen**: Create folder in `lib/features/`, define route in `app_routes.dart`

---

## 📚 File Quick Reference

### Frontend Key Files
| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, Supabase init |
| `lib/routes/app_routes.dart` | Navigation routing |
| `lib/data/models/*.dart` | Data structures |
| `lib/data/repositories/*.dart` | API calls |
| `lib/features/*/` | UI screens |
| `lib/src/constant/api_constant.dart` | Backend URL config |

### Backend Key Files
| File | Purpose |
|------|---------|
| `app/main.py` | FastAPI setup, lifespan |
| `app/api/v1/endpoints/*.py` | API routes |
| `app/services/cnn_service.py` | CNN inference |
| `app/services/cbf_service.py` | CBF recommendations |
| `app/core/security.py` | JWT, password hashing |
| `app/core/config.py` | Configuration from .env |

---

## 📞 Support & Questions

- **Architecture unclear?** See Flow Diagrams section
- **API endpoint behavior?** See API Endpoints table
- **Database schema?** See Database Schema section
- **ML algorithm?** See ML Implementation Details section
- **Deployment?** See Setup & Deployment section

---

**Document Version:** 2.0  
**Last Updated:** June 26, 2026  
**Status:** Ready for Developer Handover ✅

*This document provides everything needed to understand, maintain, and extend the Jelita system.*
