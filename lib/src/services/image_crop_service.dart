import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ImageCropService {
  Future<Uint8List> cropFace({
    required String imagePath,
    required Face face,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception("Failed to decode image");
      }

      final rect = face.boundingBox;

      int x = rect.left.toInt() - 20;
      int y = rect.top.toInt() - 20;
      int w = rect.width.toInt() + 40;
      int h = rect.height.toInt() + 40;

      x = x.clamp(0, decoded.width);
      y = y.clamp(0, decoded.height);
      w = w.clamp(1, decoded.width - x);
      h = h.clamp(1, decoded.height - y);

      final cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      throw Exception("Image crop failed: $e");
    }
  }
}