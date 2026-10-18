part of 'investments_page.dart';

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
    required this.child,
  });

  final String label;
  final String title;
  final String value;
  final Color accent;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252A32)
        : const Color(0xFFDBDDE6);
    return Container(
      height: 218,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .07),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TelemetryLinePainter extends CustomPainter {
  const _TelemetryLinePainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<double> values;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final path = Path();
    final fill = Path()..moveTo(0, size.height);
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final wave = math.sin(progress * math.pi * 2 + index * .8) * 3;
      final y = size.height - values[index] * size.height * .72 + wave;
      if (index == 0) {
        path.moveTo(x, y);
        fill.lineTo(x, y);
      } else {
        final previousX = (index - 1) / (values.length - 1) * size.width;
        final previousY = size.height -
            values[index - 1] * size.height * .72 +
            math.sin(progress * math.pi * 2 + (index - 1) * .8) * 3;
        final controlX = (previousX + x) / 2;
        path.cubicTo(controlX, previousY, controlX, y, x, y);
        fill.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .34), color.withValues(alpha: .02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TelemetryLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

class _TelemetryBarsPainter extends CustomPainter {
  const _TelemetryBarsPainter({
    required this.values,
    required this.progress,
    required this.color,
  });

  final List<double> values;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    final gap = size.width / (count * 2.2);
    final barWidth = gap * .9;
    final pulse = .86 + math.sin(progress * math.pi * 2) * .08;
    for (var index = 0; index < count; index++) {
      final height = values[index] * size.height * pulse;
      final x = gap + index * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryBarsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

class _SyntheticCorePainter extends CustomPainter {
  const _SyntheticCorePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 150; index++) {
      final t = index / 149;
      final y = size.height * (.06 + t * .88);
      final wave = math.sin(t * math.pi * 4 + phase * math.pi * 2) *
          (size.width * (.13 + t * .06));
      final x = center.dx + wave;
      final radius = .7 + math.sin(t * math.pi) * 1.7;
      final opacity = (.14 + math.sin(t * math.pi) * .56).clamp(.08, .7);
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
      if (index % 6 == 0) {
        paint.color = Colors.white.withValues(alpha: opacity * .35);
        canvas.drawCircle(Offset(x - wave * .18, y), radius * .55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SyntheticCorePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
