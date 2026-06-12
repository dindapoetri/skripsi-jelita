import 'product_model.dart';

class RecommendationModel {
  final ProductModel product;
  final double score;
  final List<String> matchedConcerns;
  final List<String> matchedIngredients;
  final String rationale;

  const RecommendationModel({
    required this.product,
    required this.score,
    required this.matchedConcerns,
    required this.matchedIngredients,
    required this.rationale,
  });
}
