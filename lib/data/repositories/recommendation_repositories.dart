// INI HARUS DI HAPUS TOTAL SAMA FILENYA

// import '../../src/services/supabase_service.dart';
// import '../models/product_model.dart';
// import '../models/recommendation_model.dart';
// import 'skin_repositories.dart';
//
// class RecommendationRepository {
//   RecommendationRepository({
//     SkinRepository? skinRepository,
//     SupabaseService? supabaseService,
//   })  : _skinRepository = skinRepository ?? SkinRepository(),
//         _supabaseService = supabaseService ?? SupabaseService();
//
//   final SkinRepository _skinRepository;
//   final SupabaseService _supabaseService;
//
//   /// Mengambil rekomendasi yang dikelompokkan berdasarkan kategori (Top 5 per kategori)
//   Future<Map<String, List<RecommendationModel>>> recommendCategorized({
//     required String skinType,
//     required List<String> concerns,
//   }) async {
//     // Ambil data produk dari Supabase
//     final catalog = await _supabaseService.fetchProductCatalog();
//     if (catalog.isEmpty) return {};
//
//     final profile = _skinRepository.profileFor(skinType);
//     final categories = ['facial_wash', 'toner', 'moisturizer', 'sunscreen'];
//     Map<String, List<RecommendationModel>> categorizedResults = {};
//
//     for (var category in categories) {
//       // Pencocokan kategori secara fleksibel (mengandung kata kunci)
//       final String searchKey = category.split('_')[0];
//
//       final filtered = catalog.where((p) {
//         final prodCat = p.category.toLowerCase();
//         return prodCat.contains(searchKey) || prodCat.contains(category.replaceAll('_', ' '));
//       }).toList();
//
//       final scored = filtered.map((product) => _scoreProduct(
//         product: product,
//         profile: profile,
//         concerns: concerns,
//       )).toList()
//         ..sort((left, right) => right.score.compareTo(left.score));
//
//       categorizedResults[category] = scored.take(5).toList();
//     }
//
//     return categorizedResults;
//   }
//
//   /// Rekomendasi list tunggal (Flat List)
//   Future<List<RecommendationModel>> recommend({
//     required String skinType,
//     required List<String> concerns,
//     int limit = 6,
//   }) async {
//     final catalog = await _supabaseService.fetchProductCatalog();
//     if (catalog.isEmpty) return [];
//
//     final profile = _skinRepository.profileFor(skinType);
//     final results = catalog.map((product) => _scoreProduct(
//       product: product,
//       profile: profile,
//       concerns: concerns
//     )).toList()
//       ..sort((left, right) => right.score.compareTo(left.score));
//
//     return results.take(limit).toList();
//   }
//
//   RecommendationModel _scoreProduct({
//     required ProductModel product,
//     required SkinProfile profile,
//     required List<String> concerns,
//   }) {
//     double score = 0;
//     final matchedConcerns = <String>[];
//     final matchedIngredients = <String>[];
//
//     final String content = "${product.name} ${product.description}".toLowerCase();
//     final String targetSkin = profile.label.toLowerCase();
//
//     // 1. Skor Tipe Kulit (40%)
//     bool isSuitable = product.suitableSkinTypes.any((t) => t.toLowerCase() == targetSkin) ||
//                       content.contains(targetSkin) ||
//                       content.contains("semua jenis kulit");
//     if (isSuitable) score += 40;
//
//     // 2. Skor Gejala (40%)
//     for (final concern in concerns) {
//       final String c = concern.toLowerCase();
//       if (product.concerns.any((pc) => pc.toLowerCase() == c) || content.contains(c)) {
//         matchedConcerns.add(concern);
//         score += 20;
//       }
//     }
//
//     // 3. Skor Bahan Aktif (20%)
//     for (final ingredient in profile.idealIngredients) {
//       if (content.contains(ingredient.toLowerCase())) {
//         matchedIngredients.add(ingredient);
//         score += 10;
//       }
//     }
//
//     return RecommendationModel(
//       product: product,
//       score: score.clamp(0, 100).toDouble(),
//       matchedConcerns: matchedConcerns,
//       matchedIngredients: matchedIngredients,
//       rationale: matchedConcerns.isNotEmpty
//           ? 'Cocok untuk masalah ${matchedConcerns.take(2).join(" & ")}.'
//           : 'Sesuai dengan profil kulit ${profile.title}.',
//     );
//   }
// }
