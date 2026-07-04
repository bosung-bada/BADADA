import 'package:flutter/material.dart';

import '../models/sos_event.dart';

Future<void> showSosPopup({
  required BuildContext context,
  required SosEvent sos,
  required VoidCallback onMoveToMap,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: const Text('🚨 긴급 구조 요청'),
        content: Text(
          '${sos.name}님이 SOS를 보냈습니다.\n\n즉시 위치를 확인하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMoveToMap();
            },
            child: const Text('지도 보기'),
          ),
        ],
      );
    },
  );
}