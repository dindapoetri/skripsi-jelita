import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pytorch_lite/pytorch_lite.dart';

import 'face_detection_service.dart';
import 'image_crop_service.dart';
import 'clahe_processor.dart';

import '../../data/models/skin_result_models.dart';
import '../../data/repositories/skin_repositories.dart';

class PyTorchService {
  ClassificationModel? _model;

  final SkinRepository _skinRepository = SkinRepository();

  // Pipeline
  final FaceDetectionService _faceService = FaceDetectionService();
  final ImageCropService _cropService = ImageCropService();
  final ClaheProcessor _claheProcessor = ClaheProcessor(); // [BARU]

  static const List<double> _normMean = [0.485, 0.456, 0.406];
  static const List<double> _normStd = [0.229, 0.224, 0.225];

  Future<void> loadModel() async {
    try {
      _model = await PytorchLite.loadClassificationModel(
        "assets/models/cnn/model_cnn.ptl",
        224,
        224,
        5,
        labelPath: "assets/labels/labels.txt",
      );
      print("Model PyTorch Berhasil Dimuat");
    } catch (e) {
      print("Error saat memuat model atau label: $e");
      _model = null;
    }
  }

  List<double> _applySoftmax(List<double> logits) {
    if (logits.isEmpty) return [];

    double maxLogit = logits.reduce(max);

    List<double> exps =
    logits.map((x) => exp(x - maxLogit)).toList();

    double sumExps = exps.reduce((a, b) => a + b);

    return exps.map((x) => x / sumExps).toList();
  }

  Uint8List _applyClahe(Uint8List croppedBytes) {
    final decoded = img.decodeImage(croppedBytes);
    if (decoded == null) {
      throw Exception("Gagal decode gambar hasil crop untuk CLAHE");
    }
    final normalized = _claheProcessor.apply(decoded);
    return Uint8List.fromList(img.encodeJpg(normalized));
  }

  Future<SkinResultModel> classifySkin(String imagePath) async {
    if (_model == null) {
      await loadModel();
    }

    if (_model == null) {
      throw Exception("Model gagal dimuat.");
    }

    try {
      final face = await _faceService.detectSingleFace(imagePath);

      if (face == null) {
        throw Exception("No face detected. Please use face image only.");
      }

      final Uint8List croppedBytes =
      await _cropService.cropFace(
        imagePath: imagePath,
        face: face,
      );

      final Uint8List inputImage = _applyClahe(croppedBytes);

      final List<double> rawLogits =
      await _model!.getImagePredictionList(
        inputImage,
        mean: _normMean,
        std: _normStd,
      );

      final List<double> predictionList =
      _applySoftmax(rawLogits);

      final modelLabels = ['acne', 'combi', 'dry', 'normal', 'oily'];

      final Map<String, double> probabilities = {};

      int maxIndex = 0;
      double maxProb = -1;

      for (int i = 0;
      i < modelLabels.length && i < predictionList.length;
      i++) {
        probabilities[modelLabels[i]] = predictionList[i];

        if (predictionList[i] > maxProb) {
          maxProb = predictionList[i];
          maxIndex = i;
        }
      }

      String resultLabel = modelLabels[maxIndex];

      String mappedLabel =
      resultLabel == 'combi' ? 'combination' : resultLabel;

      final sortedProbs = predictionList.toList()..sort((a, b) => b.compareTo(a));
      final double confidenceGap =
      sortedProbs.length >= 2 ? (sortedProbs[0] - sortedProbs[1]) : 1.0;
      if (confidenceGap < 0.15) {
        print(
          "⚠️ Confidence gap rendah ($confidenceGap) — hasil kemungkinan kurang pasti, "
              "pertimbangkan sarankan retake foto ke user.",
        );
      }

      final profile =
      _skinRepository.profileFor(mappedLabel);

      return SkinResultModel(
        skinType: profile.label,
        confidence: maxProb,
        description: profile.description,
        concerns: profile.concerns,
        idealIngredients: profile.idealIngredients,
        recommendations: profile.recommendations,
        probabilities: probabilities,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print("Error klasifikasi: $e");
      throw Exception("Gagal memproses gambar: $e");
    }
  }

  void dispose() {
    _faceService.dispose();
  }
}
