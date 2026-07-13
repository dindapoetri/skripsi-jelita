import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();

    debugPrint("📍 RESULT SCREEN OPENED");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("🔐 TOKEN (INIT RESULT SCREEN): ${prefs.getString('access_token')}");

      if (!widget.isFromHistory) {
        _autoSave();
      } else {
        setState(() => _saved = true);
      }
    });
  }

  Future<void> _autoSave() async {
    debugPrint("🚀 AUTO SAVE STARTED");

    final prefs = await SharedPreferences.getInstance();
    debugPrint("🔐 TOKEN (BEFORE SAVE): ${prefs.getString('access_token')}");

    if (_saved || _saving) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      String finalImagePath = widget.result.imagePath;

      debugPrint("📦 IMAGE PATH: ${widget.result.imagePath}");
      debugPrint("📦 SYMPTOMS: ${widget.symptoms}");
      debugPrint("📤 UPLOAD IMAGE START");

      if (widget.result.imagePath.isEmpty) {
        throw Exception("Image path kosong");
      }

      final uploadedUrl =
      await _historyService.uploadImage(widget.result.imagePath);

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalImagePath = uploadedUrl;
        debugPrint("✅ UPLOAD SUCCESS: $uploadedUrl");
      } else {
        debugPrint("⚠️ UPLOAD FAILED, USING LOCAL PATH");
      }

      final finalResult = SkinResultModel(
        skinType: widget.result.skinType,
        confidence: widget.result.confidence,
        description: widget.result.description,
        idealIngredients: widget.result.idealIngredients,
        concerns: widget.result.concerns,
        recommendations: widget.result.recommendations,
        probabilities: widget.result.probabilities,
        imagePath: finalImagePath,
        createdAt: widget.result.createdAt,
        symptoms: widget.symptoms,
      );

      await _historyService.saveResult(finalResult);

      if (!mounted) return;

      setState(() {
        _saved = true;
      });

      final prefsAfter = await SharedPreferences.getInstance();
      debugPrint("🔐 TOKEN (AFTER SAVE): ${prefsAfter.getString('access_token')}");
      debugPrint("✅ HISTORY SAVE SUCCESS");
    } catch (e) {
      debugPrint("❌ AUTO SAVE ERROR: $e");

      final prefs = await SharedPreferences.getInstance();
      debugPrint("🔐 TOKEN (ON ERROR): ${prefs.getString('access_token')}");

      if (!mounted) return;

      setState(() {
        _saveError = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("📊 BUILD RESULT SCREEN");

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

            const SizedBox(height: 12),

            if (_saving) const LinearProgressIndicator(),

            if (_saved)
              const Text(
                "✔ Hasil tersimpan",
                style: TextStyle(color: Colors.green),
              ),

            if (_saveError != null)
              Text(
                "⚠ Gagal menyimpan: $_saveError",
                style: const TextStyle(color: Colors.red),
              ),

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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.symptoms
                        .map(
                          (s) => Chip(label: Text(s)),
                    )
                        .toList(),
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