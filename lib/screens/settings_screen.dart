import 'package:flutter/material.dart';

import '../services/safety_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoSosEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final enabled = await SafetySettingsService.isAutoSosEnabled();

    if (!mounted) return;

    setState(() {
      autoSosEnabled = enabled;
      isLoading = false;
    });
  }

  Future<void> updateAutoSos(bool value) async {
    await SafetySettingsService.setAutoSosEnabled(value);

    if (!mounted) return;

    setState(() {
      autoSosEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('🛟 자동 SOS'),
            subtitle: const Text('무이동 감지 후 응답이 없으면 자동으로 SOS를 전송합니다.'),
            value: autoSosEnabled,
            onChanged: updateAutoSos,
          ),
        ],
      ),
    );
  }
}