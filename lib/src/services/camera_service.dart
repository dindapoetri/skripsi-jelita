import 'package:image_picker/image_picker.dart';

// file camera_Service.dart
class CameraService {
  final ImagePicker _picker = ImagePicker();
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
