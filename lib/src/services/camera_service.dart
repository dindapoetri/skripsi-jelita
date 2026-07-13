import 'package:image_picker/image_picker.dart';

// file camera_Service.dart
class CameraService {
  final ImagePicker _picker = ImagePicker();

  // [DIUBAH] maxWidth dinaikkan dari 1280 -> 2400.
  //
  // Alasan: sebelumnya foto sudah di-downscale ke 1280px SEBELUM face
  // detection/crop dilakukan. Setelah wajah di-crop (area wajah biasanya
  // cuma sebagian kecil dari frame), resolusi efektif area wajah jadi kecil
  // sekali -- detail halus seperti tekstur/bintik jerawat (fitur lokal,
  // beda dengan oily/dry yang fiturnya lebih global/menyebar) hilang duluan
  // di tahap ini, sebelum sempat diproses CLAHE atau masuk ke model.
  //
  // 2400px cukup memberi "ruang" bagi area wajah hasil crop untuk tetap
  // punya detail memadai saat di-resize ke 224x224 untuk model, tanpa
  // membuat file mentah jadi terlalu besar untuk diproses di HP.
  static const int _captureMaxWidth = 2400;
  static const int _captureQuality = 92;

  Future<String?> captureFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: _captureQuality,
        maxWidth: _captureMaxWidth.toDouble(),
      );

      if (file == null) return null;

      if (await file.length() <= 0) {
        throw Exception("Captured image is empty");
      }

      return file.path;
    } catch (e) {
      throw Exception("Camera error: $e");
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _captureQuality,
        maxWidth: _captureMaxWidth.toDouble(),
      );

      if (file == null) return null;

      if (await file.length() <= 0) {
        throw Exception("Selected image is empty");
      }

      return file.path;
    } catch (e) {
      throw Exception("Gallery error: $e");
    }
  }
}

// -----------------------------------------------------------------------
// CATATAN: file hasil capture ini kepakai untuk 2 hal sekaligus di kode
// kamu -- (1) input klasifikasi model, (2) file yang diupload ke Supabase
// (lihat log: path yang sama dipakai untuk classifySkin() maupun upload).
//
// Konsekuensi dari menaikkan resolusi ini: ukuran file yang diupload ke
// Supabase juga ikut lebih besar (sebelumnya ~300KB, sekarang mungkin naik
// ke ~600KB-1MB tergantung kompleksitas foto). Untuk skala skripsi/prototype
// ini biasanya masih wajar.
//
// Kalau nanti mau dioptimalkan lebih jauh (resolusi tinggi khusus untuk
// model, tapi file upload tetap kecil untuk hemat storage/bandwidth),
// caranya: pisahkan jadi 2 file -- capture di resolusi tinggi untuk
// classifySkin(), lalu buat 1 copy terkompresi terpisah khusus untuk
// upload (pakai package `image`, resize+encodeJpg dengan quality lebih
// rendah) sebelum dikirim ke Supabase. Beri tahu saya kalau mau saya
// bantu implementasikan pemisahan ini.
// -----------------------------------------------------------------------