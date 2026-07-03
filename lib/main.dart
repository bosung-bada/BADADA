import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = await AuthService.signInAnonymously();
  print('UID: ${user.uid}');

  runApp(const BadadaApp());
}

class BadadaApp extends StatelessWidget {
  const BadadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '바다다',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    MapPage(),
    RecordPage(),
    FriendsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.map), label: '지도'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: '기록'),
          NavigationDestination(icon: Icon(Icons.group), label: '친구'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      appBar: AppBar(title: const Text('바다다'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🌊 오늘의 해루질',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            infoCard('📍 현재 위치', '위치 정보 준비중'),
            infoCard('🌊 간조', '02:40'),
            infoCard('🌊 만조', '08:35'),
            infoCard('⭐ 해루질 점수', '85점'),
            const Spacer(),
            ElevatedButton(onPressed: () {}, child: const Text('🚨 SOS')),
            ElevatedButton(onPressed: () {}, child: const Text('📍 위치공유 시작')),
            ElevatedButton(onPressed: () {}, child: const Text('📝 오늘 기록하기')),
          ],
        ),
      ),
    );
  }
}

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('📝 기록 화면'));
}

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('👥 친구 화면'));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('⚙ 설정 화면'));
}