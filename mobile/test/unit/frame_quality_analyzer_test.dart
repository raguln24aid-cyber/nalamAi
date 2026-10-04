import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalamai_mobile/features/scanner/domain/frame_quality_analyzer.dart';

Uint8List solidFrame(int width, int height, int value) => Uint8List.fromList(
      List.filled(width * height, value),
    );

Uint8List checkerboardFrame(int width, int height) {
  final bytes = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      bytes[y * width + x] = (x % 8 < 4) ? 40 : 220;
    }
  }
  return bytes;
}

void main() {
  final analyzer = FrameQualityAnalyzer();

  test('flags a uniformly dark frame as too dark', () {
    final frame = solidFrame(64, 64, 20);
    final result = analyzer.analyzeLuma(frame, width: 64, height: 64, bytesPerRow: 64);
    expect(result.guidance, FrameGuidance.tooDark);
  });

  test('flags a uniformly bright frame as too bright', () {
    final frame = solidFrame(64, 64, 250);
    final result = analyzer.analyzeLuma(frame, width: 64, height: 64, bytesPerRow: 64);
    expect(result.guidance, FrameGuidance.tooBright);
  });

  test('flags a flat mid-brightness frame (no edges) as too blurry', () {
    final frame = solidFrame(64, 64, 128);
    final result = analyzer.analyzeLuma(frame, width: 64, height: 64, bytesPerRow: 64);
    expect(result.guidance, FrameGuidance.tooBlurry);
  });

  test('accepts a mid-brightness frame with strong high-frequency content as good', () {
    final frame = checkerboardFrame(64, 64);
    final result = analyzer.analyzeLuma(frame, width: 64, height: 64, bytesPerRow: 64);
    expect(result.guidance, FrameGuidance.good);
  });

  test('handles an empty buffer without throwing', () {
    final result = analyzer.analyzeLuma(Uint8List(0), width: 64, height: 64, bytesPerRow: 64);
    expect(result.guidance, FrameGuidance.none);
  });
}
