import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onPageStarted;
  final VoidCallback? onPageFinished;
  final ValueChanged<String>? onWebError;

  const PropWebView({
    super.key,
    required this.url,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebError,
  });

  @override
  State<PropWebView> createState() => PropWebViewState();
}

class PropWebViewState extends State<PropWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101511))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onPageStarted?.call(),
          onPageFinished: (_) => widget.onPageFinished?.call(),
          onWebResourceError: (error) {
            widget.onWebError?.call('PROP PAGE ERROR');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(covariant PropWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}

class KeyboardSafeArea extends StatelessWidget {
  final Widget child;

  const KeyboardSafeArea({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}

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

  const AOJDesktopIcon({
    super.key,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.35),
            const Color(0xFF111713),
          ],
        ),
        border: Border.all(color: accent.withOpacity(0.75), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 26, color: accent),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.18),
          border: Border.all(color: color.withOpacity(0.8)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const HeroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const InfoCard({
    super.key,
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xCC101511),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const InfoLine(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class ActionLine extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;

  const ActionLine({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7E8B63).withOpacity(0.06)
      ..strokeWidth = 1;

    const double gap = 28.0;

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
