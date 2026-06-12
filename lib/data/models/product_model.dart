class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final List<String> suitableSkinTypes;
  final List<String> concerns;
  final List<String> ingredients;
  final List<String> usageSteps;
  final String priceRange;
  final String? imageUrl;
  final String? suitableFor;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.suitableSkinTypes,
    required this.concerns,
    required this.ingredients,
    required this.usageSteps,
    required this.priceRange,
    this.imageUrl,
    this.suitableFor,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Fungsi helper untuk menangani data yang bisa berupa String (koma) atau List
    List<String> parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return List<String>.from(data);
      if (data is String) return data.split(',').map((e) => e.trim()).toList();
      return [];
    }

    return ProductModel(
      id: map['id'].toString(),
      name: map['product_name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      suitableSkinTypes: parseList(map['suitable_skin_types']),
      concerns: parseList(map['concerns']),
      ingredients: parseList(map['ingredients']),
      usageSteps: parseList(map['usage_steps']),
      priceRange: map['price_range'] ?? '',
      imageUrl: map['image_url'],
      suitableFor: map['suitable_for'],
    );
  }
}
