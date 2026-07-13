import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/api_constant.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = ApiConstant.baseUrl;
  const ApiService();

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    debugPrint("🔐 TOKEN FETCHED: $token");

    return token;
  }

  Future<Map<String, String>> get _headers async {
    final token = await _token;

    if (token == null || token.isEmpty) {
      debugPrint("⚠️ TOKEN NULL → REQUEST WITHOUT AUTH HEADER");

      return {
        'Content-Type': 'application/json',
      };
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> postMultipart(
      String endpoint,
      String filePath,
      Map<String, String> fields,
      ) async {
    final token = await _token;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields.addAll(fields);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint("📡 STATUS: ${response.statusCode}");
    debugPrint("📡 BODY: ${response.body}");

    // SUCCESS
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // HANDLE UNAUTHORIZED (TAPI JANGAN AUTO LOGOUT DI SINI)
    if (response.statusCode == 401) {
      debugPrint("🚨 401 UNAUTHORIZED (NO AUTO LOGOUT TRIGGERED)");
      throw Exception("UNAUTHORIZED");
    }

    // HANDLE ERROR SAFE PARSE
    try {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Server Error');
    } catch (_) {
      throw Exception('Server Error (${response.statusCode})');
    }
  }
}
