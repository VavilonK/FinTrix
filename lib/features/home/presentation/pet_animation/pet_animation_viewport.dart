import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'pet_animation_coordinator.dart';
import 'pet_animation_models.dart';
import 'pet_clip_cache.dart';

/// Draws whatever [PetAnimationCoordinator] selects inside PetStage's bounds.
///
/// Every clip shares one square canvas placed by [canvasRect], so switching
/// clips never moves the fox or resizes the scene. Clips cut directly from
/// one decoded frame to the next; the previous frame stays up while the next
/// clip's first frame is not ready yet.
class PetAnimationViewport extends StatefulWidget {
  const PetAnimationViewport({
    required this.coordinator,
    required this.fallbackAsset,
    required this.isActive,
    super.key,
  });

  final PetAnimationCoordinator coordinator;

  /// Legacy PNG, only shown if the runtime assets cannot be loaded.
  final String fallbackAsset;
  final bool isActive;

  /// Idle frames advance this much faster while an action waits for the idle
  /// loop to come back to its anchor pose.
  static const catchUpSpeed = 4;

  /// Fast-forwarding is bound by decode speed; after this long the action
  /// starts anyway so a tap never feels ignored (a small pose jump is
  /// preferred over a multi-second wait on slow devices).
  static const catchUpBudget = Duration(seconds: 1);

  /// Places the shared animation canvas so the anchor pose keeps the height
  /// and paw line of the canonical PNG (1214x1295, opaque y=24..1233).
  /// Runtime anchor frames are opaque at y=61..959 of 960.
  static Rect canvasRect(Size bounds) {
    final area = Offset.zero & bounds;
    final pngSize = applyBoxFit(
      BoxFit.contain,
      const Size(1214, 1295),
      bounds,
    ).destination;
    final pngRect = Alignment.bottomCenter.inscribe(pngSize, area);
    final side = pngRect.height * (1209 / 1295) / (899 / 960);
    final top = pngRect.top + pngRect.height * (24 / 1295) - side * (61 / 960);
    return Rect.fromLTWH((bounds.width - side) / 2, top, side, side);
  }

  @override
  State<PetAnimationViewport> createState() => _PetAnimationViewportState();
}

class _PetAnimationViewportState extends State<PetAnimationViewport>
    with WidgetsBindingObserver {
  PetClipCache? _cache;
  PetClipSession? _session;
  PetAnimationState? _sessionState;
  int? _sessionPlayId;
  int? _loadingPlayId;
  ui.Image? _image;
  Timer? _frameTimer;
  bool _catchingUp = false;
  DateTime? _catchUpStartedAt;
  bool _foreground = true;
  bool _visible = true;
  final Set<String> _failedAssets = {};

  PetAnimationCoordinator get _coordinator => widget.coordinator;

  bool get _playing => widget.isActive && _foreground && _visible;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _coordinator.addListener(_reconcile);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_cache == null) {
      _cache = PetClipCache(bundle);
    } else {
      _cache!.bundle = bundle;
    }
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _reconcile();
  }

  @override
  void didUpdateWidget(PetAnimationViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_reconcile);
      widget.coordinator.addListener(_reconcile);
    }
    _reconcile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    _reconcile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.removeListener(_reconcile);
    _frameTimer?.cancel();
    _session?.dispose();
    _image?.dispose();
    _cache?.dispose();
    super.dispose();
  }

  /// Brings playback in line with the coordinator and visibility.
  void _reconcile() {
    final cache = _cache;
    if (cache == null || !mounted) return;
    if (!_coordinator.animationsEnabled) {
      cache.retain(const {});
      if (_session != null || _image != null || _loadingPlayId != null) {
        _stop();
        setState(() {});
      }
      return;
    }
    cache.retain({
      for (final state in _coordinator.preloadSet) state.definition.asset,
    });

    final wanted = _coordinator.current;
    final playId = _coordinator.playId;
    if (_sessionPlayId == playId || _loadingPlayId == playId) {
      _ensureTicking();
      return;
    }
    if (wanted.isIdle && wanted == _sessionState) {
      // Interrupting an action that never started, or a rebuild: the idle
      // keeps its place in the loop instead of restarting.
      _sessionPlayId = playId;
      _catchingUp = false;
      _catchUpStartedAt = null;
      _ensureTicking();
      return;
    }
    if (_failedAssets.contains(wanted.definition.asset)) {
      _showStill();
      if (!wanted.isIdle) _coordinator.actionCompleted(playId);
      return;
    }
    if (!wanted.isIdle && !_atAnchor()) {
      // Let the idle finish its loop quickly and cut at its anchor frame.
      _catchingUp = true;
      _catchUpStartedAt ??= DateTime.now();
      _ensureTicking();
      return;
    }
    _switchTo(wanted, playId);
  }

  /// Whether the current idle frame matches the anchor pose closely enough for
  /// an action to cut in. Stills and not-yet-decoded idles always do.
  bool _atAnchor() {
    final session = _session;
    final state = _sessionState;
    if (session == null || state == null || session.frameCount <= 1) {
      return true;
    }
    return state.isIdle && session.elapsed < state.definition.anchorWindow;
  }

  void _switchTo(PetAnimationState state, int playId) {
    // Hold the frame on screen until the next clip's first frame is ready.
    _cancelTick();
    _catchingUp = false;
    _catchUpStartedAt = null;
    _loadingPlayId = playId;
    final asset = state.definition.asset;
    _cache!.take(asset).then((session) {
      if (!mounted || playId != _coordinator.playId) {
        session?.dispose();
        return;
      }
      if (_loadingPlayId == playId) _loadingPlayId = null;
      if (session == null) {
        _failedAssets.add(asset);
        _showStill();
        if (!state.isIdle) _coordinator.actionCompleted(playId);
        return;
      }
      _cancelTick();
      final previous = _session;
      _session = session;
      _sessionState = state;
      _sessionPlayId = playId;
      _setImage(session.image);
      if (previous != null) _cache!.recycle(previous);
      if (!state.isIdle) _coordinator.actionStarted(playId);
      _ensureTicking();
    });
  }

  void _ensureTicking() {
    if (!_playing) {
      _cancelTick();
    } else if (_frameTimer == null && _loadingPlayId == null) {
      _schedule();
    }
  }

  void _cancelTick() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  /// Shows the current frame for its duration, then the next one. At most
  /// one tick is pending; [_frameTimer] stays set until it has completed.
  void _schedule() {
    final session = _session;
    final state = _sessionState;
    if (session == null || state == null || !_playing) return;
    if (session.frameCount <= 1) return;
    var due = session.frameDuration;
    if (_catchingUp) due = due ~/ PetAnimationViewport.catchUpSpeed;
    if (!state.definition.loops && session.isLastFrame) {
      final playId = _sessionPlayId!;
      // The last frame stays up until the destination idle replaces it.
      _frameTimer = Timer(due, () => _coordinator.actionCompleted(playId));
      return;
    }
    final next = session.prefetch();
    late final Timer tick;
    tick = _frameTimer = Timer(due, () async {
      final ui.FrameInfo frame;
      try {
        frame = await next;
      } catch (_) {
        return;
      }
      // Paused or replaced meanwhile; a paused session keeps the decoded
      // frame for when playback resumes.
      if (!mounted || session != _session || _frameTimer != tick) return;
      _frameTimer = null;
      final overBudget =
          _catchingUp &&
          DateTime.now().difference(_catchUpStartedAt ?? DateTime.now()) >
              PetAnimationViewport.catchUpBudget;
      if (_catchingUp &&
          (session.isLastFrame || overBudget) &&
          !_coordinator.current.isIdle) {
        // The loop is back at its anchor: start the action in its place.
        _switchTo(_coordinator.current, _coordinator.playId);
        return;
      }
      session.advance(frame);
      _setImage(session.image);
      _ensureTicking();
    });
  }

  void _setImage(ui.Image image) {
    final previous = _image;
    setState(() => _image = image.clone());
    previous?.dispose();
  }

  void _showStill() {
    _stop();
    if (mounted) setState(() {});
  }

  void _stop() {
    _cancelTick();
    _catchingUp = false;
    _catchUpStartedAt = null;
    _loadingPlayId = null;
    _sessionPlayId = null;
    _sessionState = null;
    final session = _session;
    _session = null;
    if (session != null) _cache?.recycle(session);
    final image = _image;
    _image = null;
    image?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final Widget content;
    if (image != null && _coordinator.animationsEnabled) {
      content = RawImage(
        key: const ValueKey('pet_animation_frame'),
        image: image,
        fit: BoxFit.contain,
      );
    } else {
      content = Image.asset(
        _stillAsset,
        key: const ValueKey('pet_static_frame'),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          widget.fallbackAsset,
          key: const ValueKey('pet_static_fallback'),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          excludeFromSemantics: true,
        ),
      );
    }
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: PetAnimationViewport.canvasRect(constraints.biggest),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  /// The anchor pose of the clip on screen (or about to be), which is also
  /// the reduce-motion frame for the current base state.
  String get _stillAsset => _coordinator.animationsEnabled
      ? (_sessionState ?? _coordinator.current).definition.stillAsset
      : PetAnimationCatalog.idleFor(_coordinator.baseState)
            .definition
            .stillAsset;
}
