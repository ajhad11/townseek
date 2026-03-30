import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../data/shop_data.dart';
import '../widgets/shop_card.dart';
import 'shop_page.dart';
import 'service_details_page.dart';
import 'hospital_details_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  Future<void> _processQRCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final Map<String, dynamic> data = jsonDecode(code);
      if (data['app'] == 'town_seek' && data['type'] == 'shop' && data['id'] != null) {
        final String shopId = data['id'].toString();
        await _navigateToShop(shopId);
      } else {
        _showError('Invalid QR Code for Town Seek');
      }
    } catch (e) {
      _showError('Unrecognized QR format.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        cameraController.start(); 
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    
    // Pause live camera while picking an image
    cameraController.stop();

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        // User canceled, resume camera
        if (mounted) cameraController.start();
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final BarcodeCapture? capture = await cameraController.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        await _processQRCode(barcode.rawValue);
      } else {
        _showError('No QR code found in this image');
        if (mounted) {
           setState(() {
            _isProcessing = false;
          });
          cameraController.start();
        }
      }
    } catch (e) {
      _showError('Failed to analyze the image');
      if (mounted) {
         setState(() {
          _isProcessing = false;
        });
        cameraController.start();
      }
    }
  }

  Future<void> _navigateToShop(String shopId) async {
    Shop? shop;
    try {
      shop = ShopData.allShops.firstWhere(
        (s) => s.id?.toString() == shopId,
      );
    } catch (e) {
      shop = null;
    }

    if (shop == null) {
      _showError('Shop not found in local catalog.');
      return;
    }

    if (!mounted) return;

    bool isHospital = (shop.category?.toLowerCase() == 'hospital') || shop.tags.any((t) => ['Emergency', 'Pharmacy', 'OPD', 'Maternity', 'ICU', 'Pediatrics'].contains(t));

    // Pop the scanner page
    Navigator.pop(context);

    if (isHospital) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HospitalDetailsPage(shop: shop!),
        ),
      );
    } else if (shop.services != null && shop.services!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailsPage(shop: shop!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopPage(
            title: shop!.title,
            subtitle: shop.subtitle,
            rating: shop.rating,
            tags: shop.tags,
            imageUrl: shop.imageUrl,
            isOpen: shop.isOpen,
            openingTime: shop.openingTime,
            closingTime: shop.closingTime,
            googleMapsLink: shop.googleMapsLink,
            description: shop.description,
            location: shop.location,
            distance: "",
            phone: shop.phone,
            email: shop.email,
            latitude: shop.latitude,
            longitude: shop.longitude,
            workingDays: shop.workingDays,
            id: shop.id,
            ownerId: shop.ownerId,
            category: shop.category,
            openNowOverride: shop.openNowOverride,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Shop QR'),
        backgroundColor: const Color(0xFF2962FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Scan from Gallery',
            onPressed: () {
              if (!_isProcessing) {
                _scanFromGallery();
              }
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!_isProcessing) {
                  cameraController.stop(); 
                  _processQRCode(barcode.rawValue);
                  break; 
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (!_isProcessing)
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2962FF), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
        ],
      ),
    );
  }
}
