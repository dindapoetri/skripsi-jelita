import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/skin_result_models.dart';
import '../../data/models/product_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- AUTENTIKASI ---
  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String name) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // --- DATABASE ---
  Future<List<ProductModel>> fetchProductCatalog() async {
    try {
      final List<dynamic> response = await _supabase.from('products').select();
      return response.map((item) => ProductModel.fromMap(item)).toList();
    } catch (e) {
      print('Error fetch products: $e');
      return [];
    }
  }

  Future<void> saveScanResult(SkinResultModel result) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _supabase.from('classification_results').insert({
        'user_id': user.id,
        'skin_type': result.skinType,
        'confidence_score': result.confidence,
        'short_recommendation': result.description,
        'idealingredients': result.idealIngredients,
        'concerns': result.concerns,
        'recommendations': result.recommendations,
        'probabilities': result.probabilities,
        'image_path': result.imagePath,
        'detected_symptoms': result.symptoms,
        'created_at': DateTime.now().toIso8601String(),
      });
      print("✅ Riwayat berhasil disimpan ke Supabase");
    } catch (e) {
      print('❌ Error DB Supabase: $e');
    }
  }
}
