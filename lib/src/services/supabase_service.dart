import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/skin_result_models.dart';
import '../../data/models/product_model.dart';
import 'api_service.dart';

class SupabaseService {
  final ApiService _api = const ApiService();

  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  // --- AUTHENTICATION VIA FASTAPI ---
  Future<void> signIn(String email, String password) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (response != null && response['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);
      await _saveUserInfo(response['user']);
    }
  }

  Future<void> signUp(String email, String password, String name, {
    required String username,
  }) async {
    final response = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'full_name': name,
      'username': username,
    });
    // Auto-login setelah register jika backend langsung return token
    if (response != null && response['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);
      await _saveUserInfo(response['user']);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_full_name');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
  }

  // Menyimpan data user (dari response login/register) ke SharedPreferences
  Future<void> _saveUserInfo(dynamic user) async {
    if (user == null || user is! Map) return;
    final prefs = await SharedPreferences.getInstance();

    if (user['id'] != null) {
      await prefs.setString('user_id', user['id'].toString());
    }
    if (user['email'] != null) {
      await prefs.setString('user_email', user['email'].toString());
    }
    if (user['full_name'] != null) {
      await prefs.setString('user_full_name', user['full_name'].toString());
    }
    if (user['username'] != null) {
      await prefs.setString('user_name', user['username'].toString());
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await _api.post('/auth/forgot-password', {'email': email});
    return (response is Map && response['message'] != null)
        ? response['message'] as String
        : 'Jika email kamu terdaftar, silakan hubungi admin untuk proses reset password.';
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _api.post('/auth/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    if (response is Map && response['success'] == false) {
      throw Exception(response['message'] ?? 'Gagal mengganti password');
    }
  }

  // --- DATA (semua lewat FastAPI) ---

  Future<List<ProductModel>> fetchProductCatalog() async {
    try {
      final List<dynamic> response = await _api.get('/products');
      return response.map((item) => ProductModel.fromMap(item)).toList();
    } catch (e) {
      print('❌ Error Fetch Products: $e');
      return [];
    }
  }

  Future<void> saveScanResult(SkinResultModel result) async {
    try {
      await _api.post('/scans/save', result.toMap());
    } catch (e) {
      print('❌ Gagal simpan scan: $e');
    }
  }
}