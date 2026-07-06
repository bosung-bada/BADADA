import 'dart:async';

import 'package:flutter/material.dart';

Future<bool> showSafetyCheckDialog({
  required BuildContext context,
  int countdownSeconds = 30,
}) async {
  bool isSafe = false;
  int seconds = countdownSeconds;
  bool canConfirm = false;
  Timer? timer;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          timer ??= Timer.periodic(
            const Duration(seconds: 1),
            (t) {
              if (seconds > 0) {
                setState(() {
                  seconds--;
                  if (seconds <= countdownSeconds - 3) {
                    canConfirm = true;
                  }
                });
              } else {
                t.cancel();
                Navigator.of(dialogContext).pop();
              }
            },
          );

          return AlertDialog(
            title: const Text('⚠️ 안전 확인'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '움직임이 감지되지 않았습니다.\n현재 안전하신가요?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '자동 SOS까지 $seconds초',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: canConfirm
                    ? () {
                        isSafe = true;
                        timer?.cancel();
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
                child: const Text('괜찮습니다'),
              ),
            ],
          );
        },
      );
    },
  );

  timer?.cancel();
  return isSafe;
}
