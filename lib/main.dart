import 'package:edu_time/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes/app_router.dart';

// Import firebase options jika menggunakan flutterfire CLI
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  
  runApp(const EduTimeApp());
}

class EduTimeApp extends StatelessWidget {
  const EduTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        fontFamily: 'Roboto',
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}

// Tambahkan class AuthService untuk mempermudah penggunaan Firebase Auth di seluruh aplikasi
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan user saat ini
  static User? get currentUser => _auth.currentUser;

  // Stream untuk mendengarkan perubahan state otentikasi
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method login
  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Method register
  static Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Method logout
  static Future<void> signOut() async {
    return await _auth.signOut();
  }

  // Method reset password
  static Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  // Method update email
  static Future<void> updateEmail(String newEmail) async {
    User? user = currentUser;
    if (user != null) {
      return await user.updateEmail(newEmail);
    }
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user is currently signed in',
    );
  }

  // Method update password
  static Future<void> updatePassword(String newPassword) async {
    User? user = currentUser;
    if (user != null) {
      return await user.updatePassword(newPassword);
    }
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user is currently signed in',
    );
  }

  // Method reauthenticate
  static Future<UserCredential> reauthenticate(String email, String password) async {
    User? user = currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await user.reauthenticateWithCredential(credential);
    }
    throw FirebaseAuthException(
      code: 'no-user',
      message: 'No user is currently signed in',
    );
  }
}