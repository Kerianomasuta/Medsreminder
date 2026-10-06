import 'package:flutter/material.dart';

class CaregiverPharmacyScreen extends StatelessWidget {
  final VoidCallback onSendRefill;

  const CaregiverPharmacyScreen({
    super.key,
    required this.onSendRefill,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3F4F6),
      body: Center(
        child: Text(
          'Tính năng đang phát triển',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
