import 'dart:math';
import 'package:flutter/material.dart';
import '../models/circuit_model.dart';

class SchematicPainter extends CustomPainter {
  final List<CircuitComponent> components;
  final List<CircuitConnection> connections;

  SchematicPainter({required this.components, required this.connections});

  @override
  void paint(Canvas canvas, Size size) {
    if (components.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) * 0.35;

    final positions = <Offset>{};
    for (int i = 0; i < components.length; i++) {
      final angle = (2 * pi * i / components.length) - pi / 2;
      positions.add(
        Offset(centerX + radius * cos(angle), centerY + radius * sin(angle)),
      );
    }

    for (final conn in connections) {
      final fromIdx = _findComponentIndex(conn.from);
      final toIdx = _findComponentIndex(conn.to);
      if (fromIdx >= 0 &&
          toIdx >= 0 &&
          fromIdx < positions.length &&
          toIdx < positions.length) {
        final fromPos = positions.elementAt(fromIdx);
        final toPos = positions.elementAt(toIdx);
        canvas.drawLine(fromPos, toPos, paint);
      }
    }

    final boxPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    int i = 0;
    for (final pos in positions) {
      final comp = components[i];
      final symbolSize = const Size(50, 30);
      final rect = Rect.fromCenter(
        center: pos,
        width: symbolSize.width,
        height: symbolSize.height,
      );

      canvas.drawRect(rect, boxPaint);
      canvas.drawRect(rect, borderPaint);

      _drawSymbol(canvas, comp, pos, paint);

      textPainter.text = TextSpan(
        text: comp.ref,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy + 18),
      );

      i++;
    }
  }

  void _drawSymbol(
    Canvas canvas,
    CircuitComponent comp,
    Offset center,
    Paint paint,
  ) {
    final symbolPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (comp.type.toLowerCase()) {
      case 'resistor':
        final path = Path()
          ..moveTo(center.dx - 20, center.dy)
          ..lineTo(center.dx - 15, center.dy - 6)
          ..lineTo(center.dx - 8, center.dy + 6)
          ..lineTo(center.dx, center.dy - 6)
          ..lineTo(center.dx + 8, center.dy + 6)
          ..lineTo(center.dx + 15, center.dy - 6)
          ..lineTo(center.dx + 20, center.dy);
        canvas.drawPath(path, symbolPaint);
        break;
      case 'capacitor':
        canvas.drawLine(
          Offset(center.dx - 5, center.dy - 10),
          Offset(center.dx - 5, center.dy + 10),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 5, center.dy - 10),
          Offset(center.dx + 5, center.dy + 10),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx - 20, center.dy),
          Offset(center.dx - 5, center.dy),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 5, center.dy),
          Offset(center.dx + 20, center.dy),
          symbolPaint,
        );
        break;
      case 'inductor':
        final path = Path()
          ..moveTo(center.dx - 20, center.dy)
          ..arcToPoint(
            Offset(center.dx - 10, center.dy),
            radius: const Radius.circular(5),
            clockwise: true,
          )
          ..arcToPoint(
            Offset(center.dx, center.dy),
            radius: const Radius.circular(5),
            clockwise: true,
          )
          ..arcToPoint(
            Offset(center.dx + 10, center.dy),
            radius: const Radius.circular(5),
            clockwise: true,
          )
          ..arcToPoint(
            Offset(center.dx + 20, center.dy),
            radius: const Radius.circular(5),
            clockwise: true,
          );
        canvas.drawPath(path, symbolPaint);
        break;
      case 'led':
        canvas.drawLine(
          Offset(center.dx - 8, center.dy - 10),
          Offset(center.dx - 8, center.dy + 10),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 8, center.dy - 10),
          Offset(center.dx + 8, center.dy + 10),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx - 20, center.dy),
          Offset(center.dx - 8, center.dy),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 8, center.dy),
          Offset(center.dx + 20, center.dy),
          symbolPaint,
        );
        final arrowPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(center.dx - 3, center.dy - 14),
          Offset(center.dx + 3, center.dy - 20),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - 17),
          Offset(center.dx + 3, center.dy - 20),
          arrowPaint,
        );
        break;
      default:
        final path = Path()
          ..moveTo(center.dx - 15, center.dy - 8)
          ..lineTo(center.dx + 15, center.dy - 8)
          ..lineTo(center.dx + 15, center.dy + 8)
          ..lineTo(center.dx - 15, center.dy + 8)
          ..close();
        canvas.drawPath(path, symbolPaint);
        canvas.drawLine(
          Offset(center.dx - 20, center.dy),
          Offset(center.dx - 15, center.dy),
          symbolPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 15, center.dy),
          Offset(center.dx + 20, center.dy),
          symbolPaint,
        );
    }
  }

  int _findComponentIndex(String nodeId) {
    final ref = nodeId.split('.').first;
    for (int i = 0; i < components.length; i++) {
      if (components[i].ref == ref) return i;
    }
    return -1;
  }

  @override
  bool shouldRepaint(covariant SchematicPainter oldDelegate) {
    return oldDelegate.components != components ||
        oldDelegate.connections != connections;
  }
}
