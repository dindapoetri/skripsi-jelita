import '../../src/services/postgres_service.dart';
import '../models/product_model.dart';
import '../models/recommendation_model.dart';
import 'skin_repositories.dart';

class RecommendationRepository {
  RecommendationRepository({
    SkinRepository? skinRepository,
    PostgresService? pgService,
  })  : _skinRepository = skinRepository ?? SkinRepository(),
        _pgService = pgService ?? PostgresService();

  final SkinRepository _skinRepository;
  final PostgresService _pgService;

  Future<List<ProductModel>> _fetchProductCatalog() async {
    try {
      final result = await _pgService.query('SELECT * FROM products');
      return result.map((row) => ProductModel.fromMap(row.toColumnMap())).toList();
    } catch (e) {
      print('Error fetch products: $e');
      return [];
    }
  }

  Future<List<RecommendationModel>> recommend({
    required String skinType,
    required List<String> concerns,
    int limit = 6,
  }) async {
    final catalog = await _fetchProductCatalog();
    if (catalog.isEmpty) return [];
    
    final profile = _skinRepository.profileFor(skinType);
    final results = catalog.map((product) => _scoreProduct(product: product, profile: profile, concerns: concerns)).toList()
      ..sort((left, right) => right.score.compareTo(left.score));
      
    return results.take(limit).toList();
  }

  Future<Map<String, List<RecommendationModel>>> recommendCategorized({
    required String skinType,
    required List<String> concerns,
  }) async {
    final catalog = await _fetchProductCatalog();
    if (catalog.isEmpty) return {};

    final profile = _skinRepository.profileFor(skinType);
    final categories = ['facial_wash', 'toner', 'moisturizer', 'sunscreen'];
    Map<String, List<RecommendationModel>> categorizedResults = {};

    for (var category in categories) {
      final String searchKey = category.split('_')[0]; 
      
      final filtered = catalog.where((p) {
        final prodCat = p.category.toLowerCase().trim();
        return prodCat.contains(searchKey) || 
               prodCat == category.replaceAll('_', ' ') ||
               (category == 'moisturizer' && (prodCat.contains('cream') || prodCat.contains('gel')));
      }).toList();
      
      final scored = filtered.map((product) => _scoreProduct(
        product: product,
        profile: profile,
        concerns: concerns,
      )).toList()
        ..sort((left, right) => right.score.compareTo(left.score));

      categorizedResults[category] = scored.take(5).toList();
    }

    return categorizedResults;
  }

  RecommendationModel _scoreProduct({
    required ProductModel product,
    required SkinProfile profile,
    required List<String> concerns,
  }) {
    double score = 0;
    final matchedConcerns = <String>[];
    final matchedIngredients = <String>[];

    final String content = "${product.name} ${product.description}".toLowerCase();
    final String targetSkin = profile.label.toLowerCase();

    // 1. SCORING TIPE KULIT (40%)
    bool isSuitable = product.suitableSkinTypes.any((t) => t.toLowerCase() == targetSkin) ||
                      content.contains(targetSkin) ||
                      content.contains("all skin types") ||
                      content.contains("semua jenis kulit");

    if (isSuitable) {
      score += 40;
    } else if (targetSkin == 'normal') {
      score += 10;
    }

    // 2. SCORING GEJALA/CONCERNS (40%)
    for (final concern in concerns) {
      final String c = concern.toLowerCase();
      bool found = product.concerns.any((pc) => pc.toLowerCase() == c) || content.contains(c);
      
      if (!found) {
        final synonyms = {
          'acne': ['jerawat', 'berjerawat', 'meradang'],
          'dullness': ['kusam', 'cerah', 'mencerahkan', 'glow'],
          'dry': ['kering', 'melembabkan', 'hidrasi', 'dehidrasi'],
          'oily': ['berminyak', 'sebum', 'kilap', 'minyak berlebih'],
          'pores': ['pori', 'komedo'],
        };
        if (synonyms.containsKey(c)) {
          for (var syn in synonyms[c]!) {
            if (content.contains(syn)) { found = true; break; }
          }
        }
      }

      if (found) {
        matchedConcerns.add(concern);
        score += 20;
      }
    }

    // 3. SCORING INGREDIENTS (20%)
    for (final ingredient in profile.idealIngredients) {
      if (content.contains(ingredient.toLowerCase())) {
        matchedIngredients.add(ingredient);
        score += 10;
      }
    }

    final normalizedScore = score.clamp(5, 100).toDouble();
    
    String rationale = "";
    if (matchedConcerns.isNotEmpty) {
      rationale = 'Membantu masalah ${matchedConcerns.take(2).join(" & ")}.';
    } else if (isSuitable) {
      rationale = 'Sesuai untuk tipe kulit ${profile.title}.';
    } else {
      rationale = 'Produk perawatan harian yang relevan.';
    }

    return RecommendationModel(
      product: product,
      score: normalizedScore,
      matchedConcerns: matchedConcerns,
      matchedIngredients: matchedIngredients,
      rationale: rationale,
    );
  }
}
