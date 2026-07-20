import 'dart:math';
import 'package:flutter/material.dart';

/// Un diagramme circulaire (camembert) custom avec légende.
/// N'utilise aucun package externe — dessiné avec CustomPainter.
class PieChartWidget extends StatelessWidget {
  final Map<String, num> data;
  final double size;
  final Color? defaultColor;

  /// Palette étendue pour colorer chaque segment
  static const List<Color> _palette = [
    Color(0xFF00875A), // OCP Green
    Color(0xFF1565C0), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00838F), // Teal
    Color(0xFF283593), // Indigo
    Color(0xFFAD1457), // Pink
    Color(0xFF4E342E), // Brown
    Color(0xFF558B2F), // Light Green
  ];

  const PieChartWidget({
    super.key,
    required this.data,
    this.size = 160,
    this.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<num>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    // Filtrer les valeurs > 0 et trier par ordre décroissant
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        // ── Camembert ──
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _PieChartPainter(entries, total)),
        ),
        const SizedBox(width: 20),
        // ── Légende ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final ratio = (e.value / total) * 100;
              final color = _palette[i % _palette.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF111111),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${ratio.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, num>> entries;
  final num total;

  _PieChartPainter(this.entries, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // Commencer en haut (12h)

    for (int i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * pi;
      final color = PieChartWidget._palette[i % PieChartWidget._palette.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Petit espace entre les segments (effet "donut léger")
      final gapPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Dessiner un petit trait blanc de séparation
      final gapAngle = 0.015; // ~0.9° de gap
      canvas.drawArc(
        rect,
        startAngle + sweepAngle - gapAngle,
        gapAngle,
        true,
        gapPaint,
      );

      startAngle += sweepAngle;
    }

    // Cercle central blanc pour effet donut (optionnel, plus moderne)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.45, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.total != total;
  }
}
