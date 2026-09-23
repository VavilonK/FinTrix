import 'dart:math' as math;

import 'package:flutter/material.dart';

class MapCameraPlan {
  const MapCameraPlan({
    required this.transform,
    required this.foxPoint,
    required this.safeViewport,
    required this.scale,
  });

  final Matrix4 transform;
  final Offset foxPoint;
  final Rect safeViewport;
  final double scale;
}

abstract final class MapCamera {
  static Rect calculateSafeViewport(
    Size viewport, {
    required double bottomOverlayHeight,
    double topOverlayHeight = 0,
  }) {
    const horizontalPadding = 24.0;
    final topPadding = topOverlayHeight + 18;
    const bottomSafetyGap = 32.0;
    final bottom = math.max(
      topPadding + 96,
      viewport.height - bottomOverlayHeight - bottomSafetyGap,
    );
    return Rect.fromLTRB(
      horizontalPadding,
      topPadding,
      math.max(horizontalPadding + 120, viewport.width - horizontalPadding),
      bottom,
    );
  }

  static MapCameraPlan plan({
    required Size viewport,
    required Size sceneSize,
    required Offset normalizedLocation,
    required double bottomOverlayHeight,
    double topOverlayHeight = 0,
  }) {
    final activePoint = Offset(
      normalizedLocation.dx * sceneSize.width,
      normalizedLocation.dy * sceneSize.height,
    );
    final safeViewport = calculateSafeViewport(
      viewport,
      bottomOverlayHeight: bottomOverlayHeight,
      topOverlayHeight: topOverlayHeight,
    );
    final visibleMapBottom = math.max(
      safeViewport.bottom + 24,
      viewport.height - bottomOverlayHeight,
    );
    final minScale = math.max(
      viewport.width / sceneSize.width,
      visibleMapBottom / sceneSize.height,
    );

    MapCameraPlan? best;
    var bestScore = double.infinity;
    for (final delta in _orderedAnchors(normalizedLocation)) {
      final foxPoint = activePoint + delta;
      final foxRect = Rect.fromLTWH(
        foxPoint.dx - 58,
        foxPoint.dy - 88,
        122,
        122,
      );
      if (!_insideScene(foxRect, sceneSize)) continue;

      final focusBounds = Rect.fromPoints(activePoint, foxPoint)
          .expandToInclude(
            Rect.fromCenter(center: activePoint, width: 154, height: 138),
          )
          .expandToInclude(foxRect)
          .inflate(24);
      final fitScale = math.min(
        safeViewport.width / focusBounds.width,
        safeViewport.height / focusBounds.height,
      );
      final topVisibilityScale = activePoint.dy <= 0
          ? minScale
          : (safeViewport.top + 4) / activePoint.dy;
      final scale = math
          .max(
            math.max(minScale, topVisibilityScale),
            math.min(0.96, fitScale * 0.94),
          )
          .clamp(minScale, 1.25)
          .toDouble();
      var translation = Offset(
        safeViewport.center.dx - activePoint.dx * scale,
        safeViewport.top + safeViewport.height * 0.60 - activePoint.dy * scale,
      );
      translation = _fitBounds(
        translation: translation,
        scale: scale,
        bounds: focusBounds,
        safeViewport: safeViewport,
      );
      translation = Offset(
        translation.dx.clamp(
          math.min(0.0, viewport.width - sceneSize.width * scale),
          0.0,
        ),
        translation.dy.clamp(
          math.min(0.0, visibleMapBottom - sceneSize.height * scale),
          0.0,
        ),
      );

      final screenBounds = Rect.fromLTWH(
        focusBounds.left * scale + translation.dx,
        focusBounds.top * scale + translation.dy,
        focusBounds.width * scale,
        focusBounds.height * scale,
      );
      final score =
          _overflowScore(screenBounds, safeViewport) +
          (scale < 0.66 ? (0.66 - scale) * 100 : 0);
      if (score < bestScore) {
        bestScore = score;
        best = MapCameraPlan(
          transform: Matrix4.identity()
            ..translateByDouble(translation.dx, translation.dy, 0, 1)
            ..scaleByDouble(scale, scale, scale, 1),
          foxPoint: foxPoint,
          safeViewport: safeViewport,
          scale: scale,
        );
      }
    }

    return best ??
        MapCameraPlan(
          transform: Matrix4.identity()
            ..scaleByDouble(minScale, minScale, minScale, 1),
          foxPoint: activePoint + const Offset(160, -120),
          safeViewport: safeViewport,
          scale: minScale,
        );
  }

  static List<Offset> _orderedAnchors(Offset normalized) {
    const topLeft = Offset(-170, -118);
    const topRight = Offset(170, -118);
    const bottomLeft = Offset(-170, 148);
    const bottomRight = Offset(170, 148);
    const left = Offset(-196, 10);
    const right = Offset(196, 10);

    if (normalized.dy >= 0.62) {
      return normalized.dx < 0.5
          ? [topRight, right, topLeft, left, bottomRight, bottomLeft]
          : [topLeft, left, topRight, right, bottomLeft, bottomRight];
    }
    if (normalized.dy <= 0.34) {
      return normalized.dx < 0.5
          ? [bottomRight, right, bottomLeft, left, topRight, topLeft]
          : [bottomLeft, left, bottomRight, right, topLeft, topRight];
    }
    if (normalized.dx <= 0.3) {
      return [right, bottomRight, topRight, bottomLeft, topLeft, left];
    }
    if (normalized.dx >= 0.7) {
      return [left, bottomLeft, topLeft, bottomRight, topRight, right];
    }
    return [bottomLeft, bottomRight, topLeft, topRight, left, right];
  }

  static bool _insideScene(Rect rect, Size sceneSize) {
    const margin = 18.0;
    return rect.left >= margin &&
        rect.top >= margin &&
        rect.right <= sceneSize.width - margin &&
        rect.bottom <= sceneSize.height - margin;
  }

  static Offset _fitBounds({
    required Offset translation,
    required double scale,
    required Rect bounds,
    required Rect safeViewport,
  }) {
    var dx = translation.dx;
    var dy = translation.dy;
    final left = bounds.left * scale + dx;
    final right = bounds.right * scale + dx;
    final top = bounds.top * scale + dy;
    final bottom = bounds.bottom * scale + dy;
    if (left < safeViewport.left) dx += safeViewport.left - left;
    if (right > safeViewport.right) dx -= right - safeViewport.right;
    if (top < safeViewport.top) dy += safeViewport.top - top;
    if (bottom > safeViewport.bottom) dy -= bottom - safeViewport.bottom;
    return Offset(dx, dy);
  }

  static double _overflowScore(Rect rect, Rect safe) {
    return math.max(0, safe.left - rect.left) +
        math.max(0, rect.right - safe.right) +
        math.max(0, safe.top - rect.top) +
        math.max(0, rect.bottom - safe.bottom);
  }
}
