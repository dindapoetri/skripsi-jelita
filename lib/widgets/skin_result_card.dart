import 'dart:io';
import 'package:flutter/material.dart';

import '../../src/constant/app_theme.dart';
import '../src/utils/helper.dart';
import '../data/models/skin_result_models.dart';

class SkinResultCard extends StatelessWidget {
  const SkinResultCard({super.key, required this.result, this.compact = false});

  final SkinResultModel result;
  final bool compact;

  Widget _placeholderWidget() => Container(
    color: AppTheme.primarySoft,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 42),
    ),
  );

  bool get _isNetworkImage =>
      result.displayImage.startsWith('http://') || result.displayImage.startsWith('https://');

  Widget _buildImage() {
    final image = result.displayImage;

    if (image.isEmpty) return _placeholderWidget();

    if (_isNetworkImage) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.primarySoft,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Image.network error: $error');
          return _placeholderWidget();
        },
      );
    }

    final file = File(image);
    if (!file.existsSync()) return _placeholderWidget();

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) {
        debugPrint('Image.file error: $error');
        return _placeholderWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: compact ? 16 / 10 : 16 / 11,
              child: _buildImage(), // ✅ ganti dari logic lama
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        capitalizeWords(result.skinType),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Chip(
                      backgroundColor: AppTheme.primarySoft,
                      side: BorderSide.none,
                      label: Text(
                        result.confidenceLabel,
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (result.description.isNotEmpty) ...[
                  Text(result.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ],
                if (result.idealIngredients.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: result.idealIngredients.map((item) => Chip(
                      label: Text(
                        capitalizeWords(item),
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      backgroundColor: AppTheme.background,
                      side: const BorderSide(color: AppTheme.border),
                    )).toList(),
                  ),
                if (!compact) ...[
                  const SizedBox(height: 16),
                  Text('Rekomendasi singkat', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (result.recommendations.isEmpty)
                    Text(
                      'Tidak ada rekomendasi tersedia.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    ...result.recommendations.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppTheme.success),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    )),
                  const SizedBox(height: 12),
                  Text('Probabilitas model', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (result.probabilities.isEmpty)
                    Text(
                      'Tidak ada data probabilitas.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    ...result.probabilities.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(capitalizeWords(entry.key)),
                              Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: entry.value,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(result.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}