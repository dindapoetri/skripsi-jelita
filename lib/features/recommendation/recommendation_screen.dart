import 'dart:io';
import 'package:flutter/material.dart';

import '../../src/constant/app_theme.dart';
import '../../src/constant/app_string.dart';
import '../../src/services/cbf_service.dart';
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
  bool _isError = false;
  String? _errorMessage;

  String _selectedCategory = 'toner';

  final List<Map<String, String>> _categories = [
    {'id': 'facial_wash', 'label': 'Facial Wash'},
    {'id': 'toner', 'label': 'Toner'},
    {'id': 'moisturizer', 'label': 'Moisturizer'},
    {'id': 'sunscreen', 'label': 'Sunscreen'},
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final results = await _recommender.recommendCategorized(
        widget.result,
        symptoms: widget.symptoms,
      );

      if (!mounted) return;

      setState(() {
        _categorizedRecommendations = results;
        _isLoading = false;
      });
    } on RecommendationAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat rekomendasi"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations =
        _categorizedRecommendations[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recommendation),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())

            : _isError
            ? _buildErrorView()

            : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildHomeButton(),
            const SizedBox(height: 24),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildRecommendationList(recommendations),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Terjadi kesalahan",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendations,
              child: const Text("Coba Lagi"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Image.file(
        File(widget.result.imagePath),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          color: Colors.grey[200],
          child: const Icon(
            Icons.image_not_supported,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil Kulit',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Tipe: ${widget.result.skinType}'),
          const SizedBox(height: 4),
          Text(
            'Gejala: ${widget.symptoms.isEmpty ? "-" : widget.symptoms.join(", ")}',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return CustomButton(
      label: 'Kembali ke Beranda',
      icon: Icons.home_rounded,
      outlined: true,
      onPressed: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
              (route) => false,
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Kategori',
            style: Theme.of(context).textTheme.titleLarge),
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
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat['id']!;
                    });
                  },
                  selectedColor: AppTheme.primarySoft,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationList(
      List<RecommendationModel> recommendations) {
    if (recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("Tidak ada produk yang cocok"),
        ),
      );
    }

    return Column(
      children: recommendations
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ProductCard(recommendation: item),
        ),
      )
          .toList(),
    );
  }
}