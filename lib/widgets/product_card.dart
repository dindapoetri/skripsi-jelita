import 'package:flutter/material.dart';

import '../src/utils/helper.dart';
import '../data/models/recommendation_model.dart';
import '../../src/constant/app_theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.recommendation});

  final RecommendationModel recommendation;

  @override
  Widget build(BuildContext context) {
    final product = recommendation.product;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Nama & Skor
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.brand} • ${capitalizeWords(product.category.replaceAll("_", " "))}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recommendation.score.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DESKRIPSI PRODUK
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              product.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),

          // INFO TAMBAHAN (Hasil Colab Feature #5)
          if (product.suitableFor != null && product.suitableFor!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cocok untuk:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(product.suitableFor!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.all(20),
            child: Divider(height: 1),
          ),

          // FOOTER: Kenapa dipilih & Cara pakai
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation.rationale,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                if (product.usageSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text("Cara Pakai:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...product.usageSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text("• $step", style: theme.textTheme.bodySmall),
                  )),
                ],
                const SizedBox(height: 12),
                // Text(
                //   "Estimasi: ${product.priceRange}",
                //   style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[500]),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
