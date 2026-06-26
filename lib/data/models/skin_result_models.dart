import 'dart:convert';

class SkinResultModel {
  final String skinType;
  final double confidence;
  final String description;
  final List<String> idealIngredients;
  final List<String> concerns;
  final List<String> recommendations;
  final Map<String, double> probabilities;
  final String imagePath; // lokal / fallback storage path
  final String imageUrl;  // server
  final DateTime createdAt;
  final List<String> symptoms;

  const SkinResultModel({
    required this.skinType,
    required this.confidence,
    required this.description,
    required this.idealIngredients,
    required this.concerns,
    required this.recommendations,
    required this.probabilities,
    this.imagePath = '',
    this.imageUrl = '',
    required this.createdAt,
    this.symptoms = const [],
  });

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  Map<String, dynamic> toMap() {
    return {
      'skin_type': skinType,
      'confidence_score': confidence,
      'description': description,
      'ideal_ingredients': idealIngredients,
      'concerns': concerns,
      'recommendations': recommendations,
      'probabilities': probabilities,
      'image_path': imagePath,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'detected_symptoms': symptoms,
    };
  }

  factory SkinResultModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic data) {
      if (data == null) return [];

      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }

      if (data is String) {
        if (data.trim().isEmpty) return [];

        // kalau list dikirim sebagai JSON string: '["a","b"]'
        if (data.trim().startsWith('[') && data.trim().endsWith(']')) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is List) {
              return decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }

        return data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      return [];
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      return <String, dynamic>{};
    }

    String pickFirstString(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    final faceCapture = asMap(map['face_capture']);
    final resultMap = asMap(map['result']);
    final dataMap = asMap(map['data']);

    return SkinResultModel(
      skinType: pickFirstString([
        map['skin_type'],
        map['skinType'],
        resultMap['skin_type'],
        resultMap['skinType'],
        'Unknown',
      ]),
      confidence: parseDouble(
        map['confidence_score'] ??
            map['confidence'] ??
            resultMap['confidence_score'] ??
            resultMap['confidence'],
      ),
      description: pickFirstString([
        map['description'],
        resultMap['description'],
      ]),
      concerns: parseList(
        map['concerns'] ?? resultMap['concerns'],
      ),
      idealIngredients: parseList(
        map['ideal_ingredients'] ??
            map['idealIngredients'] ??
            resultMap['ideal_ingredients'] ??
            resultMap['idealIngredients'],
      ),
      recommendations: parseList(
        map['recommendations'] ?? resultMap['recommendations'],
      ),
      probabilities: ((map['probabilities'] ?? resultMap['probabilities']) is Map)
          ? ((map['probabilities'] ?? resultMap['probabilities']) as Map)
          .map((k, v) => MapEntry(k.toString(), parseDouble(v)))
          : {},
      imagePath: pickFirstString([
        map['image_path'],
        map['imagePath'],
        map['storage_path'],
        map['storagePath'],
        faceCapture['image_path'],
        faceCapture['imagePath'],
        faceCapture['storage_path'],
        faceCapture['storagePath'],
        resultMap['image_path'],
        resultMap['imagePath'],
        resultMap['storage_path'],
        resultMap['storagePath'],
        dataMap['image_path'],
        dataMap['imagePath'],
        dataMap['storage_path'],
        dataMap['storagePath'],
      ]),
      imageUrl: pickFirstString([
        map['image_url'],
        map['imageUrl'],
        faceCapture['image_url'],
        faceCapture['imageUrl'],
        resultMap['image_url'],
        resultMap['imageUrl'],
        dataMap['image_url'],
        dataMap['imageUrl'],
      ]),
      createdAt: DateTime.tryParse(
        pickFirstString([
          map['created_at'],
          map['createdAt'],
          resultMap['created_at'],
          resultMap['createdAt'],
        ]),
      ) ??
          DateTime.now(),
      symptoms: parseList(
        map['detected_symptoms'] ??
            map['symptoms'] ??
            resultMap['detected_symptoms'] ??
            resultMap['symptoms'],
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SkinResultModel.fromJson(String source) =>
      SkinResultModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}