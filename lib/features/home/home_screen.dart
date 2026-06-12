import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../src/constant/app_string.dart';
import '../../src/services/camera_service.dart';
import '../../src/constant/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  bool _isProcessing = false;
  String _userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pengguna';
    });
  }

  Future<void> _processImage(Future<String?> Function() picker) async {
    setState(() => _isProcessing = true);
    try {
      final imagePath = await picker();
      if (imagePath == null) return;
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.symptoms, arguments: imagePath);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, $_userName!',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary)),
                        Text(AppStrings.appIntro, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.history),
                        icon: const Icon(Icons.history_rounded,
                            color: AppTheme.primary),
                        style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primarySoft),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.profile),
                        icon: const Icon(Icons.person_rounded,
                            color: AppTheme.primary),
                        style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primarySoft),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF245C50), Color(0xFFFA3D66)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.face_retouching_natural_rounded,
                        color: Colors.white, size: 42),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.homeHeroTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildStepCard(context, '01', 'Ambil foto wajah',
                  'Gunakan kamera depan agar wajah lebih mudah dibaca.'),
              _buildStepCard(context, '02', 'Pilih kondisi',
                  'Pilih gejala atau kondisi kulit yang sedang Anda alami.'),
              _buildStepCard(context, '03', 'Rekomendasi',
                  'Lihat hasil klasifikasi kulitmu dan produk yang disarankan.'),
              const SizedBox(height: 24),
              CustomButton(
                label: AppStrings.captureButton,
                icon: Icons.camera_alt_rounded,
                isLoading: _isProcessing,
                onPressed: () => _processImage(_cameraService.captureFromCamera),
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: AppStrings.galleryButton,
                icon: Icons.photo_library_rounded,
                outlined: true,
                isLoading: _isProcessing,
                onPressed: () => _processImage(_cameraService.pickFromGallery),
              ),
              const SizedBox(height: 24),
              Text('Artikel Terbaru', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const ArticlePage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, String index, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              backgroundColor: AppTheme.primarySoft,
              foregroundColor: AppTheme.primary,
              child: Text(index, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = [
      {
        'image': 'assets/images/skincare-image-1.jpg',
        'title': 'Tips konsisten buat kamu yang males skincare',
        'description': 'Lorem ipsum dolor sit amet consectetur adipiscing elit. Batagor siomay lumpia basah bakwan goreng.',
      },
      {
        'image': 'assets/images/skincare-image-2.jpg',
        'title': 'Cara wajah glowing alami setiap hari',
        'description': 'Lorem ipsum dolor sit amet consectetur adipiscing elit.',
      },
    ];

    return Column(
      children: articles.map((article) {
        final words = article['description']!.split(' ');
        final displayDescription = words.length > 5 ? '${words.take(5).join(' ')}...' : article['description']!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ArticleSkins(image: article['image']!, title: article['title']!, description: displayDescription),
        );
      }).toList(),
    );
  }
}

class _ArticleSkins extends StatelessWidget {
  const _ArticleSkins({required this.image, required this.title, required this.description});
  final String image, title, description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 120,
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 8),
                    Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
