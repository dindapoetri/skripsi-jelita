import 'product_model.dart';

class RecommendationModel {
  final ProductModel product;
  final double score;
  final List<String> matchedConcerns; // catatan: berisi KANDUNGAN/INGREDIENTS yang relevan,
  // bukan keluhan kulit — lihat penjelasan di rationale builder.
  final List<String> matchedIngredients;
  final String rationale;

  const RecommendationModel({
    required this.product,
    required this.score,
    required this.matchedConcerns,
    required this.matchedIngredients,
    required this.rationale,
  });

  /// Factory untuk parsing satu item dari response FastAPI
  /// POST /api/v1/recommendations/ (lihat RecommendationResponse.recommendations.<category>[i])
  ///
  /// Bentuk JSON per item:
  /// {
  ///   "id": "...",
  ///   "name": "...",
  ///   "brand": "...",
  ///   "category": "...",
  ///   "description_clean": null,
  ///   "suitable_for": null,
  ///   "image_url": null,
  ///   "skin_types": ["dry", "normal"],
  ///   "concerns": ["niacinamide", "centella"],  // <- isinya KANDUNGAN, bukan concern kulit
  ///   "similarity_score": 0
  /// }
  factory RecommendationModel.fromCbfMap(
      Map<String, dynamic> map, {
        String skinType = '',
      }) {
    final product = ProductModel.fromMap(map);

    // Kolom "concerns" di backend sebenarnya berisi kandungan/ingredients aktif
    // (data source: kolom `concerns` Supabase yang ternyata diisi nama bahan,
    // bukan keluhan kulit). Kita pakai apa adanya sebagai "kandungan relevan".
    final List<String> relevantIngredients = product.concerns;

    final rationale = _buildRationale(
      ingredients: relevantIngredients,
      skinType: skinType.isNotEmpty ? skinType : product.suitableSkinTypes.firstOrNull ?? '',
      product: product,
    );

    return RecommendationModel(
      product: product,
      score: ((map['similarity_score'] as num?) ?? 0).toDouble(),
      matchedConcerns: relevantIngredients, // direframe sbg kandungan, lihat docstring di atas
      matchedIngredients: relevantIngredients,
      rationale: rationale,
    );
  }

  static String _buildRationale({
    required List<String> ingredients,
    required String skinType,
    required ProductModel product,
  }) {
    if (ingredients.isNotEmpty) {
      final shown = ingredients.take(2).join(' & ');
      return 'Mengandung $shown yang relevan untuk kulit ${skinType.isNotEmpty ? skinType : "kamu"}.';
    }
    if (skinType.isNotEmpty) {
      return 'Sesuai untuk tipe kulit $skinType.';
    }
    return 'Direkomendasikan berdasarkan profil kulitmu.';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}