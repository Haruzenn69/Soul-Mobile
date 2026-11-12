import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';

/// Halaman scanner QR built-in dengan tampilan viewfinder modern,
/// kontrol flashlight, tombol switch kamera, dan efek bingkai pemindai yang elegan.
class InAppQrScannerScreen extends StatefulWidget {
  const InAppQrScannerScreen({super.key});

  @override
  State<InAppQrScannerScreen> createState() => _InAppQrScannerScreenState();
}

class _InAppQrScannerScreenState extends State<InAppQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    autoStart: true,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Menangani hasil deteksi barcode/QR code dari kamera
  void _handleDetection(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    _controller.stop();
    if (!mounted) return;
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Flashlight',
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Ganti Kamera',
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
        title: Text(
          'Scan QR Kehadiran',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Widget kamera full-screen mobile scanner
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
          ),
          // Lapisan overlay gelap dengan bingkai transparan di tengah (Center sejajar dengan kotak scanner)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dst,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bingkai dekoratif luar agar presisi tepat di tengah layar
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.blue, width: 3.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _cornerIndicator(true, true),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _cornerIndicator(true, false),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _cornerIndicator(false, true),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _cornerIndicator(false, false),
                  ),
                ],
              ),
            ),
          ),
          // Label teks panduan di bawah kotak scanner secara absolut
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Arahkan kamera ke QR code siswa',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper untuk membuat sudut indikator kotak scanner
  Widget _cornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3.5) : BorderSide.none,
        ),
      ),
    );
  }
}
