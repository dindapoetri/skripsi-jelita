// import '../../data/models/recommendation_model.dart';
// import '../../data/models/skin_result_models.dart';
// import '../../data/repositories/skin_repositories.dart';
// import '../../data/repositories/recommendation_repositories.dart';
//
// class CbfRecommender {
//   CbfRecommender({RecommendationRepository? repository})
//       : _repository = repository ?? RecommendationRepository();
//
//   final RecommendationRepository _repository;
//
//   /// Rekomendasi Umum (Flat List)
//   Future<List<RecommendationModel>> recommend(
//     SkinResultModel skinResult, {
//     List<String> symptoms = const [],
//     int limit = 6,
//   }) async {
//     // Gabungkan concern AI dan pilihan user, pastikan unik
//     final combined = {...skinResult.concerns, ...symptoms}.toList();
//
//     // Konversi ke terms yang dikenali database (Mapping vocab)
//     final concerns = SkinRepository.toVocabTerms(combined);
//
//     return await _repository.recommend(
//       skinType: skinResult.skinType,
//       concerns: concerns,
//       limit: limit,
//     );
//   }
//
//   /// Rekomendasi Terkategori (Top 5 per kategori: Facial Wash, Toner, Moisturizer, Sunscreen)
//   Future<Map<String, List<RecommendationModel>>> recommendCategorized(
//     SkinResultModel skinResult, {
//     List<String> symptoms = const [],
//   }) async {
//     final combined = {...skinResult.concerns, ...symptoms}.toList();
//     final concerns = SkinRepository.toVocabTerms(combined);
//
//     return await _repository.recommendCategorized(
//       skinType: skinResult.skinType,
//       concerns: concerns,
//     );
//   }
// }

import '../../data/models/recommendation_model.dart';
import '../../data/models/skin_result_models.dart';
import '../../data/repositories/skin_repositories.dart';
import 'cbf_service.dart';

class CbfRecommender {
  CbfRecommender({CbfService? service}) : _service = service ?? CbfService();

  final CbfService _service;

  /// Rekomendasi Terkategori (Top N per kategori: Facial Wash, Toner, Moisturizer, Sunscreen)
  /// Sekarang manggil FastAPI (/recommendations/) — bukan scoring manual di Dart.
  Future<Map<String, List<RecommendationModel>>> recommendCategorized(
      SkinResultModel skinResult, {
        List<String> symptoms = const [],
        int topN = 5,
      }) async {
    final combined = {...skinResult.concerns, ...symptoms}.toList();
    final concerns = SkinRepository.toVocabTerms(combined);

    return await _service.recommendCategorized(
      skinType: skinResult.skinType,
      concerns: concerns,
      topN: topN,
    );
  }
}
