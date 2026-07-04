import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onProfileSaved;

  const ProfileSetupScreen({
    super.key,
    required this.onProfileSaved,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController nicknameController = TextEditingController();

  Future<void> saveNickname() async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) return;

    await UserProfileService.saveProfile(
      nickname: nickname,
    );

    widget.onProfileSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      appBar: AppBar(
        title: const Text('프로필 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              'BADADA에서 사용할 닉네임을 입력하세요.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveNickname,
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}