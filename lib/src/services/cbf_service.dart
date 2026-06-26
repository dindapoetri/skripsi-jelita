import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/recommendation_model.dart';
import '../constant/api_constant.dart';

/// Exception khusus supaya UI (RecommendationScreen) bisa tampilkan pesan
/// yang lebih jelas dibanding generic Exception.
class RecommendationAuthException implements Exception {
  final String message;
  RecommendationAuthException(this.message);
  @override
  String toString() => message;
}

class CbfService {
  final String apiBaseUrl = ApiConstant.baseUrl; // diasumsikan sudah termasuk /api/v1

  /// Token diambil dari SharedPreferences — sumber yang SAMA dengan yang
  /// dipakai SupabaseService.signIn() & ApiService. Ini access_token hasil
  /// POST /auth/login FastAPI, BUKAN token dari Supabase Auth SDK.
  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static const List<String> _categories = [
    'facial_wash',
    'toner',
    'moisturizer',
    'sunscreen',
  ];

  /// Memanggil POST /recommendations/ (wajib login).
  /// Mengembalikan Map per kategori, masing-masing top [topN] produk.
  Future<Map<String, List<RecommendationModel>>> recommendCategorized({
    required String skinType,
    required List<String> concerns,
    int topN = 5,
  }) async {
    final token = await _token;
    if (token == null) {
      // Sengaja throw exception khusus (bukan return {} diam-diam) supaya
      // UI tahu kalau penyebabnya user belum/sesi habis login, bukan "produk tidak ada".
      throw RecommendationAuthException(
        'Sesi login tidak ditemukan. Silakan login ulang untuk melihat rekomendasi.',
      );
    }

    final response = await http.post(
      Uri.parse('$apiBaseUrl/recommendations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'skin_type': skinType,
        'concerns': concerns,
        'top_n': topN,
      }),
    );

    if (response.statusCode == 401) {
      throw RecommendationAuthException(
        'Sesi login sudah berakhir. Silakan login ulang.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat rekomendasi (${response.statusCode}): ${response.body}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final Map<String, dynamic>? recs = data['recommendations'] as Map<String, dynamic>?;

    if (recs == null) return {};

    final Map<String, List<RecommendationModel>> result = {};
    for (final category in _categories) {
      final List<dynamic> items = (recs[category] as List<dynamic>?) ?? [];
      result[category] = items
          .map((item) => RecommendationModel.fromCbfMap(
        Map<String, dynamic>.from(item),
        skinType: skinType,
      ))
          .toList();
    }
    return result;
  }
}