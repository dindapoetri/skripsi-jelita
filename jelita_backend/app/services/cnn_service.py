import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import numpy as np
from typing import Dict, Tuple
import io
import os
from app.core.config import settings

# Label mapping sesuai SkinRepository.skinLabels di Flutter
SKIN_LABELS = {
    0: "oily",
    1: "dry",
    2: "normal",
    3: "combination",
    4: "acne",
}

SKIN_LABELS_ID = {
    "oily": "Kulit Berminyak",
    "dry": "Kulit Kering",
    "normal": "Kulit Normal",
    "combination": "Kulit Kombinasi",
    "acne": "Kulit Berjerawat",
}

# Transform: sama persis dengan preprocessing di Flutter
TRANSFORM = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    ),
])

_model = None

def load_cnn_model():  # sourcery skip: remove-unreachable-code
    """Load model CNN dari file .ptl atau .pt"""
    global _model

    model_path = settings.CNN_MODEL_PATH

    if not os.path.exists(model_path):
        print(f"[CNN] WARNING: Model tidak ditemukan di {model_path}")
        print("[CNN] Menggunakan MobileNetV3 default (tanpa bobot skripsi)...")
        raise RuntimeError("Model CNN tidak ditemukan atau gagal load.")
        return

    try:
        # Coba load sebagai TorchScript (.ptl)
        _model = torch.jit.load(model_path, map_location="cpu")
        _model.eval()
        print(f"[CNN] TorchScript model loaded dari {model_path}")
    except Exception:
        try:
            # Fallback: load sebagai state_dict
            _model = _create_default_model()
            state_dict = torch.load(model_path, map_location="cpu")
            if "state_dict" in state_dict:
                state_dict = state_dict["state_dict"]
            _model.load_state_dict(state_dict)
            _model.eval()
            print(f"[CNN] State dict model loaded dari {model_path}")
        except Exception as e:
            print(f"[CNN] ERROR load model: {e}")
            _model = _create_default_model()


def _create_default_model() -> nn.Module:
    """Buat MobileNetV3-Small dengan output 5 kelas."""
    model = models.mobilenet_v3_small(weights=None)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, len(SKIN_LABELS))
    model.eval()
    return model

def predict_skin_type(image_bytes: bytes) -> Tuple[str, float, Dict[str, float]]:
    global _model

    if _model is None:
        load_cnn_model()

    # Decode image
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    tensor = TRANSFORM(image).unsqueeze(0)  # [1, 3, 224, 224]

    with torch.no_grad():
        output = _model(tensor)
        probabilities = torch.softmax(output, dim=1).squeeze()

    probs = probabilities.numpy()
    pred_idx = int(np.argmax(probs))
    skin_type = SKIN_LABELS[pred_idx]
    confidence = float(probs[pred_idx])

    all_scores = {
        SKIN_LABELS[i]: float(probs[i])
        for i in range(len(SKIN_LABELS))
    }

    return skin_type, confidence, all_scores
