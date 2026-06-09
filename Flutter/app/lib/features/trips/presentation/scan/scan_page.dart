import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/error_message_localizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../active_trip_controller.dart';
import '../my_trips/my_trips_controller.dart';
import 'scan_controller.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  bool _isHandlingScan = false;
  bool _showUpload = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scanState = ref.watch(scanControllerProvider);
    return Scaffold(
      backgroundColor: _ScanColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ScanAppBar(l10n: l10n),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: _ScanTabs(
                l10n: l10n,
                showUpload: _showUpload,
                onScanSelected: () => setState(() => _showUpload = false),
                onUploadSelected: () => setState(() => _showUpload = true),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: _showUpload
                  ? _UploadTicketPanel(
                      l10n: l10n,
                      isLoading: scanState.isLoading,
                      onUploadPressed: _pickAndScanImage,
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: _CameraPreview(
                            onPayloadDetected: _handlePayload,
                          ),
                        ),
                        Positioned.fill(child: _ScanOverlay(l10n: l10n)),
                        Positioned(
                          left: 13,
                          right: 13,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _ScanNowButton(
                                l10n: l10n,
                                isLoading: scanState.isLoading,
                                onPressed: () =>
                                    _showQrPayloadSheet(context, ref),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayload(String payload) async {
    if (_isHandlingScan) return;
    _isHandlingScan = true;
    final trip = await ref
        .read(scanControllerProvider.notifier)
        .scanPayload(payload);
    if (trip != null && mounted) {
      ref.read(activeTripProvider.notifier).state = trip;
      await ref.read(myTripsControllerProvider.notifier).loadTrips();
      if (!mounted) return;
      context.goNamed('dashboard');
      return;
    }
    if (mounted) {
      _showScanError();
    }
    _isHandlingScan = false;
  }

  Future<void> _pickAndScanImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final trip = await ref
        .read(scanControllerProvider.notifier)
        .scanImage(image.path);
    if (trip != null && mounted) {
      ref.read(activeTripProvider.notifier).state = trip;
      await ref.read(myTripsControllerProvider.notifier).loadTrips();
      if (mounted) {
        context.goNamed('dashboard');
      }
      return;
    }
    if (mounted) {
      _showScanError();
    }
  }

  void _showScanError() {
    final l10n = AppLocalizations.of(context)!;
    final error = ref
        .read(scanControllerProvider)
        .whenOrNull(error: (error, _) => error);
    final message = error == null
        ? l10n.scanValidateTicketError
        : localizeUserFacingError(error, l10n);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showQrPayloadSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final payload = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _ScanColors.buttonShell,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.scanPastePayload,
                style: const TextStyle(
                  color: _ScanColors.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: _ScanColors.title),
                decoration: InputDecoration(hintText: l10n.scanPayloadHint),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(l10n.validateTicket),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (payload == null || !context.mounted) return;
    await _handlePayload(payload);
  }
}

class _CameraPreview extends StatelessWidget {
  final ValueChanged<String> onPayloadDetected;

  const _CameraPreview({required this.onPayloadDetected});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final payload = capture.barcodes.isEmpty
            ? null
            : capture.barcodes.first.rawValue;
        if (payload != null && payload.isNotEmpty) {
          onPayloadDetected(payload);
        }
      },
      errorBuilder: (context, error) {
        return const _CameraPreviewPlaceholder();
      },
    );
  }
}

class _ScanAppBar extends StatelessWidget {
  final AppLocalizations l10n;

  const _ScanAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.goNamed('myTrips'),
            child: const SizedBox(
              width: 40,
              height: 36,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back,
                  color: _ScanColors.title,
                  size: 21,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.brandMosafer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ScanColors.title,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          const SizedBox(
            width: 40,
            height: 36,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(
                Icons.help_outline,
                color: _ScanColors.title,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTabs extends StatelessWidget {
  final AppLocalizations l10n;
  final bool showUpload;
  final VoidCallback onScanSelected;
  final VoidCallback onUploadSelected;

  const _ScanTabs({
    required this.l10n,
    required this.showUpload,
    required this.onScanSelected,
    required this.onUploadSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _ScanColors.tabBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScanTab(
              label: l10n.scanTabScanQr,
              isSelected: !showUpload,
              onTap: onScanSelected,
            ),
          ),
          Expanded(
            child: _ScanTab(
              label: l10n.scanTabUploadImage,
              isSelected: showUpload,
              onTap: onUploadSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScanTab({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? _ScanColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _ScanColors.background : _ScanColors.title,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadTicketPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final VoidCallback onUploadPressed;

  const _UploadTicketPanel({
    required this.l10n,
    required this.isLoading,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _ScanColors.buttonShell,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_search_outlined,
              color: _ScanColors.blue,
              size: 62,
            ),
            const SizedBox(height: 18),
            Text(
              l10n.scanUploadTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ScanColors.title,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.scanUploadBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ScanColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onUploadPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                isLoading ? l10n.scanChooseImageLoading : l10n.scanChooseImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewPlaceholder extends StatelessWidget {
  const _CameraPreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF101B20),
            Color(0xFF17232A),
            Color(0xFF233242),
            Color(0xFF080D14),
          ],
        ),
      ),
      child: CustomPaint(painter: _BlurredLightsPainter()),
    );
  }
}

class _BlurredLightsPainter extends CustomPainter {
  const _BlurredLightsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hazePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _ScanColors.blue.withValues(alpha: 0.58),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.45),
              radius: size.width * 0.62,
            ),
          );
    canvas.drawRect(Offset.zero & size, hazePaint);

    final lightPaint = Paint()..style = PaintingStyle.fill;
    final lights = [
      Offset(size.width * 0.35, size.height * 0.17),
      Offset(size.width * 0.71, size.height * 0.17),
      Offset(size.width * 0.08, size.height * 0.5),
      Offset(size.width * 0.53, size.height * 0.49),
      Offset(size.width * 0.96, size.height * 0.43),
    ];

    for (final light in lights) {
      lightPaint.color = Colors.white.withValues(alpha: 0.2);
      canvas.drawCircle(light, 12, lightPaint);
      lightPaint.color = _ScanColors.blue.withValues(alpha: 0.22);
      canvas.drawCircle(Offset(light.dx, light.dy + 105), 26, lightPaint);
    }

    final floorPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x884C3D2A), Color(0x11061326)],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.36,
              size.height * 0.5,
              90,
              size.height * 0.5,
            ),
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.37,
          size.height * 0.48,
          84,
          size.height * 0.43,
        ),
        const Radius.circular(18),
      ),
      floorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanOverlay extends StatelessWidget {
  final AppLocalizations l10n;

  const _ScanOverlay({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        const _ScannerFrame(),
        const SizedBox(height: 41),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Text(
            l10n.scanCenterQr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 222,
      height: 222,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _ScanColors.blue.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                  stops: const [0.27, 0.5, 0.73],
                ),
              ),
            ),
          ),
          const _FrameCorner(alignment: Alignment.topLeft),
          const _FrameCorner(alignment: Alignment.topRight),
          const _FrameCorner(alignment: Alignment.bottomLeft),
          const _FrameCorner(alignment: Alignment.bottomRight),
        ],
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  final Alignment alignment;

  const _FrameCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(
          painter: _CornerPainter(isLeft: isLeft, isTop: isTop),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;

  const _CornerPainter({required this.isLeft, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ScanColors.frame
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final horizontalEnd = isLeft ? size.width : 0.0;
    final verticalEnd = isTop ? size.height : 0.0;

    canvas.drawLine(Offset(x, y), Offset(horizontalEnd, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, verticalEnd), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanNowButton extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onPressed;
  final bool isLoading;

  const _ScanNowButton({
    required this.l10n,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _ScanColors.buttonShell,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: 45,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _ScanColors.blue,
            foregroundColor: _ScanColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.scanScanNow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ScanColors {
  _ScanColors._();

  static const Color background = Color(0xFF061326);
  static const Color title = Color(0xFFD5E4FF);
  static const Color blue = Color(0xFF4A91F8);
  static const Color muted = Color(0xFF8FA0BA);
  static const Color tabBackground = Color(0xFF2B3B55);
  static const Color frame = Color(0xFFBFD0FF);
  static const Color buttonShell = Color(0xFF1D2D47);
}
