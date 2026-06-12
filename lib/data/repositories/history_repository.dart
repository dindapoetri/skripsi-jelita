import '../../src/services/postgres_service.dart';
import '../models/skin_result_models.dart';

class HistoryRepository {
  final PostgresService _pgService = PostgresService();

  Future<void> saveResult(SkinResultModel result, String userId) async {
    try {
      await _pgService.execute(
        'INSERT INTO classification_results (user_id, skin_type, confidence, ideal_ingredients, concerns, image_path, probabilities, created_at) '
        'VALUES (@userId, @skinType, @confidence, @ingredients, @concerns, @imagePath, @probs, @createdAt)',
        params: {
          'userId': userId,
          'skinType': result.skinType,
          'confidence': result.confidence,
          'ingredients': result.idealIngredients.join(','),
          'concerns': result.concerns.join(','),
          'imagePath': result.imagePath,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error saving history: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    try {
      final result = await _pgService.query(
        'SELECT * FROM classification_results WHERE user_id = @userId ORDER BY created_at DESC',
        params: {'userId': userId},
      );
      
      return result.map((row) {
        // Mapping depend on your table structure
        return row.toColumnMap();
      }).toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }
}
