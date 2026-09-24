import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';

/// Home-only presentation. The surrounding PetStage owns all layout dimensions.
class AnimatedPet extends StatefulWidget {
  const AnimatedPet({
    required this.fallbackAsset,
    required this.isActive,
    this.animationsEnabled = true,
    super.key,
  });

  final String fallbackAsset;
  final bool isActive;
  final bool animationsEnabled;

  @override
  State<AnimatedPet> createState() => _AnimatedPetState();
}

class _AnimatedPetState extends State<AnimatedPet> with WidgetsBindingObserver {
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground != foreground) setState(() => _foreground = foreground);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _fallback() => Image.asset(
    widget.fallbackAsset,
    key: const ValueKey('pet_static_fallback'),
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    gaplessPlayback: true,
    excludeFromSemantics: true,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.animationsEnabled || MediaQuery.disableAnimationsOf(context)) {
      return _fallback();
    }
    final playing =
        widget.isActive &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Offset.zero & constraints.biggest;
          final pngSize = applyBoxFit(
            BoxFit.contain,
            const Size(1214, 1295),
            bounds.size,
          ).destination;
          final pngRect = Alignment.bottomCenter.inscribe(pngSize, bounds);
          // Align the first pose's visible height and paws with the canonical
          // PNG (alpha > 32): PNG y=24..1233/1295, WebP y=18..720/720.
          // This transform is local and constant across frames, not a new scene.
          final side = pngRect.height * (1209 / 1295) / (702 / 720);
          final top =
              pngRect.top + pngRect.height * (24 / 1295) - side * (18 / 720);
          return TickerMode(
            enabled: playing,
            // Flutter detaches the frame listener while paused, retaining
            // the completer/current frame for an immediate tab return.
            child: Image.asset(
              AppAssets.ryzhikIdleAnimation,
              key: const ValueKey('pet_idle_animation'),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => _fallback(),
              frameBuilder: (context, child, frame, synchronous) => Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: (bounds.width - side) / 2,
                    top: top,
                    width: side,
                    height: side,
                    child: child,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
