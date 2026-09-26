import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum SpeechBubbleTail { bottomLeft, bottomRight, left, right }

/// Comic speech bubble with a tail and a small heart, slightly tilted like the
/// hand-drawn notes in the reference art.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    required this.text,
    this.tail = SpeechBubbleTail.bottomLeft,
    this.tilt = -4,
    this.showHeart = true,
    this.style,
    this.padding = const EdgeInsets.fromLTRB(14, 10, 14, 12),
    super.key,
  });

  final String text;
  final SpeechBubbleTail tail;

  /// Rotation in degrees; negative tilts counter-clockwise.
  final double tilt;
  final bool showHeart;
  final TextStyle? style;
  final EdgeInsets padding;

  static const double tailSize = 12;

  @override
  Widget build(BuildContext context) {
    final tailInsets = switch (tail) {
      SpeechBubbleTail.bottomLeft ||
      SpeechBubbleTail.bottomRight => const EdgeInsets.only(bottom: tailSize),
      SpeechBubbleTail.left => const EdgeInsets.only(left: tailSize),
      SpeechBubbleTail.right => const EdgeInsets.only(right: tailSize),
    };
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Transform.rotate(
        angle: tilt * math.pi / 180,
        child: CustomPaint(
          painter: _BubblePainter(tail),
          child: Padding(
            padding: padding + tailInsets,
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  if (showHeart)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: AppColors.pink,
                        ),
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
              style:
                  style ??
                  AppTextStyles.caption.copyWith(
                    color: AppColors.navy.withAlpha(215),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.tail);

  final SpeechBubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    const t = SpeechBubble.tailSize;
    var body = Offset.zero & size;
    body = switch (tail) {
      SpeechBubbleTail.bottomLeft || SpeechBubbleTail.bottomRight =>
        Rect.fromLTRB(0, 0, size.width, size.height - t),
      SpeechBubbleTail.left => Rect.fromLTRB(t, 0, size.width, size.height),
      SpeechBubbleTail.right => Rect.fromLTRB(
        0,
        0,
        size.width - t,
        size.height,
      ),
    };
    final radius = math.min(22.0, body.shortestSide / 2);
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
    // Each tail starts inside the body, so the rounded corner leaves no gap
    // through which the character behind could show.
    final inset = radius * 0.7;
    final tailPath = switch (tail) {
      SpeechBubbleTail.bottomLeft =>
        Path()
          ..moveTo(body.left + radius * 0.5, body.bottom - inset)
          ..lineTo(body.left + radius * 0.9, body.bottom - 1)
          ..quadraticBezierTo(
            body.left + radius * 0.5,
            size.height,
            body.left + 4,
            size.height,
          )
          ..quadraticBezierTo(
            body.left + radius * 0.9,
            body.bottom + t * 0.2,
            body.left + radius * 1.9,
            body.bottom - 1,
          )
          ..lineTo(body.left + radius * 1.9, body.bottom - inset)
          ..close(),
      SpeechBubbleTail.bottomRight =>
        Path()
          ..moveTo(body.right - radius * 0.5, body.bottom - inset)
          ..lineTo(body.right - radius * 0.9, body.bottom - 1)
          ..quadraticBezierTo(
            body.right - radius * 0.5,
            size.height,
            body.right - 4,
            size.height,
          )
          ..quadraticBezierTo(
            body.right - radius * 0.9,
            body.bottom + t * 0.2,
            body.right - radius * 1.9,
            body.bottom - 1,
          )
          ..lineTo(body.right - radius * 1.9, body.bottom - inset)
          ..close(),
      SpeechBubbleTail.left =>
        Path()
          ..moveTo(body.left + 8, body.center.dy - 8)
          ..lineTo(0, body.center.dy + 6)
          ..lineTo(body.left + 8, body.center.dy + 6)
          ..close(),
      SpeechBubbleTail.right =>
        Path()
          ..moveTo(body.right - 8, body.center.dy - 8)
          ..lineTo(size.width, body.center.dy + 6)
          ..lineTo(body.right - 8, body.center.dy + 6)
          ..close(),
    };
    final path = Path.combine(PathOperation.union, bodyPath, tailPath);
    canvas.drawShadow(path, const Color(0x551C326F), 4, false);
    // Opaque, so the character behind never shows through.
    canvas.drawPath(path, Paint()..color = AppColors.surface);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => oldDelegate.tail != tail;
}
