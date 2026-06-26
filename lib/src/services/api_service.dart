import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/api_constant.dart';

class ApiService {
  final String baseUrl = ApiConstant.baseUrl;
  const ApiService();

  // Mengambil token JWT dari session untuk diteruskan ke FastAPI
  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  // Otentikasi langsung dari supabase
  // String? get _token => Supabase.instance.client.auth.currentSession?.accessToken;

  Future<Map<String, String>> get _headers async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token}',
  };

  // Fungsi umum GET ke FastAPI
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  // Fungsi umum POST ke FastAPI
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Fungsi Multipart (Upload File) ke FastAPI
  Future<dynamic> postMultipart(String endpoint, String filePath, Map<String, String> fields) async {
    final token = await _token;
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'))
      ..headers.addAll({'Authorization': 'Bearer $token'})
      ..files.add(await http.MultipartFile.fromPath('file', filePath))
      ..fields.addAll(fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Terjadi kesalahan pada server');
    }
  }
}