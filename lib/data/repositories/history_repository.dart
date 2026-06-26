import '../../src/services/api_service.dart';
import '../models/skin_result_models.dart';

class HistoryRepository {
  final ApiService _api = const ApiService();

  /// Mengambil riwayat klasifikasi dari FastAPI
  Future<List<SkinResultModel>> getHistory() async {
    try {
      // Hit endpoint FastAPI yang mengambil data dari Supabase
      final List<dynamic> response = await _api.get('/scans/history');
      return response.map((item) => SkinResultModel.fromMap(item)).toList();
    } catch (e) {
      print('❌ Error fetch history via FastAPI: $e');
      return [];
    }
  }

  /// Menyimpan hasil klasifikasi melalui FastAPI (Transaksi)
  Future<void> saveResult(SkinResultModel result) async {
    try {
      await _api.post('/scans/save', result.toMap());
      print('✅ Berhasil simpan riwayat via FastAPI');
    } catch (e) {
      print('❌ Error simpan riwayat via FastAPI: $e');
    }
  }

  /// Menghapus seluruh riwayat melalui FastAPI
  Future<void> clearHistory() async {
    try {
      await _api.get('/scans/clear-history'); // Sesuaikan dengan endpoint FastAPI Anda
      print('✅ Riwayat dibersihkan via FastAPI');
    } catch (e) {
      print('❌ Error hapus riwayat via FastAPI: $e');
    }
  }
}
