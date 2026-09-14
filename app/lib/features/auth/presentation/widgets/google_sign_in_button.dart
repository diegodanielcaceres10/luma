import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1F1F1F),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Minimal four-color "G" mark, drawn to avoid shipping a bitmap asset.
class _GoogleMark extends StatelessWidget {
  final double size;

  const _GoogleMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.42;
    final rect =
        Rect.fromCircle(radius: radius - strokeWidth / 2, center: center);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const twoPi = 6.28318530718;
    const start = -0.35; // radians, small offset so the seams sit at the notch

    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, start, twoPi * 0.28, false, paint);

    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, start + twoPi * 0.28, twoPi * 0.22, false, paint);

    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, start + twoPi * 0.50, twoPi * 0.22, false, paint);

    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, start + twoPi * 0.72, twoPi * 0.28, false, paint);

    // Horizontal bar of the "G".
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth * 0.28,
        radius,
        strokeWidth * 0.56,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
