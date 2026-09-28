import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../pet_progression/domain/pet_appearance.dart';

/// Companion data of a runtime clip: `<clip>.pose.json` holds the pupil
/// centres of every frame, `<clip>.hoodie.webp` the hoodie coverage.
/// Both are produced by tool/animations from the approved animation scripts.
abstract final class PetLookAssets {
  static String poseFor(String clipAsset) =>
      clipAsset.replaceFirst(RegExp(r'\.webp$'), '.pose.json');

  static String hoodieMaskFor(String clipAsset) =>
      clipAsset.replaceFirst(RegExp(r'\.webp$'), '.hoodie.webp');
}

/// Pupil centres per frame in unit canvas coordinates.
class PetPose {
  const PetPose(this._eyes);

  final List<List<double>> _eyes;

  int get length => _eyes.length;

  /// Left pupil x/y, right pupil x/y of [frame] (clamped to the clip).
  List<double> eyes(int frame) => _eyes[frame.clamp(0, _eyes.length - 1)];

  static Future<PetPose?> load(AssetBundle bundle, String asset) async {
    try {
      final json = jsonDecode(
        await bundle.loadString(asset, cache: false),
      ) as Map<String, dynamic>;
      return PetPose([
        for (final row in json['eyes'] as List)
          [for (final value in row as List) (value as num).toDouble()],
      ]);
    } catch (_) {
      return null;
    }
  }
}

/// Decoded accessory artwork plus where it attaches.
class PetAccessoryArt {
  const PetAccessoryArt(this.image, this.spec);

  final ui.Image image;
  final PetAccessorySpec spec;
}

/// Placement of an accessory in the fox's eye frame: origin between the
/// pupils, x along the eye line, unit = pupil distance.
class PetAccessorySpec {
  const PetAccessorySpec({
    required this.asset,
    required this.anchor,
    required this.widthInPupils,
    required this.offset,
    this.referenceWidth,
    this.rotationDegrees = 0,
  });

  final String asset;

  /// Attachment point in the artwork's pixels.
  final Offset anchor;

  /// Artwork scale: [referenceWidth] artwork pixels (whole width when null)
  /// span this many pupil distances.
  final double widthInPupils;
  final double? referenceWidth;
  final Offset offset;
  final double rotationDegrees;

  static const glasses = PetAccessorySpec(
    asset: AppAssets.accessoryGlasses,
    // Midpoint of the lens centres (127.7, 124.1) and (397.1, 124.1).
    anchor: Offset(262.4, 124.1),
    referenceWidth: 269.4,
    widthInPupils: 1.12,
    offset: Offset(0, -0.04),
  );

  static const bow = PetAccessorySpec(
    asset: AppAssets.accessoryBow,
    anchor: Offset(197.6, 103.2),
    // Top of the head at the left ear: clear of the speech bubble on the
    // right and of the paw raised to the cheek when petted.
    widthInPupils: 0.8,
    offset: Offset(-0.8, -0.9),
    rotationDegrees: 18,
  );

  static PetAccessorySpec of(PetAccessory accessory) => switch (accessory) {
    PetAccessory.glasses => glasses,
    PetAccessory.bow => bow,
  };
}

/// Colour matrices that turn the blue hoodie into another colour; applied
/// only where the clip's hoodie mask is set.
abstract final class HoodiePalette {
  static List<double>? matrixFor(HoodieColor color) => switch (color) {
    HoodieColor.blue => null,
    HoodieColor.red => _hue(120, saturation: 1.7, brightness: 0.9),
    HoodieColor.green => _hue(-85, saturation: 0.9, brightness: 1.05),
    HoodieColor.purple => _hue(55, brightness: 1.05),
  };

  /// Hue rotation (W3C feColorMatrix) combined with saturation/brightness.
  static List<double> _hue(
    double degrees, {
    double saturation = 1,
    double brightness = 1,
  }) {
    final a = degrees * math.pi / 180;
    final c = math.cos(a);
    final s = math.sin(a);
    const lr = 0.213, lg = 0.715, lb = 0.072;
    final h = [
      [
        lr + c * (1 - lr) - s * lr,
        lg - c * lg - s * lg,
        lb - c * lb + s * (1 - lb),
      ],
      [
        lr - c * lr + s * 0.143,
        lg + c * (1 - lg) + s * 0.140,
        lb - c * lb - s * 0.283,
      ],
      [
        lr - c * lr - s * (1 - lr),
        lg - c * lg + s * lg,
        lb + c * (1 - lb) + s * lb,
      ],
    ];
    final t = saturation;
    final sat = [
      [lr + (1 - lr) * t, lg - lg * t, lb - lb * t],
      [lr - lr * t, lg + (1 - lg) * t, lb - lb * t],
      [lr - lr * t, lg - lg * t, lb + (1 - lb) * t],
    ];
    final m = List.generate(
      3,
      (i) => List.generate(3, (j) {
        var sum = 0.0;
        for (var k = 0; k < 3; k++) {
          sum += sat[i][k] * h[k][j];
        }
        return sum * brightness;
      }),
    );
    return [
      m[0][0], m[0][1], m[0][2], 0, 0, //
      m[1][0], m[1][1], m[1][2], 0, 0,
      m[2][0], m[2][1], m[2][2], 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Paints one fox frame with the chosen look into the full canvas box:
/// the frame itself, the recoloured hoodie on top of it (masked), then the
/// accessories attached to the tracked pupils of [frameIndex].
class PetLookPainter extends CustomPainter {
  PetLookPainter({
    required this.frame,
    required this.frameIndex,
    this.hoodieMask,
    this.hoodieMatrix,
    this.pose,
    this.accessories = const [],
  });

  final ui.Image frame;
  final int frameIndex;
  final ui.Image? hoodieMask;
  final List<double>? hoodieMatrix;
  final PetPose? pose;
  final List<PetAccessoryArt> accessories;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final src =
        Offset.zero & Size(frame.width.toDouble(), frame.height.toDouble());
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(frame, src, dst, paint);

    final mask = hoodieMask;
    final matrix = hoodieMatrix;
    if (mask != null && matrix != null) {
      canvas.saveLayer(dst, Paint());
      canvas.drawImageRect(
        frame,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.matrix(matrix),
      );
      canvas.drawImageRect(
        mask,
        Offset.zero & Size(mask.width.toDouble(), mask.height.toDouble()),
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }

    final pose = this.pose;
    if (pose == null || accessories.isEmpty) return;
    final e = pose.eyes(frameIndex);
    final left = Offset(e[0] * size.width, e[1] * size.height);
    final right = Offset(e[2] * size.width, e[3] * size.height);
    final eyeLine = right - left;
    final pupils = eyeLine.distance;
    if (pupils <= 0) return;
    final angle = math.atan2(eyeLine.dy, eyeLine.dx);
    final middle = (left + right) / 2;
    for (final art in accessories) {
      final spec = art.spec;
      final width = spec.referenceWidth ?? art.image.width.toDouble();
      final scale = spec.widthInPupils * pupils / width;
      canvas.save();
      canvas.translate(middle.dx, middle.dy);
      canvas.rotate(angle);
      canvas.translate(spec.offset.dx * pupils, spec.offset.dy * pupils);
      canvas.rotate(spec.rotationDegrees * math.pi / 180);
      canvas.scale(scale);
      canvas.drawImage(
        art.image,
        -spec.anchor,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PetLookPainter old) =>
      old.frame != frame ||
      old.frameIndex != frameIndex ||
      old.hoodieMask != hoodieMask ||
      old.hoodieMatrix != hoodieMatrix ||
      old.pose != pose ||
      old.accessories != accessories;
}

/// Loads and caches the artwork of the chosen accessories per bundle.
abstract final class PetAccessoryLoader {
  static final Map<(AssetBundle, PetAccessory), Future<PetAccessoryArt?>>
  _cache = {};

  static Future<List<PetAccessoryArt>> load(
    AssetBundle bundle,
    Set<PetAccessory> accessories,
  ) async {
    final arts = <PetAccessoryArt>[];
    // Glasses first, so a bow never ends up under them.
    for (final accessory in PetAccessory.values) {
      if (!accessories.contains(accessory)) continue;
      final art = await (_cache[(bundle, accessory)] ??= _decode(
        bundle,
        PetAccessorySpec.of(accessory),
      ));
      if (art != null) arts.add(art);
    }
    return arts;
  }

  static Future<PetAccessoryArt?> _decode(
    AssetBundle bundle,
    PetAccessorySpec spec,
  ) async {
    try {
      final data = await bundle.load(spec.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return PetAccessoryArt(frame.image, spec);
    } catch (_) {
      return null;
    }
  }
}

/// First frame of an image asset (a still or a clip's frame 0).
Future<ui.Image?> decodeFirstFrame(AssetBundle bundle, String asset) async {
  try {
    final data = await bundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } catch (_) {
    return null;
  }
}
