import 'package:flutter/material.dart';

import '../branding/brand_geometry.g.dart';
import '../theme/app_theme.dart';

/// One vector mark for the in-app brand, matching Android icon and splash.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 44, this.onCoral = false, super.key});

  final double size;
  final bool onCoral;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onCoral ? AppTheme.coral : AppTheme.coralSoft,
      borderRadius: BorderRadius.circular(size * .25),
    ),
    child: CustomPaint(
      painter: _BrandPainter(onCoral ? Colors.white : AppTheme.coralActive),
    ),
  );
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ExcludeSemantics(child: BrandMark(size: 38, onCoral: true)),
      const SizedBox(width: 10),
      Text(
        'MueNee',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: 'Prompt',
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    ],
  );
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / BrandGeometry.viewport,
      size.height / BrandGeometry.viewport,
    );
    BrandGeometry.paint(canvas, color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) =>
      oldDelegate.color != color;
}
