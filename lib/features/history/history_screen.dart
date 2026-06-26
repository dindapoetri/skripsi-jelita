import 'package:flutter/material.dart';

import '../../src/constant/app_string.dart';
import '../../src/services/history_service.dart';
import '../../data/models/skin_result_models.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skin_result_card.dart';
import '../../routes/app_routes.dart';
import '../../src/constant/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _service = HistoryService();
  late Future<List<SkinResultModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.loadHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _service.loadHistory();
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat klasifikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearHistory();
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.history)),
      body: SafeArea(
        child: FutureBuilder<List<SkinResultModel>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Gagal memuat data: ${snapshot.error}', textAlign: TextAlign.center),
              ));
            }

            final items = snapshot.data ?? <SkinResultModel>[];
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 100),
                    const Icon(Icons.history_toggle_off_rounded, size: 68, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.noHistory,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      label: 'Muat ulang',
                      outlined: true,
                      onPressed: () => _refresh(),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  CustomButton(
                    label: 'Hapus semua riwayat',
                    outlined: true,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _clearHistory(),
                  ),
                  const SizedBox(height: 18),
                  ...items.map(
                        (result) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.result,
                            arguments: {
                              'result': result,
                              'symptoms': result.symptoms, 
                              'isFromHistory': true,
                            },
                          );
                        },
                        child: SkinResultCard(result: result, compact: true),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
