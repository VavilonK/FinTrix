import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One playback of an Animated WebP clip with its current decoded frame.
///
/// Sessions are single-use: a one-shot clip restarts by taking a new session,
/// which ImageCache-shared completers cannot do once they have finished.
class PetClipSession {
  PetClipSession._(this.asset, this._codec, this._frame);

  final String asset;
  final ui.Codec _codec;
  ui.FrameInfo _frame;
  Future<ui.FrameInfo>? _next;
  bool _disposed = false;

  int index = 0;

  /// Start time of the current frame within one pass of the clip.
  Duration elapsed = Duration.zero;

  int get frameCount => _codec.frameCount;
  ui.Image get image => _frame.image;
  Duration get frameDuration => _frame.duration;
  bool get isLastFrame => index == frameCount - 1;

  /// Decodes the following frame ahead of its display time.
  Future<ui.FrameInfo> prefetch() => _next ??= _codec.getNextFrame();

  void advance(ui.FrameInfo next) {
    _next = null;
    final previous = _frame;
    _frame = next;
    if (isLastFrame) {
      index = 0;
      elapsed = Duration.zero;
    } else {
      elapsed += previous.duration;
      index += 1;
    }
    previous.image.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _frame.image.dispose();
    _next?.then((frame) => frame.image.dispose(), onError: (_) {});
    _codec.dispose();
  }
}

/// Keeps the clips reachable from the current pet state decoded up to their
/// first frame, so switching clips never waits on asset IO or decoding.
class PetClipCache {
  PetClipCache(this.bundle);

  AssetBundle bundle;
  final Map<String, Future<PetClipSession?>> _primed = {};
  Set<String> _retained = const {};
  bool _disposed = false;

  void retain(Set<String> assets) {
    if (_disposed || setEquals(assets, _retained)) return;
    _retained = assets;
    for (final asset in _primed.keys.toList()) {
      if (!assets.contains(asset)) _release(_primed.remove(asset)!);
    }
    for (final asset in assets) {
      _primed[asset] ??= _open(asset);
    }
  }

  /// Hands over a session starting at frame 0; resolves to null on failure.
  Future<PetClipSession?> take(String asset) =>
      _primed.remove(asset) ?? _open(asset);

  /// Disposes a finished session and primes the next playback of its clip.
  void recycle(PetClipSession session) {
    session.dispose();
    if (!_disposed && _retained.contains(session.asset)) {
      _primed[session.asset] ??= _open(session.asset);
    }
  }

  Future<PetClipSession?> _open(String asset) async {
    try {
      final buffer = await bundle.loadBuffer(asset);
      final codec = await ui.instantiateImageCodecFromBuffer(buffer);
      final first = await codec.getNextFrame();
      final session = PetClipSession._(asset, codec, first);
      if (_disposed) {
        session.dispose();
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  void _release(Future<PetClipSession?> session) {
    session.then((value) => value?.dispose());
  }

  void dispose() {
    _disposed = true;
    _primed.values.forEach(_release);
    _primed.clear();
  }
}
