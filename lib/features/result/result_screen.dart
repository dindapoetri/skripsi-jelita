import 'package:flutter/material.dart';

import '../../src/constant/app_string.dart';
import '../../src/constant/app_theme.dart';
import '../../data/models/skin_result_models.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skin_result_card.dart';
import '../../src/services/history_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.symptoms,
  });

  final SkinResultModel result;
  final List<String> symptoms;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final HistoryService _historyService = HistoryService();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _autoSave();
  }

  Future<void> _autoSave() async {
    if (_saved) return;
    
    try {
      // Menggabungkan data hasil AI dan pilihan user ke dalam satu model untuk disimpan
      final finalResult = SkinResultModel(
        skinType: widget.result.skinType,
        confidence: widget.result.confidence,
        description: widget.result.description,
        idealIngredients: widget.result.idealIngredients,
        concerns: widget.result.concerns,
        recommendations: widget.result.recommendations,
        probabilities: widget.result.probabilities,
        imagePath: widget.result.imagePath,
        createdAt: widget.result.createdAt,
        symptoms: widget.symptoms, // Menyimpan gejala pilihan user
      );

      await _historyService.saveResult(finalResult);
      if (mounted) {
        setState(() => _saved = true);
      }
      print('✅ Hasil klasifikasi berhasil disimpan dengan symptoms: ${widget.symptoms}');
    } catch (e) {
      print('❌ Error saat menyimpan hasil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan riwayat: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.result),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Menampilkan hasil klasifikasi utama
            SkinResultCard(result: widget.result),

            const SizedBox(height: 16),

            // 2. Menampilkan Kondisi Pilihan User (REVISI: Ukuran Chip Kecil)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kondisi Kulit Pilihanmu:",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.symptoms.map((s) => Chip(
                      label: Text(
                        s, 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AppTheme.background,
                      side: const BorderSide(color: AppTheme.border),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Mengecilkan area box
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // Membuat chip padat
                    )).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Tombol Rekomendasi
            CustomButton(
              label: AppStrings.recommendation,
              icon: Icons.shopping_bag_rounded,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.recommendation,
                  arguments: {
                    'result': widget.result,
                    'symptoms': widget.symptoms,
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // 4. Tombol Kembali
            CustomButton(
              label: 'Kembali ke Beranda',
              outlined: true,
              icon: Icons.home_rounded,
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
