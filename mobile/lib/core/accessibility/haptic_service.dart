import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralises haptic feedback so warning/critical safety flags always feel distinctly
/// different from routine UI taps — required by the product spec ("haptic feedback for
/// important warnings"). Falls back to Flutter's built-in HapticFeedback on devices/platforms
/// without a custom-vibration-capable vibrator (iOS, or Android devices lacking amplitude
/// control) so the app never crashes or silently does nothing.
class HapticService {
  bool _hasCustomVibrator = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _hasCustomVibrator = await Vibration.hasVibrator() && await Vibration.hasCustomVibrationsSupport();
    } catch (_) {
      _hasCustomVibrator = false;
    }
  }

  /// Light tap — routine confirmation (button press, navigation).
  Future<void> tap() => HapticFeedback.lightImpact();

  /// Selection change (e.g. switching a toggle, choosing a list item).
  Future<void> selection() => HapticFeedback.selectionClick();

  /// Informational safety flag (e.g. a nutrition threshold note) — a single, gentle pulse.
  Future<void> infoNotice() async {
    if (_hasCustomVibrator) {
      await Vibration.vibrate(duration: 80, amplitude: 100);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Warning-level safety flag (e.g. an unconfirmed possible allergen) — two short pulses.
  Future<void> warning() async {
    if (_hasCustomVibrator) {
      await Vibration.vibrate(pattern: [0, 100, 80, 100], intensities: [0, 180, 0, 180]);
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
    }
  }

  /// Critical safety flag (e.g. a declared allergen matches the user's profile) — a distinct,
  /// longer, more insistent pattern so it cannot be mistaken for routine UI feedback.
  Future<void> critical() async {
    if (_hasCustomVibrator) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200], intensities: [0, 255, 0, 255, 0, 255]);
    } else {
      for (var i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }
}
