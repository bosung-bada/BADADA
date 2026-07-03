import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    return userCredential.user!;
  }

  static User? get currentUser => _auth.currentUser;
}