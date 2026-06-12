class ApiConstant {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Duration timeout = Duration(seconds: 15);
}

class SupabaseConfig {
  static const String url = 'https://pdnmqrzpswlgouvzxtej.supabase.co';
  // Note: Gunakan Anon Key dari Dashboard Supabase Anda (Settings > API)
  static const String anonKey = 'sb_publishable_dPYBrxA-11Xx4zTOsM34Ew_Xn68bM9Q';
}

class ModelConstant {
  static const String modelAssetPath = 'lib/data/assets/models/cnn/mobilenetv3_skintype_90.ptl';
  static const String labelsAssetPath = 'lib/data/assets/labels/labels.txt';
}
