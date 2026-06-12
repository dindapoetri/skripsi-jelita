import 'dart:io';
import 'package:flutter/material.dart';

import '../../src/constant/app_theme.dart';
import '../../src/constant/app_string.dart';
import '../../src/utils/helper.dart';
import '../../src/services/cbf_recommender.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/skin_result_models.dart';
import '../../widgets/product_card.dart';
import '../../widgets/custom_button.dart';
import '../../routes/app_routes.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({
    super.key,
    required this.result,
    required this.symptoms,
  });

  final SkinResultModel result;
  final List<String> symptoms;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final CbfRecommender _recommender = CbfRecommender();
  Map<String, List<RecommendationModel>> _categorizedRecommendations = {};
  bool _isLoading = true;
  String _selectedCategory = 'toner'; // Default ke toner sesuai permintaan

  final List<Map<String, String>> _categories = [
    {'id': 'facial_wash', 'label': 'Facial Wash'},
    {'id': 'toner', 'label': 'Toner'},
    {'id': 'moisturizer', 'label': 'Moisturizer'},
    {'id': 'sunscreen', 'label': 'Sunscreen'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final results = await _recommender.recommendCategorized(
        widget.result,
        symptoms: widget.symptoms,
      );

      setState(() {
        _categorizedRecommendations = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error memproses CBF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _categorizedRecommendations[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recommendation),
        // Icon home dihapus dari sini
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Column(
                children: [
                  Image.file(
                    File(widget.result.imagePath),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.face_retouching_natural, size: 50, color: Colors.grey),
                    ),
                  ),
                  const ListTile(
                    title: Text("Hasil Foto Kulit Wajah Anda", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Analisis berdasarkan foto yang diambil per hari ini."),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profil Kulit', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 8),
                  Text('Tipe Kulit: ${capitalizeWords(widget.result.skinType)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Gejala: ${widget.symptoms.isEmpty ? "-" : widget.symptoms.map((e) => e[0].toUpperCase() + e.substring(1)).join(", ")}',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // FITUR REVISI: Tombol Beranda dipindah ke bawah Profil Kulit
            CustomButton(
              label: 'Kembali ke Beranda',
              icon: Icons.home_rounded,
              outlined: true,
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              ),
            ),

            const SizedBox(height: 24),

            Text('Pilih Kategori', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat['id']!;
                        });
                      },
                      selectedColor: AppTheme.primarySoft,
                      checkmarkColor: AppTheme.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Top 5 ${_categories.firstWhere((c) => c['id'] == _selectedCategory)['label']}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recommendations.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("Maaf, tidak ada produk yang cocok."),
              ))
            else
              ...recommendations.map(
                    (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ProductCard(recommendation: recommendation),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
