import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one screen currently owning the microphone, so an app-wide gesture can hand control back
/// to it without knowing which screen it is.
///
/// Every hands-free screen registers its own "start listening again" callback here as it takes
/// the foreground (see HandsFreeLoopMixin). The app-level gesture layer in app.dart then has a
/// single thing to call: whatever the user is looking at — or rather, listening to — re-opens
/// its microphone with the right command vocabulary already in place.
class ActiveVoiceScreen {
  VoidCallback? _onRequestListen;
  Object? _owner;

  /// [owner] is the registering State object, so a screen being disposed after a new one has
  /// already claimed the microphone cannot clear its successor's callback.
  void register(Object owner, VoidCallback onRequestListen) {
    _owner = owner;
    _onRequestListen = onRequestListen;
  }

  void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onRequestListen = null;
  }

  bool get hasListener => _onRequestListen != null;

  /// Returns false when no screen is listening (e.g. during boot), so the caller can fall back
  /// to saying something useful rather than doing nothing at all.
  bool requestListen() {
    final callback = _onRequestListen;
    if (callback == null) return false;
    callback();
    return true;
  }
}

final activeVoiceScreenProvider = Provider<ActiveVoiceScreen>((ref) => ActiveVoiceScreen());
