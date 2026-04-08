import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onPageStarted;
  final VoidCallback? onPageFinished;
  final Function(String)? onWebError;

  const PropWebView({
    super.key,
    required this.url,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebError,
  });

  @override
  State<PropWebView> createState() => _PropWebViewState();
}

class _PropWebViewState extends State<PropWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onPageStarted?.call(),
          onPageFinished: (_) => widget.onPageFinished?.call(),
          onWebResourceError: (error) {
            widget.onWebError?.call(error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
