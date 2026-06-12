import '../../data/models/skin_result_models.dart';
import 'supabase_service.dart';
import 'cbf_recommender.dart';
import 'pytorch_service.dart';

class ScanService {
  final PyTorchService _cnn = PyTorchService();
  final CbfRecommender _cbf = CbfRecommender();
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> initialize() async {
    await _cnn.loadModel();
  }

  Future<Map<String, dynamic>> scan(
    String imagePath, {
    List<String> symptoms = const [],
  }) async {
    // 1. CNN — klasifikasi jenis kulit
    final skinResult = await _cnn.classifySkin(imagePath);

    // 2. CBF — rekomendasi produk berdasarkan hasil CNN dan gejala
    final productRecs = await _cbf.recommend(
      skinResult,
      symptoms: symptoms,
    );

    // 3. Simpan riwayat ke Supabase
    await _supabaseService.saveScanResult(skinResult);

    return {
      'skinResult': skinResult,
      'productRecommendations': productRecs,
    };
  }
}
