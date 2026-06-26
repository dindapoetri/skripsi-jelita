class ApiConstant {
  // IP 10.0.2.2 agar emulator Android bisa akses localhost laptop
  // NANTI GANTI SAMA YANG UDAH DIPINDAHIN KE RAILWAY
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Duration timeout = Duration(seconds: 15);
}

class SupabaseConfig {
  static const String url = 'https://pdnmqrzpswlgouvzxtej.supabase.co';
  // Anon Key tetap dibutuhkan oleh SDK klien untuk manajemen session token
  static const String anonKey = 'sb_publishable_dPYBrxA-11Xx4zTOsM34Ew_Xn68bM9Q';
}

class ModelConstant {
  static const String modelAssetPath = 'assets/models/cnn/mobilenetv3_skintype_90.ptl';
  static const String labelsAssetPath = 'assets/labels/labels.txt';
}
