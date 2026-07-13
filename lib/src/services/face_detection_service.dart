import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
    ),
  );

  Future<Face?> detectSingleFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) return null;

      faces.sort((a, b) =>
          (b.boundingBox.width * b.boundingBox.height)
              .compareTo(a.boundingBox.width * a.boundingBox.height));

      return faces.first;
    } catch (e) {
      throw Exception("Face detection failed: $e");
    }
  }

  void dispose() {
    _detector.close();
  }
}