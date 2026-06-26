import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme_extension.dart';

const kGuestAvatarAsset = 'assets/images/profile/guest_avatar.png';
const kProfileAvatarApiPath = '/users/me/avatar';

String? resolveProfileAvatarUrl(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) {
    return null;
  }

  final trimmed = rawPath.trim();
  if (_isLocalAvatarFile(trimmed)) {
    return null;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    return trimmed;
  }

  final base = Uri.parse(AppConstants.apiBaseUrl);
  final ref = Uri.encodeComponent(trimmed);
  return base
      .replace(path: '${base.path}$kProfileAvatarApiPath', query: 'ref=$ref')
      .toString();
}

bool _isLocalAvatarFile(String path) {
  if (path.startsWith('file://')) {
    return true;
  }
  if (path.startsWith('/')) {
    return true;
  }
  return RegExp(r'^[A-Za-z]:\\').hasMatch(path);
}

String? _localAvatarFilePath(String? rawPath) {
  if (rawPath == null || rawPath.trim().isEmpty) {
    return null;
  }
  final trimmed = rawPath.trim();
  if (!_isLocalAvatarFile(trimmed)) {
    return null;
  }
  if (trimmed.startsWith('file://')) {
    return Uri.parse(trimmed).toFilePath();
  }
  return trimmed;
}

class ProfileGuestAvatar extends StatelessWidget {
  final double size;
  final bool showGradientRing;

  const ProfileGuestAvatar({
    super.key,
    this.size = 103,
    this.showGradientRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = ClipOval(
      child: Image.asset(
        kGuestAvatarAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!showGradientRing) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC8D4FF), Color(0xFFFFACA6)],
        ),
      ),
      child: image,
    );
  }
}

class ProfileAvatarImage extends ConsumerStatefulWidget {
  final String? avatarPath;
  final Uint8List? localBytes;
  final double size;
  final bool showGradientRing;
  final double borderRadius;

  const ProfileAvatarImage({
    super.key,
    this.avatarPath,
    this.localBytes,
    this.size = 103,
    this.showGradientRing = true,
    this.borderRadius = 0,
  });

  @override
  ConsumerState<ProfileAvatarImage> createState() => _ProfileAvatarImageState();
}

class _ProfileAvatarImageState extends ConsumerState<ProfileAvatarImage> {
  Uint8List? _remoteBytes;
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteAvatar();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _loadRemoteAvatar();
    }
  }

  Future<void> _loadRemoteAvatar() async {
    final imageUrl = resolveProfileAvatarUrl(widget.avatarPath);
    if (imageUrl == null) {
      if (mounted) {
        setState(() {
          _remoteBytes = null;
          _loadingRemote = false;
        });
      }
      return;
    }

    setState(() => _loadingRemote = true);
    final uri = Uri.parse(imageUrl);
    final apiPath = uri.path.replaceFirst('/api/v1', '');
    final query = uri.query.isEmpty
        ? null
        : Map<String, dynamic>.from(uri.queryParameters);

    try {
      final bytes = await ref
          .read(apiClientProvider)
          .getBytes(apiPath, queryParameters: query);
      if (!mounted) return;
      setState(() {
        _remoteBytes = bytes;
        _loadingRemote = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remoteBytes = null;
        _loadingRemote = false;
      });
    }
  }

  Widget _clipImage(Widget child) {
    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: child,
      );
    }
    return ClipOval(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localPath = _localAvatarFilePath(widget.avatarPath);
    final hasLocalFile =
        !kIsWeb && localPath != null && File(localPath).existsSync();

    Widget avatarContent;
    if (widget.localBytes != null) {
      avatarContent = _clipImage(
        Image.memory(
          widget.localBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasLocalFile) {
      avatarContent = _clipImage(
        Image.file(
          File(localPath),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_loadingRemote) {
      avatarContent = SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_remoteBytes != null) {
      avatarContent = _clipImage(
        Image.memory(
          _remoteBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ProfileGuestAvatar(
        size: widget.size,
        showGradientRing: widget.showGradientRing,
      );
    }

    if (!widget.showGradientRing) {
      return SizedBox(width: widget.size, height: widget.size, child: avatarContent);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC8D4FF), Color(0xFFFFACA6)],
        ),
      ),
      child: avatarContent,
    );
  }
}
