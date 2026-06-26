import 'package:flutter/material.dart';
import '../../src/services/pytorch_service.dart';
import '../../widgets/custom_button.dart';
import '../../routes/app_routes.dart';

class SkinSymptomsScreen extends StatefulWidget {
  final String imagePath;

  const SkinSymptomsScreen({super.key, required this.imagePath});

  @override
  State<SkinSymptomsScreen> createState() => _SkinSymptomsScreenState();
}

class _SkinSymptomsScreenState extends State<SkinSymptomsScreen> {
  final PyTorchService _classifier = PyTorchService();
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _symptoms = [
    {'id': 'jerawat', 'label': 'Berjerawat'}, // jerawat
    {'id': 'dehidrasi', 'label': 'Kulit Kering'}, // kering
    {'id': 'minyak berlebih', 'label': 'Berminyak'}, // berminyak
    {'id': 'kemerahan', 'label': 'Kemerahan'}, // kemerahan
    {'id': 'kulit kusam', 'label': 'Kusam'}, //kusam
    {'id': 'noda bekas jerawat', 'label': 'Bekas Jerawat'}, // bekas jerawat
    {'id': 'pori besar', 'label': 'Pori-Pori'}, //pori pori
    {'id': 'anti penuaan dini', 'label': 'Garis Halus'}, // kerutan
    {'id': 'komedo', 'label': 'Komedo'}, // komedo
    {'id': 'pipi kering', 'label': 'Pipi Kering'},
    {'id': 't-zone', 'label': 'Berminyak (T-Zone)'}, // t-zone
    {'id': 'meradang', 'label': 'Jerawat Meradang'}, // jerawat radang
    {'id': 'tidak ada', 'label': 'Tidak Ada'},
  ];

  final Set<String> _selectedIds = {};

  Future<void> _processAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      // 1. Jalankan Klasifikasi AI (CNN)
      final result = await _classifier.classifySkin(widget.imagePath);
      
      if (!mounted) return;

      // 2. Pindah ke Hasil dengan membawa data AI + Pilihan User
      Navigator.pushNamed(
        context,
        AppRoutes.result,
        arguments: {
          'result': result,
          'symptoms': _selectedIds.toList(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Kondisi Kulit"),
        automaticallyImplyLeading: false, // Menghilangkan tombol back otomatis
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apa yang kamu rasakan saat ini?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Pilihanmu membantu kami memberikan rekomendasi yang lebih personal."),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _symptoms.map((item) {
                    final isSelected = _selectedIds.contains(item['id']);
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 50) / 2,
                      height: 50,
                      child: FilterChip(
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            item['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            selected ? _selectedIds.add(item['id']) : _selectedIds.remove(item['id']);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: "Lihat Hasil Analisis",
              isLoading: _isLoading,
              onPressed: _selectedIds.isEmpty ? null : _processAndNavigate,
            ),
          ],
        ),
      ),
    );
  }
}
