import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/skin_result_models.dart';
import 'postgres_service.dart';

class HistoryService {
  final _pgService = PostgresService();

  /// Simpan riwayat ke tabel classification_results di PostgreSQL
  Future<void> saveResult(SkinResultModel result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        print('⚠️ User ID tidak ditemukan di session lokal.');
        return;
      }

      await _pgService.execute(
        'INSERT INTO classification_results ('
        'user_id, skin_type, confidence_score, short_recommendation, '
        'idealingredients, concerns, recommendations, probabilities, '
        'image_path, created_at, detected_symptoms'
        ') VALUES (@uid, @st, @conf, @desc, @ing, @con, @rec, @prob, @img, @cat, @sym)',
        params: {
          'uid': userId,
          'st': result.skinType,
          'conf': result.confidence,
          'desc': result.description,
          'ing': result.idealIngredients.join(','),
          'con': result.concerns.join(','),
          'rec': result.recommendations.join(','),
          // 'prob': result.probabilities.join(','),
          'img': result.imagePath,
          'cat': DateTime.now().toIso8601String(),
          'sym': result.symptoms.join(','),
        },
      );
      print('✅ Riwayat berhasil disimpan ke PostgreSQL');
    } catch (e) {
      print('❌ Gagal simpan riwayat ke DB: $e');
    }
  }

  Future<List<SkinResultModel>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return [];

      final response = await _pgService.query(
        'SELECT * FROM classification_results WHERE user_id = @uid ORDER BY created_at DESC',
        params: {'uid': userId},
      );

      return response.map((row) => SkinResultModel.fromMap(row.toColumnMap())).toList();
    } catch (e) {
      print('❌ Gagal memuat riwayat: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      await _pgService.execute(
        'DELETE FROM classification_results WHERE user_id = @uid',
        params: {'uid': userId},
      );
      print('✅ Riwayat dibersihkan');
    } catch (e) {
      print('❌ Gagal bersihkan riwayat: $e');
    }
  }
}
