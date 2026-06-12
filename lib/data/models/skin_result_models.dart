import 'dart:convert';

class SkinResultModel {
  final String skinType;
  final double confidence;
  final String description;
  final List<String> idealIngredients;
  final List<String> concerns;
  final List<String> recommendations;
  final Map<String, double> probabilities;
  final String imagePath;
  final DateTime createdAt;
  final List<String> symptoms; // Tambahkan untuk menyimpan pilihan ciri-ciri kulit user

  const SkinResultModel({
    required this.skinType,
    required this.confidence,
    required this.description,
    required this.idealIngredients,
    required this.concerns,
    required this.recommendations,
    required this.probabilities,
    required this.imagePath,
    required this.createdAt,
    this.symptoms = const [],
  });

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toMap() {
    return {
      'skin_type': skinType,
      'confidence_score': confidence,
      'short_recommendation': description,
      'concerns': concerns,
      'idealingredients': idealIngredients,
      'recommendations': recommendations,
      'probabilities': probabilities,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'detected_symptoms': symptoms,
    };
  }

  factory SkinResultModel.fromMap(Map<String, dynamic> map) {
    return SkinResultModel(
      skinType: (map['skin_type'] ?? map['skinType'] ?? 'Unknown').toString(),
      confidence: (map['confidence_score'] ?? map['confidence'] ?? 0.0).toDouble(),
      description: (map['short_recommendation'] ?? map['description'] ?? '').toString(),
      idealIngredients: List<String>.from(map['idealingredients'] ?? map['ideal_ingredients'] ?? map['idealIngredients'] ?? []),
      concerns: List<String>.from(map['concerns'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      probabilities: (map['probabilities'] is Map)
          ? (map['probabilities'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()))
          : {},
      imagePath: (map['image_path'] ?? map['imagePath'] ?? '').toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      symptoms: List<String>.from(map['detected_symptoms'] ?? map['symptoms'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SkinResultModel.fromJson(String source) =>
      SkinResultModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
