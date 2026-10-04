import 'dart:typed_data';
import 'package:camera/camera.dart';

enum FrameGuidance {
  good,
  tooDark,
  tooBright,
  tooBlurry,
  none, // not enough signal yet (e.g. very first frames)
}

class FrameQuality {
  final double averageBrightness; // 0..255
  final double sharpness; // relative gradient-energy score, unbounded but typically 0..~40
  final FrameGuidance guidance;

  const FrameQuality({
    required this.averageBrightness,
    required this.sharpness,
    required this.guidance,
  });
}

/// Real-time heuristic frame-quality analysis run on the camera preview stream to drive spoken
/// guidance ("too dark", "hold steady") before the user spends a barcode/OCR round trip on a
/// low-quality capture. This is intentionally a lightweight heuristic (mean luma for exposure,
/// a Sobel-style gradient-energy proxy for sharpness) rather than a full CV model, chosen to run
/// on every few preview frames without a native ML dependency. Thresholds were tuned by eye
/// against sample label photos and are conservative (biased toward asking the user to retry
/// rather than accepting a frame OCR is unlikely to read).
class FrameQualityAnalyzer {
  static const double _darkThreshold = 60;
  static const double _brightThreshold = 215;
  static const double _blurThreshold = 6.0;

  /// Downsampling stride — analyzing every pixel of a 1080p frame on every callback would be
  /// too slow for a >1fps guidance loop; every 4th pixel is enough signal for this heuristic.
  static const int _stride = 4;

  FrameQuality? analyzeCameraImage(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first; // Y (luma) plane for YUV420, or the only plane for BGRA8888 alpha-less reads
    return analyzeLuma(
      plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
    );
  }

  /// Pure, testable core: operates directly on a luma byte buffer so it can be unit tested with
  /// synthetic data instead of a real CameraImage.
  FrameQuality analyzeLuma(Uint8List luma, {required int width, required int height, required int bytesPerRow}) {
    var sum = 0;
    var count = 0;
    var gradientEnergy = 0.0;
    var gradientSamples = 0;

    for (var y = 0; y < height; y += _stride) {
      final rowStart = y * bytesPerRow;
      for (var x = 0; x < width - _stride; x += _stride) {
        final idx = rowStart + x;
        if (idx >= luma.length) continue;
        final value = luma[idx];
        sum += value;
        count++;

        final rightIdx = idx + _stride;
        if (rightIdx < luma.length && rightIdx < rowStart + width) {
          final diff = (value - luma[rightIdx]).abs();
          gradientEnergy += diff * diff;
          gradientSamples++;
        }
      }
    }

    if (count == 0) {
      return const FrameQuality(averageBrightness: 0, sharpness: 0, guidance: FrameGuidance.none);
    }

    final brightness = sum / count;
    final sharpness = gradientSamples == 0 ? 0.0 : gradientEnergy / gradientSamples / 40.0;

    final guidance = brightness < _darkThreshold
        ? FrameGuidance.tooDark
        : brightness > _brightThreshold
            ? FrameGuidance.tooBright
            : sharpness < _blurThreshold
                ? FrameGuidance.tooBlurry
                : FrameGuidance.good;

    return FrameQuality(averageBrightness: brightness, sharpness: sharpness, guidance: guidance);
  }
}
