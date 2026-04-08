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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
