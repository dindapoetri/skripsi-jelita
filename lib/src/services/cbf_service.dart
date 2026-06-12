import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';
import '../../data/models/skin_result_models.dart';
import '../../data/repositories/skin_repositories.dart';
import 'postgres_service.dart';

class CbfService {
  final _pgService = PostgresService();

  List<ProductModel> _products = [];
  List<List<double>> _productVectors = [];
  List<String> _vocabulary = [];
  List<double> _idf = [];

  bool get isReady => _products.isNotEmpty;

  Future<void> initialize({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cbf_data');

    if (cached != null && !forceRefresh) {
      _loadFromCache(jsonDecode(cached));
      return;
    }

    try {
      // 1. Fetch products dari PostgreSQL
      final productsRes = await _pgService.query(
        'SELECT id, product_name, brand, category, skin_types, concerns, ingredients, image_url, price_range, tfidf_vector FROM products'
      );

      // 2. Fetch vocabulary & IDF dari tabel metadata
      final metaRes = await _pgService.query(
        "SELECT value FROM cbf_metadata WHERE key = 'tfidf_vocab' LIMIT 1"
      );

      if (metaRes.isEmpty) throw Exception('Metadata TF-IDF tidak ditemukan di database');

      final meta = jsonDecode(metaRes.first.toColumnMap()['value']);
      _vocabulary = List<String>.from(meta['vocabulary']);
      _idf = List<double>.from(meta['idf']);

      _products = [];
      _productVectors = [];
      
      final List<Map<String, dynamic>> productsJson = [];

      for (final row in productsRes) {
        final map = row.toColumnMap();
        productsJson.add(map);
        _products.add(ProductModel.fromMap(map));

        List<double> vec;
        final vecRaw = map['tfidf_vector'];
        
        if (vecRaw is String) {
          // Jika disimpan sebagai string/json di Postgres
          vec = List<double>.from(jsonDecode(vecRaw).map((e) => (e as num).toDouble()));
        } else if (vecRaw is List) {
          vec = vecRaw.map((e) => (e as num).toDouble()).toList();
        } else {
          vec = List<double>.filled(_vocabulary.length, 0.0);
        }

        // Pad/Trim vector agar sesuai vocabulary
        if (vec.length < _vocabulary.length) {
          vec = [...vec, ...List<double>.filled(_vocabulary.length - vec.length, 0.0)];
        } else {
          vec = vec.sublist(0, _vocabulary.length);
        }

        _productVectors.add(_normalize(vec));
      }

      // Simpan cache lokal
      await prefs.setString('cbf_data', jsonEncode({
        'products': productsJson,
        'vocabulary': _vocabulary,
        'idf': _idf,
      }));

      print('✅ CBF beralih ke PostgreSQL: ${_products.length} produk dimuat.');
    } catch (e) {
      print('❌ Error initializing CBF (Postgres): $e');
      if (cached != null) _loadFromCache(jsonDecode(cached));
    }
  }

  void _loadFromCache(Map<String, dynamic> cache) {
    _vocabulary = List<String>.from(cache['vocabulary']);
    _idf = List<double>.from(cache['idf']);
    _products = (cache['products'] as List).map((p) => ProductModel.fromMap(p)).toList();
    
    _productVectors = [];
    for (final p in cache['products']) {
      final vecRaw = p['tfidf_vector'];
      List<double> vec;
      if (vecRaw is String) {
        vec = List<double>.from(jsonDecode(vecRaw).map((e) => (e as num).toDouble()));
      } else if (vecRaw is List) {
        vec = vecRaw.map((e) => (e as num).toDouble()).toList();
      } else {
        vec = List<double>.filled(_vocabulary.length, 0.0);
      }
      
      if (vec.length < _vocabulary.length) {
        vec = [...vec, ...List<double>.filled(_vocabulary.length - vec.length, 0.0)];
      } else {
        vec = vec.sublist(0, _vocabulary.length);
      }
      _productVectors.add(_normalize(vec));
    }
  }

  // Metode _buildQueryVector, _normalize, _cosineSimilarity, recommend tetap sama...
  List<double> _buildQueryVector(List<String> terms) {
    final tf = <String, double>{};
    for (final t in terms) {
      tf[t] = (tf[t] ?? 0) + 1;
    }
    final vector = List<double>.filled(_vocabulary.length, 0.0);
    tf.forEach((term, freq) {
      final idx = _vocabulary.indexOf(term.toLowerCase());
      if (idx >= 0) {
        vector[idx] = (freq / terms.length) * _idf[idx];
      }
    });
    return _normalize(vector);
  }

  List<double> _normalize(List<double> v) {
    final norm = sqrt(v.fold(0.0, (sum, x) => sum + x * x));
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    for (int i = 0; i < a.length; i++) { dot += a[i] * b[i]; }
    return dot;
  }

  Future<List<ProductModel>> recommend(SkinResultModel skinResult, {int topK = 10, String? category}) async {
    if (!isReady) await initialize();
    
    final terms = [skinResult.skinType, ...SkinRepository.toVocabTerms(skinResult.concerns)];
    final queryVector = _buildQueryVector(terms);

    final scored = <Map<String, dynamic>>[];
    for (int i = 0; i < _products.length; i++) {
      final p = _products[i];
      if (category != null) {
        if (!p.category.toLowerCase().contains(category.toLowerCase())) continue;
      }
      final score = _cosineSimilarity(queryVector, _productVectors[i]);
      scored.add({'product': p, 'score': score});
    }
    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scored.take(topK).map((e) => e['product'] as ProductModel).toList();
  }

  Future<Map<String, List<ProductModel>>> recommendByCategory(SkinResultModel skinResult, {int topKPerCategory = 5}) async {
    final categories = ['facial_wash', 'toner', 'moisturizer', 'sunscreen'];
    final result = <String, List<ProductModel>>{};
    for (final cat in categories) {
      final recs = await recommend(skinResult, topK: topKPerCategory, category: cat);
      if (recs.isNotEmpty) result[cat] = recs;
    }
    return result;
  }
}
