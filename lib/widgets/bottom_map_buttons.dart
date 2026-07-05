import 'package:flutter/material.dart';

class BottomMapButtons extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onStartStop;
  final VoidCallback onSos;

  const BottomMapButtons({
    super.key,
    required this.isTracking,
    required this.onStartStop,
    required this.onSos,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: onSos,
              child: const Text(
                '🚨 SOS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onStartStop,
              child: Text(
                isTracking ? '🛑 해루질 종료' : '🟢 해루질 시작',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}