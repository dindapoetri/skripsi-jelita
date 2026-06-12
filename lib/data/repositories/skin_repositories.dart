class SkinProfile {
  final String label;
  final String title;
  final String description;
  final List<String> concerns;
  final List<String> recommendations;
  final List<String> idealIngredients;

  const SkinProfile({
    required this.label,
    required this.title,
    required this.description,
    required this.concerns,
    required this.recommendations,
    required this.idealIngredients,
  });
}

class SkinRepository {
  static const List<String> skinLabels = <String>[
    'normal',
    'oily',
    'dry',
    'combination',
    'acne',
  ];

  // Mapping dari label display -> term yang ada di vocabulary CBF/Colab
  static const Map<String, String> concernsVocabMap = {
    'Jerawat': 'acne',
    'Komedo': 'pores',
    'Kulit Kusam': 'dullness',
    'Kulit Kering': 'dry',
    'Berminyak': 'oily',
    'Kulit Sensitif': 'sensitive',
    'Anti Aging': 'anti_aging',
    'Cerah': 'brightening',
    'Hidrasi': 'hydration',
  };

  // Konversi concerns display ke vocabulary term sebelum masuk CBF
  static List<String> toVocabTerms(List<String> displayConcerns) {
    return displayConcerns
        .map((c) => concernsVocabMap[c] ?? c.toLowerCase())
        .toList();
  }

  static const Map<String, SkinProfile> _profiles = {
    // Text string untuk kulit normal yang akan tampil pada hasil klasifikasi
    'normal': SkinProfile(
      label: 'normal',
      title: 'Kulit Normal',
      description:
      'Kulit relatif seimbang, tidak terlalu berminyak dan tidak terlalu kering.',
      concerns: ['seimbang', 'skin barrier normal'],
      recommendations: [
        'Pakai cleanser lembut dua kali sehari.',
        'Aplikasikan toner dengan kandungan ringan.',
        'Gunakan moisturizer ringan untuk menjaga kelembapan.',
        'Tetap pakai sunscreen setiap pagi.',
      ],
      idealIngredients: ['niacinamide', 'hyaluronic acid', 'ceramide'],
    ),
    // Text string untuk kulit berminyak yang akan tampil pada hasil klasifikasi
    'oily': SkinProfile(
      label: 'oily',
      title: 'Kulit Berminyak',
      description:
      'Produksi sebum cenderung tinggi sehingga wajah cepat mengilap dan pori lebih terlihat.',
      concerns: ['minyak berlebih', 'pori besar', 'jerawat'],
      recommendations: [
        'Pilih pembersih dengan kontrol sebum.',
        'Gunakan serum niacinamide atau salicylic acid.',
        'Hindari pelembap yang terlalu berat.',
      ],
      idealIngredients: ['salicylic acid', 'niacinamide', 'zinc', 'clay'],
    ),
    // Text string untuk kulit berminyak yang akan tampil pada hasil klasifikasi
    'dry': SkinProfile(
      label: 'dry',
      title: 'Kulit Kering',
      description:
      'Kulit terasa ketarik, mudah kusam, dan sering membutuhkan hidrasi tambahan.',
      concerns: ['dehidrasi', 'kulit kasar', 'skin barrier lemah'],
      recommendations: [
        'Gunakan cleanser yang tidak membuat kulit terasa kering.',
        'Prioritaskan pelembap dengan ceramide dan humektan.',
        'Tambahkan layer hidrasi seperti toner/essence.',
      ],
      idealIngredients: ['ceramide', 'glycerin', 'hyaluronic acid', 'panthenol'],
    ),
    'combination': SkinProfile(
      label: 'combination',
      title: 'Kulit Kombinasi',
      description:
      'Bagian T-zone cenderung berminyak, sedangkan area pipi lebih normal atau kering.',
      concerns: ['minyak di t-zone', 'pipi kering', 'tekstur tidak merata'],
      recommendations: [
        'Gunakan produk balance oil tanpa mengeringkan seluruh wajah.',
        'Fokus pelembap ringan di area berminyak dan hidrasi ekstra di area kering.',
        'Pilih eksfoliasi yang lembut dan terukur.',
      ],
      idealIngredients: ['niacinamide', 'centella', 'hyaluronic acid'],
    ),
    'acne': SkinProfile(
      label: 'acne',
      title: 'Kulit Berjerawat',
      description:
      'Kulit dengan kondisi peradangan aktif, komedo, atau noda bekas jerawat yang meradang.',
      concerns: ['jerawat aktif', 'kemerahan', 'pori tersumbat'],
      recommendations: [
        'Gunakan pembersih pH seimbang.',
        'Fokus pada bahan penenang dan anti-inflamasi.',
        'Jangan memencet jerawat untuk menghindari bekas permanen.',
      ],
      idealIngredients: ['salicylic acid', 'tea tree', 'centella', 'niacinamide'],
    ),
  };

  SkinProfile profileFor(String skinType) {
    final normalized = skinType.toLowerCase();
    return _profiles[normalized] ?? _profiles['normal']!;
  }

  List<String> concernsFor(String skinType) => profileFor(skinType).concerns;

  List<String> recommendationsFor(String skinType) =>
      profileFor(skinType).recommendations;

  List<String> idealIngredientsFor(String skinType) =>
      profileFor(skinType).idealIngredients;
}
