import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class InAppQrScannerScreen extends StatefulWidget {
  const InAppQrScannerScreen({super.key});

  @override
  State<InAppQrScannerScreen> createState() => _InAppQrScannerScreenState();
}

class _InAppQrScannerScreenState extends State<InAppQrScannerScreen> {
  final TextEditingController _nisController = TextEditingController();

  @override
  void dispose() {
    _nisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR Kartu Pelajar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.blue, width: 3.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          color: AppTheme.blue,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Arahkan kamera ke QR code Kartu Pelajar siswa\natau masukkan NIS secara manual di bawah',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                TextField(
                  controller: _nisController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    hintText: 'Masukkan NIS / Kode Kartu Pelajar',
                    hintStyle: const TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppTheme.blue, size: 28),
                      onPressed: () {
                        final val = _nisController.text.trim();
                        if (val.isNotEmpty) {
                          Navigator.pop(context, val);
                        }
                      },
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      Navigator.pop(context, val.trim());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
