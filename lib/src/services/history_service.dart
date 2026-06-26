import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/skin_result_models.dart';
import '../constant/api_constant.dart';

class HistoryService {
  final String apiBaseUrl = ApiConstant.baseUrl;

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Upload file gambar lokal ke FastAPI → Supabase Storage.
  /// Mengembalikan image_url publik, atau null kalau gagal/tidak ada file.
  Future<String?> uploadImage(String localPath) async {
    if (localPath.isEmpty) return null;

    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      print('ℹ️ Input sudah berupa URL, lewati upload: $localPath');
      return localPath;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      print('⚠️ File lokal tidak ditemukan, skip upload: $localPath');
      return null;
    }

    // Testing
    final bytes = await file.length();
    final sizeKb = bytes / 1024;
    final sizeMb = bytes / (1024 * 1024);
    print('📷 File path: $localPath');
    print('📦 File size: ${sizeKb.toStringAsFixed(2)} KB');
    print('📦 File size: ${sizeMb.toStringAsFixed(2)} MB');

    try {
      final token = await _token;
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Tidak bisa upload gambar.');
      }

      final uri = Uri.parse('$apiBaseUrl/history/upload-image');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', localPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Upload gambar berhasil: ${data['image_url']}');
        return data['image_url'] as String?;
      } else {
        print('❌ Gagal upload gambar (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error upload gambar: $e');
      return null;
    }
  }

  Future<List<SkinResultModel>> loadHistory() async {
    try {
      final token = await _token;
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$apiBaseUrl/history/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SkinResultModel.fromMap(item)).toList();
      } else {
        print('❌ Gagal memuat riwayat via FastAPI: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error load history via FastAPI: $e');
      return [];
    }
  }

  /// PENTING: sekarang benar-benar memanggil uploadImage() dulu, baru
  /// pakai URL hasilnya saat POST /history/. Sebelumnya uploadImage()
  /// ditulis tapi TIDAK PERNAH dipanggil dari sini, sehingga image_url
  /// yang terkirim ke backend selalu path lokal mentah (bukan URL),
  /// dan gambar gagal tampil di halaman Riwayat.
  Future<void> saveResult(SkinResultModel result) async {
    final token = await _token;
    if (token == null) {
      throw Exception('Sesi login tidak ditemukan. Tidak bisa menyimpan riwayat.');
    }

    final isAlreadyUrl =
        result.imagePath.startsWith('http://') || result.imagePath.startsWith('https://');

    final uploadedImageUrl = isAlreadyUrl
        ? result.imagePath
        : await uploadImage(result.imagePath);

    print('📨 image_url final untuk disimpan = $uploadedImageUrl');

    // 2. Baru simpan riwayat, sisipkan URL hasil upload (bisa null kalau
    //    upload gagal/dilewati -- tetap lanjut simpan riwayat teks).
    final response = await http.post(
      Uri.parse('$apiBaseUrl/history/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'skin_type':         result.skinType,
        'confidence_score':  result.confidence,
        'detected_symptoms': result.symptoms,
        'concerns':          result.concerns,
        'description':       result.description,
        'probabilities':     result.probabilities,
        'recommendations':   result.recommendations,
        'ideal_ingredients': result.idealIngredients,
        'image_url':         uploadedImageUrl, // URL Storage asli, bukan path lokal lagi
      }),
    );

    print('📥 RESPONSE POST /history/ status = ${response.statusCode}');
    print('📥 RESPONSE POST /history/ body = ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Riwayat berhasil disimpan melalui transaksi FastAPI');
    } else {
      throw Exception('Gagal simpan riwayat (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> deleteHistory(String scanId) async {
    final token = await _token;
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('$apiBaseUrl/history/$scanId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Gagal menghapus riwayat (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> clearHistory() async {
    try {
      final token = await _token;
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$apiBaseUrl/history/all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Riwayat berhasil dibersihkan via FastAPI');
      }
    } catch (e) {
      print('❌ Error membersihkan riwayat via FastAPI: $e');
    }
  }
}