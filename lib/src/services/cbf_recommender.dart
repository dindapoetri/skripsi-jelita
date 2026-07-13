import '../../data/models/recommendation_model.dart';
import '../../data/models/skin_result_models.dart';
import '../../data/repositories/skin_repositories.dart';
import 'cbf_service.dart';

class CbfRecommender {
  CbfRecommender({CbfService? service}) : _service = service ?? CbfService();

  final CbfService _service;
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
