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
    this.isFromHistory = false,
  });

  final SkinResultModel result;
  final List<String> symptoms;
  final bool isFromHistory;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final HistoryService _historyService = HistoryService();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isFromHistory) {
      _autoSave();
    } else {
      _saved = true;
    }
  }

  Future<void> _autoSave() async {
    if (_saved) return;

    try {
      // ✅ BARU: upload gambar lokal dulu, dapatkan image_url dari Supabase Storage
      String finalImagePath = widget.result.imagePath;
      final uploadedUrl = await _historyService.uploadImage(widget.result.imagePath);
      if (uploadedUrl != null) {
        finalImagePath = uploadedUrl;
        debugPrint('✅ Gambar berhasil diupload: $uploadedUrl');
      } else {
        debugPrint('⚠️ Upload gambar gagal/dilewati, lanjut simpan tanpa image_url baru');
      }

      final finalResult = SkinResultModel(
        skinType: widget.result.skinType,
        confidence: widget.result.confidence,
        description: widget.result.description,
        idealIngredients: widget.result.idealIngredients,
        concerns: widget.result.concerns,
        recommendations: widget.result.recommendations,
        probabilities: widget.result.probabilities,
        imagePath: finalImagePath, // ✅ pakai URL hasil upload (atau path lokal kalau upload gagal)
        createdAt: widget.result.createdAt,
        symptoms: widget.symptoms,
      );

      await _historyService.saveResult(finalResult);
      if (mounted) setState(() => _saved = true);
      debugPrint('✅ Transaksi riwayat berhasil melalui FastAPI');
    } catch (e) {
      debugPrint('❌ Gagal transaksi riwayat: $e');
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
            SkinResultCard(result: widget.result),
            const SizedBox(height: 16),
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
                      label: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                      backgroundColor: AppTheme.background,
                      side: const BorderSide(color: AppTheme.border),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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