import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import numpy as np
from typing import Dict, Tuple
import io
import os

from app.core.config import settings

# =====================================================
# LABEL MAPPING HARUS SAMA DENGAN HASIL TRAINING
#
# Class to Index:
# {
#   'acne': 0,
#   'combi': 1,
#   'dry': 2,
#   'normal': 3,
#   'oily': 4
# }
# =====================================================

SKIN_LABELS = {
    0: "acne",
    1: "combination",
    2: "dry",
    3: "normal",
    4: "oily",
}

SKIN_LABELS_ID = {
    "acne": "Kulit Berjerawat",
    "combination": "Kulit Kombinasi",
    "dry": "Kulit Kering",
    "normal": "Kulit Normal",
    "oily": "Kulit Berminyak",
}

# =====================================================
# PREPROCESSING
# =====================================================

TRANSFORM = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    ),
])

_model = None


# =====================================================
# LOAD MODEL
# =====================================================

def load_cnn_model():
    global _model

    model_path = settings.CNN_MODEL_PATH

    if not os.path.exists(model_path):
        raise RuntimeError(
            f"Model CNN tidak ditemukan: {model_path}"
        )

    try:
        _model = torch.jit.load(
            model_path,
            map_location="cpu"
        )
        _model.eval()

        print(f"[CNN] TorchScript model loaded dari {model_path}")

    except Exception:
        try:
            _model = _create_default_model()

            state_dict = torch.load(
                model_path,
                map_location="cpu"
            )

            if isinstance(state_dict, dict) and "state_dict" in state_dict:
                state_dict = state_dict["state_dict"]

            _model.load_state_dict(state_dict)
            _model.eval()

            print(f"[CNN] State dict model loaded dari {model_path}")

        except Exception as e:
            raise RuntimeError(
                f"Gagal load model CNN: {e}"
            )


# =====================================================
# DEFAULT MODEL
# =====================================================

def _create_default_model() -> nn.Module:
    model = models.mobilenet_v3_small(weights=None)

    model.classifier[-1] = nn.Linear(
        model.classifier[-1].in_features,
        len(SKIN_LABELS)
    )

    model.eval()
    return model


# =====================================================
# PREDICTION
# =====================================================

def predict_skin_type(
    image_bytes: bytes
) -> Tuple[str, float, Dict[str, float]]:

    global _model

    if _model is None:
        load_cnn_model()

    image = Image.open(
        io.BytesIO(image_bytes)
    ).convert("RGB")

    tensor = TRANSFORM(image).unsqueeze(0)

    with torch.no_grad():
        output = _model(tensor)
        probabilities = torch.softmax(
            output,
            dim=1
        ).squeeze()

    probs = probabilities.cpu().numpy()

    pred_idx = int(np.argmax(probs))

    skin_type = SKIN_LABELS[pred_idx]
    confidence = float(probs[pred_idx])

    # DEBUG LOG
    print("\n========== CNN PREDICTION ==========")

    for i in range(len(probs)):
        print(
            f"{i} | "
            f"{SKIN_LABELS[i]:12s} | "
            f"{float(probs[i]):.4f}"
        )

    print(
        f"PREDICTED = {skin_type} "
        f"({confidence:.4f})"
    )

    print("====================================\n")

    all_scores = {
        SKIN_LABELS[i]: float(probs[i])
        for i in range(len(probs))
    }

    return (
        skin_type,
        confidence,
        all_scores
    )