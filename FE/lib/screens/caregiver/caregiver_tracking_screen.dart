import 'package:flutter/material.dart';

class CaregiverTrackingScreen extends StatelessWidget {
  final VoidCallback onReceiptConfirmed;

  const CaregiverTrackingScreen({
    super.key,
    required this.onReceiptConfirmed,
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
