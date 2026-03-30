import 'dart:convert';
import 'dart:io' as io;
import '../utils/web_stub.dart' as web if (dart.library.js_interop) 'package:web/web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../utils/web_stub.dart';
import 'package:share_plus/share_plus.dart';

class QRDisplayDialog extends StatefulWidget {
  final String shopId;
  final String shopTitle;

  const QRDisplayDialog({
    super.key,
    required this.shopId,
    required this.shopTitle,
  });

  @override
  State<QRDisplayDialog> createState() => _QRDisplayDialogState();
}

class _QRDisplayDialogState extends State<QRDisplayDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  void _shareQR() async {
    setState(() => _isProcessing = true);
    try {
      final Uint8List? image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
      );

      if (image != null) {
        if (kIsWeb) {
          // Download on Web
          final base64Image = base64Encode(image);
          final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
          anchor.href = 'data:application/octet-stream;base64,$base64Image';
          anchor.download = 'shop_qr.png';
          anchor.click();
        } else {
          // Share on Mobile
          final directory = await getApplicationDocumentsDirectory();
          final imageFile = io.File('${directory.path}/shop_qr.png');
          await imageFile.writeAsBytes(image);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(imageFile.path)],
              subject: 'Town Seek Shop QR',
              text: 'Scan this QR code in the Town Seek app to view ${widget.shopTitle}!',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share QR code')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate JSON for QR
    final String qrData = jsonEncode({
      "app": "town_seek",
      "type": "shop",
      "id": widget.shopId,
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Shop QR Code",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.shopTitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white.withValues(alpha: 0.07),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_blue_t.png',
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Town Seek",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2962FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _shareQR,
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.share, color: Colors.white),
              label: Text(
                _isProcessing ? "Processing..." : "Share / Download QR",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF), // App Blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
