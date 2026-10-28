/// Widget logo Dr4oxBill.
///
/// Menampilkan ikon motor dengan teks "Dr4oxBill" dan "POS Dr4ox Motor".
/// Jika aset gambar logo tersedia di masa depan, dapat dengan mudah
/// diganti dengan Image.asset.
library logo_widget;

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 48, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4E79),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F4E79).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.motorcycle,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          const Text(
            'Dr4oxBill',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4E79),
            ),
          ),
          const Text(
            'POS Dr4ox Motor',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1F4E79),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget logo kecil untuk header aplikasi.
class AppLogoSmall extends StatelessWidget {
  const AppLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1F4E79),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.motorcycle,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Dr4oxBill',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4E79),
          ),
        ),
      ],
    );
  }
}
