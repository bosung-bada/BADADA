import 'package:flutter/material.dart';

class TrackingPanel extends StatelessWidget {
  final bool isTracking;
  final Duration trackingDuration;
  final double totalDistance;
  final int trackPointCount;
  final int teamMemberCount;

  const TrackingPanel({
    super.key,
    required this.isTracking,
    required this.trackingDuration,
    required this.totalDistance,
    required this.trackPointCount,
    required this.teamMemberCount,
  });

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!isTracking) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🟢 해루질 중',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('⏱ 시간: ${formatDuration(trackingDuration)}'),
              Text(
                '🚶 이동거리: ${(totalDistance / 1000).toStringAsFixed(2)} km',
              ),
              Text('📍 기록 좌표: $trackPointCount개'),
              Text('👥 팀원: $teamMemberCount명'),
            ],
          ),
        ),
      ),
    );
  }
}