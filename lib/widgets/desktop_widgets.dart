import 'package:flutter/material.dart';

class AOJDesktopBackground extends StatelessWidget {
  const AOJDesktopBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.4, -0.8),
              radius: 1.4,
              colors: [
                Color(0xFF2A372B),
                Color(0xFF111712),
                Color(0xFF090D0A),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
        Positioned(
          top: 18,
          right: 22,
          child: Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/aoj_logo.png',
              width: 420,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class AOJDesktopIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final int unreadCount;

  const AOJDesktopIcon({
    super.key,
    required this.icon,
    required this.accent,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.35),
                  const Color(0xFF111713),
                ],
              ),
              border:
                  Border.all(color: accent.withValues(alpha: 0.75), width: 1.3),
            ),
            child: Icon(icon, size: 26, color: accent),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD93025),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.80),
                    width: 1,
                  ),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WindowButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const WindowButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class KeyboardSafeArea extends StatelessWidget {
  final Widget child;

  const KeyboardSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: child);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7E8B63).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const gap = 28.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
