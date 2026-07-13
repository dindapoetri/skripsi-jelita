// clahe_processor.dart
//
// Implementasi CLAHE (Contrast Limited Adaptive Histogram Equalization)
// murni Dart, memakai package `image` (https://pub.dev/packages/image).
//
// Tujuan: menyamakan preprocessing pencahayaan antara notebook training
// (yang pakai cv2.createCLAHE() pada channel L / LAB colorspace) dengan
// pipeline inference di Flutter, supaya tidak terjadi train-inference
// mismatch yang menyebabkan hasil prediksi tidak stabil antar-take.
//
// Pendekatan: karena konversi RGB<->LAB penuh cukup berat untuk dihitung
// manual di Dart, dipakai pendekatan luminance-preserving color:
// 1. Hitung luminance (grayscale) tiap pixel.
// 2. Terapkan CLAHE (tile-based adaptive histogram equalization + clip)
//    pada luminance.
// 3. Terapkan rasio perubahan luminance (baru/lama) ke channel R, G, B
//    asli agar warna kulit tidak berubah drastis, hanya kontras &
//    pencahayaannya yang dinormalisasi -- efeknya sangat mirip dengan
//    CLAHE pada channel L di LAB colorspace.
//
// Cara pakai (lihat juga integration_example.dart):
//
//   final clahe = ClaheProcessor(tileSize: 8, clipLimit: 2.0);
//   final img.Image normalized = clahe.apply(croppedFaceImage);
//   // lanjut ke resize 224x224 + normalize ImageNet + kirim ke pytorch_lite

import 'dart:math';
import 'package:image/image.dart' as img;

class ClaheProcessor {
  /// Ukuran tile (grid) untuk adaptive histogram equalization.
  /// Default 8 -> setara dengan tileGridSize=(8,8) di cv2.createCLAHE().
  final int tileSize;

  /// Batas clip histogram, mencegah over-amplifikasi noise di area gelap/terang.
  /// Default 2.0 -> setara dengan clipLimit=2.0 di cv2.createCLAHE().
  final double clipLimit;

  ClaheProcessor({this.tileSize = 8, this.clipLimit = 2.0});

  /// Menerapkan CLAHE pada [src] dan mengembalikan gambar baru yang sudah
  /// dinormalisasi pencahayaannya. Tidak mengubah ukuran gambar.
  img.Image apply(img.Image src) {
    final width = src.width;
    final height = src.height;

    // 1. Hitung peta luminance (grayscale) untuk seluruh gambar
    final luminance = List<List<int>>.generate(
      height,
          (y) => List<int>.generate(width, (x) {
        final p = src.getPixel(x, y);
        final l = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
        return l.clamp(0, 255);
      }),
    );

    // 2. Bagi jadi tile, hitung histogram per tile, clip, lalu buat mapping (CDF)
    final tilesX = (width / tileSize).ceil();
    final tilesY = (height / tileSize).ceil();
    final mappings = List.generate(
      tilesY,
          (_) => List.generate(tilesX, (_) => List<int>.filled(256, 0)),
    );

    for (int ty = 0; ty < tilesY; ty++) {
      for (int tx = 0; tx < tilesX; tx++) {
        final x0 = tx * tileSize;
        final y0 = ty * tileSize;
        final x1 = min(x0 + tileSize, width);
        final y1 = min(y0 + tileSize, height);

        final hist = List<int>.filled(256, 0);
        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            hist[luminance[y][x]]++;
          }
        }

        // --- Clip histogram & redistribusi kelebihan (inti dari "Contrast Limited") ---
        final numPixels = (x1 - x0) * (y1 - y0);
        if (numPixels == 0) continue;
        final clip = (clipLimit * numPixels / 256).round().clamp(1, numPixels);
        int excess = 0;
        for (int i = 0; i < 256; i++) {
          if (hist[i] > clip) {
            excess += hist[i] - clip;
            hist[i] = clip;
          }
        }
        final redistribute = (excess / 256).floor();
        for (int i = 0; i < 256; i++) {
          hist[i] += redistribute;
        }

        // --- CDF -> mapping function (0-255) ---
        int cdf = 0;
        final mapping = List<int>.filled(256, 0);
        for (int i = 0; i < 256; i++) {
          cdf += hist[i];
          mapping[i] = (cdf * 255 / numPixels).round().clamp(0, 255);
        }
        mappings[ty][tx] = mapping;
      }
    }

    // 3. Interpolasi bilinear antar-tile per pixel (menghindari efek "kotak-kotak"),
    //    lalu terapkan rasio perubahan luminance ke RGB asli
    final out = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final oldL = luminance[y][x];
        final newL = _interpolate(mappings, x, y, tilesX, tilesY, oldL);

        final p = src.getPixel(x, y);
        final ratio = oldL == 0 ? 1.0 : newL / oldL;
        final newR = (p.r * ratio).round().clamp(0, 255);
        final newG = (p.g * ratio).round().clamp(0, 255);
        final newB = (p.b * ratio).round().clamp(0, 255);

        out.setPixelRgb(x, y, newR, newG, newB);
      }
    }
    return out;
  }

  int _interpolate(
      List<List<List<int>>> mappings,
      int x,
      int y,
      int tilesX,
      int tilesY,
      int value,
      ) {
    final tx = x / tileSize - 0.5;
    final ty = y / tileSize - 0.5;

    final tx0 = tx.floor().clamp(0, tilesX - 1);
    final ty0 = ty.floor().clamp(0, tilesY - 1);
    final tx1 = (tx0 + 1).clamp(0, tilesX - 1);
    final ty1 = (ty0 + 1).clamp(0, tilesY - 1);

    final fx = (tx - tx0).clamp(0.0, 1.0);
    final fy = (ty - ty0).clamp(0.0, 1.0);

    final v00 = mappings[ty0][tx0][value];
    final v10 = mappings[ty0][tx1][value];
    final v01 = mappings[ty1][tx0][value];
    final v11 = mappings[ty1][tx1][value];

    final top = v00 * (1 - fx) + v10 * fx;
    final bottom = v01 * (1 - fx) + v11 * fx;
    return (top * (1 - fy) + bottom * fy).round().clamp(0, 255);
  }
}