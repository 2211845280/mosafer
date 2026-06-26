import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme_extension.dart';

class OpenLevelUpView extends StatelessWidget {
  const OpenLevelUpView({super.key, required this.url, required this.overlay});

  final String url;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
