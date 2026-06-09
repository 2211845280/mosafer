// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Pixels cropped from embedded OpenLevelUp chrome (top navbar / left sidebar).
const openLevelUpCropTopPx = 40;
const openLevelUpCropLeftPx = 0;

class OpenLevelUpView extends StatefulWidget {
  const OpenLevelUpView({super.key, required this.url, required this.overlay});

  final String url;
  final Widget overlay;

  @override
  State<OpenLevelUpView> createState() => _OpenLevelUpViewState();
}

class _OpenLevelUpViewState extends State<OpenLevelUpView> {
  late final String _viewType;
  late final html.IFrameElement _iframe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewType = 'open-level-up-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = html.IFrameElement()
      ..src = widget.url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = 'calc(100% + ${openLevelUpCropTopPx}px)'
      ..style.marginTop = '-${openLevelUpCropTopPx}px'
      ..setAttribute('allow', 'fullscreen; geolocation');
    _iframe.onLoad.listen((_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _iframe);
  }

  @override
  void didUpdateWidget(covariant OpenLevelUpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _isLoading = true);
      _iframe.src = widget.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
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
