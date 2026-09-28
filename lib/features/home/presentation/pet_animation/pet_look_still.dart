import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../pet_progression/domain/pet_appearance.dart';
import 'pet_look.dart';

/// A still anchor frame dressed in [appearance]: hoodie colour from the idle
/// clip's first hoodie-mask frame, accessories from its first pose frame.
///
/// Paints [stillAsset] plainly while the extra layers load, so it never shows
/// an empty box; with the default look it is just the plain still.
class PetLookStill extends StatefulWidget {
  const PetLookStill({
    required this.stillAsset,
    required this.idleAsset,
    required this.appearance,
    this.fallbackAsset,
    super.key,
  });

  final String stillAsset;

  /// The idle clip whose frame 0 the still is; supplies pose and mask.
  final String idleAsset;
  final PetAppearance appearance;
  final String? fallbackAsset;

  @override
  State<PetLookStill> createState() => _PetLookStillState();
}

class _PetLookStillState extends State<PetLookStill> {
  ui.Image? _frame;
  ui.Image? _mask;
  PetPose? _pose;
  List<PetAccessoryArt> _arts = const [];
  Object? _loadKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(PetLookStill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  @override
  void dispose() {
    _frame?.dispose();
    _mask?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.appearance.isDefault) return;
    final key = (widget.stillAsset, widget.idleAsset, widget.appearance);
    if (key == _loadKey) return;
    _loadKey = key;
    final bundle = DefaultAssetBundle.of(context);
    final needsMask = widget.appearance.hoodie != HoodieColor.blue;
    final results = await Future.wait<Object?>([
      decodeFirstFrame(bundle, widget.stillAsset),
      needsMask
          ? decodeFirstFrame(
              bundle,
              PetLookAssets.hoodieMaskFor(widget.idleAsset),
            )
          : Future<ui.Image?>.value(),
      widget.appearance.accessories.isEmpty
          ? Future<PetPose?>.value()
          : PetPose.load(bundle, PetLookAssets.poseFor(widget.idleAsset)),
      PetAccessoryLoader.load(bundle, widget.appearance.accessories),
    ]);
    if (!mounted || key != _loadKey) {
      (results[0] as ui.Image?)?.dispose();
      (results[1] as ui.Image?)?.dispose();
      return;
    }
    setState(() {
      _frame?.dispose();
      _mask?.dispose();
      _frame = results[0] as ui.Image?;
      _mask = results[1] as ui.Image?;
      _pose = results[2] as PetPose?;
      _arts = results[3]! as List<PetAccessoryArt>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    if (widget.appearance.isDefault || frame == null) {
      return Image.asset(
        widget.stillAsset,
        key: const ValueKey('pet_static_frame'),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: widget.fallbackAsset == null
            ? null
            : (context, error, stackTrace) => Image.asset(
                widget.fallbackAsset!,
                key: const ValueKey('pet_static_fallback'),
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                excludeFromSemantics: true,
              ),
      );
    }
    // The clip canvas is square; keep it square in any box, paws at the
    // bottom like the plain still (BoxFit.contain).
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox.square(
        dimension: frame.width.toDouble(),
        child: CustomPaint(
          key: const ValueKey('pet_static_frame'),
          painter: PetLookPainter(
            frame: frame,
            frameIndex: 0,
            hoodieMask: _mask,
            hoodieMatrix: HoodiePalette.matrixFor(widget.appearance.hoodie),
            pose: _pose,
            accessories: _arts,
          ),
        ),
      ),
    );
  }
}
