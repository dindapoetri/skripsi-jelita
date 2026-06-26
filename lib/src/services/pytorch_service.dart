import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:pytorch_lite/pytorch_lite.dart';

import '../../data/models/skin_result_models.dart';
import '../../data/repositories/skin_repositories.dart';

class PyTorchService {
  ClassificationModel? _model;
  final SkinRepository _skinRepository = SkinRepository();

  Future<void> loadModel() async {
    try {
      _model = await PytorchLite.loadClassificationModel(
        "assets/models/cnn/mobilenetv3_skintype_90.ptl",
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

  // Fungsi Softmax untuk mengubah Logits menjadi Probabilitas (0-1)
  List<double> _applySoftmax(List<double> logits) {
    if (logits.isEmpty) return [];
    
    // Mencari nilai maksimal untuk stabilitas numerik (mencegah overflow)
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    
    // Hitung eksponensial dari setiap logit yang dikurangi maxLogit
    List<double> exps = logits.map((x) => exp(x - maxLogit)).toList();
    
    // Hitung total jumlah eksponensial
    double sumExps = exps.reduce((a, b) => a + b);
    
    // Bagi setiap eksponensial dengan totalnya
    return exps.map((x) => x / sumExps).toList();
  }

  Future<SkinResultModel> classifySkin(String imagePath) async {
    if (_model == null) {
      await loadModel();
    }

    if (_model == null) {
      throw Exception("Model gagal dimuat.");
    }

    try {
      Uint8List imageBytes = await File(imagePath).readAsBytes();
      
      // Ambil logits mentah dari model
      final List<double> rawLogits = await _model!.getImagePredictionList(imageBytes);
      
      // TERAPKAN SOFTMAX DISINI
      final List<double> predictionList = _applySoftmax(rawLogits);
      
      final modelLabels = ['acne', 'combi', 'dry', 'normal', 'oily'];
      final Map<String, double> probabilities = {};
      
      int maxIndex = 0;
      double maxProb = -1.0;

      for (int i = 0; i < modelLabels.length && i < predictionList.length; i++) {
        probabilities[modelLabels[i]] = predictionList[i];
        
        // Cari index dengan probabilitas tertinggi setelah softmax
        if (predictionList[i] > maxProb) {
          maxProb = predictionList[i];
          maxIndex = i;
        }
      }

      String resultLabel = modelLabels[maxIndex];
      String mappedLabel = resultLabel;
      if (mappedLabel == 'combi') mappedLabel = 'combination';

      final profile = _skinRepository.profileFor(mappedLabel);

      return SkinResultModel(
        skinType: profile.label,
        confidence: maxProb, // nilainya akan 0.0 sampai 1.0 (misal 0.90 untuk 90%)
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
}
