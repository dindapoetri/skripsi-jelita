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
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    final response = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'full_name': name,
    });
    // Auto-login setelah register jika backend langsung return token
    if (response != null && response['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', {'email': email});
  }

  Future<void> updatePassword(String newPassword) async {
    await _api.post('/auth/update-password', {'new_password': newPassword});
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
