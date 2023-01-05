import 'dart:math';

import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  PieChartPainter(this.collateralRatio, this.debitRatio);
  double collateralRatio;
  double debitRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final double distance = 10;
    final sw = size.width - distance;
    final sh = size.height - distance;
    final double radius = min(sw, sh) / 2;
    final Offset center = Offset((sw + distance) / 2, (sh + distance) / 2);

    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(76);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3 / 2 * pi,
        2 * pi * collateralRatio, collateralRatio == 1 ? false : true, paint);

    Paint paint1 = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    var centerAngle = 3 / 2 * pi + 2 * pi * collateralRatio + pi * debitRatio;
    centerAngle = centerAngle % (pi / 2);

    var y = centerAngle == 0 ? 0 : sin(centerAngle) * distance;
    var x = centerAngle == 0 ? distance : cos(centerAngle) * distance;

    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(center.dx - x, center.dy - y),
            radius: radius + distance * (pi / 4 - centerAngle)),
        3 / 2 * pi + 2 * pi * collateralRatio,
        2 * pi * debitRatio,
        debitRatio == 1 ? false : true,
        paint1);
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) =>
      oldDelegate.collateralRatio != collateralRatio ||
      oldDelegate.debitRatio != debitRatio;
}
