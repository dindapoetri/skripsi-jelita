import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Untuk emulator Android mengakses localhost komputer
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  const ApiService();

  // Mengambil token JWT dari SharedPreferences yang disimpan saat login
  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>?> getJson(String endpoint) async {
    try {
      final token = await _token;
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('ApiService GET Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> postJson(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _token;
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('ApiService POST Error: $e');
      return null;
    }
  }

  // Pemanggilan untuk klasifikasi (CNN) ke Backend FastAPI
  Future<Map<String, dynamic>> classifyAndRecommend({
    required File imageFile,
    required List<String> concerns,
  }) async {
    final token = await _token;
    final uri = Uri.parse('$baseUrl/classify/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path))
      ..fields['concerns'] = jsonEncode(concerns);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal klasifikasi: ${response.body}');
    }
  }

  // Pemanggilan untuk rekomendasi (CBF) ke Backend FastAPI
  Future<Map<String, dynamic>> getRecommendations({
    required String skinType,
    required List<String> concerns,
  }) async {
    final token = await _token;
    final response = await http.post(
      Uri.parse('$baseUrl/recommendations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'skin_type': skinType,
        'concerns': concerns,
        'top_n': 5,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil rekomendasi: ${response.body}');
    }
  }
}
