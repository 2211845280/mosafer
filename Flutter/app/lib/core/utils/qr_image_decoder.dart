import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Tries to read a QR/barcode payload from a still image (gallery upload).
Future<String?> extractQrPayloadFromImage(XFile file) async {
  final path = file.path;
  if (path.isEmpty) {
    return null;
  }

  final controller = MobileScannerController();
  try {
    final capture = await controller.analyzeImage(path);
    if (capture == null || capture.barcodes.isEmpty) {
      return null;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}
