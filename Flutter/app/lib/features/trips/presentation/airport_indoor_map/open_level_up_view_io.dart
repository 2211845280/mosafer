import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'open_level_up_crop.dart';

class OpenLevelUpView extends StatefulWidget {
  const OpenLevelUpView({super.key, required this.url, required this.overlay});

  final String url;
  final Widget overlay;

  @override
  State<OpenLevelUpView> createState() => _OpenLevelUpViewState();
}

class _OpenLevelUpViewState extends State<OpenLevelUpView> {
  WebViewController? _controller;
  bool _isLoading = true;

  bool get _supportsEmbeddedWebView => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  void didUpdateWidget(covariant OpenLevelUpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _controller != null) {
      _controller!.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_supportsEmbeddedWebView || controller == null) {
      return _OpenExternallyFallback(url: widget.url, overlay: widget.overlay);
    }

    return Stack(
      children: [
        _CroppedOpenLevelUpWebView(controller: controller),
        if (_isLoading)
          const ColoredBox(
            color: Color(0xFF061326),
            child: Center(child: CircularProgressIndicator()),
          ),
        widget.overlay,
      ],
    );
  }
}

class _CroppedOpenLevelUpWebView extends StatelessWidget {
  const _CroppedOpenLevelUpWebView({required this.controller});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -openLevelUpCropLeft,
            top: -openLevelUpCropTop,
            right: 0,
            bottom: 0,
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _OpenExternallyFallback extends StatelessWidget {
  const _OpenExternallyFallback({required this.url, required this.overlay});

  final String url;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColoredBox(
          color: const Color(0xFF061326),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open OpenLevelUp map'),
              ),
            ),
          ),
        ),
        overlay,
      ],
    );
  }
}
