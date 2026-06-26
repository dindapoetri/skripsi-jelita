// INI HARUS DI HAPUS TOTAL SAMA FILENYA

// import '../../data/models/skin_result_models.dart';
// import 'supabase_service.dart';
// import 'cbf_service.dart';
// import 'pytorch_service.dart';
//
// class ScanService {
//   final PyTorchService _cnn = PyTorchService();
//   final CbfService _cbf = CbfService();
//   final SupabaseService _supabaseService = SupabaseService();
//
//   Future<void> initialize() async {
//     // Muat model CNN (PyTorch Lite)
//     await _cnn.loadModel();
//     // Muat metadata CBF (TF-IDF Vocab dari Supabase)
//     await _cbf.initialize();
//   }
//
//   Future<Map<String, dynamic>> scan(
//     String imagePath, {
//     List<String> symptoms = const [],
//   }) async {
//     // 1. CNN — Klasifikasi jenis kulit secara on-device (offline)
//     final skinResult = await _cnn.classifySkin(imagePath);
//
//     // 2. CBF — Hitung rekomendasi produk menggunakan CbfService yang terhubung ke Supabase
//     final productRecs = await _cbf.recommend(
//       skinResult,
//       topK: 10,
//     );
//
//     // 3. Simpan riwayat scan secara otomatis ke Supabase
//     try {
//       await _supabaseService.saveScanResult(skinResult);
//       print("✅ Scan history tersimpan di Supabase Cloud");
//     } catch (e) {
//       print("⚠️ Gagal menyimpan history: $e");
//     }
//
//     return {
//       'skinResult': skinResult,
//       'productRecommendations': productRecs,
//     };
//   }
// }
