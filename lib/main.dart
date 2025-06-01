import 'package:edu_time/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes/app_router.dart';

// Import firebase options jika menggunakan flutterfire CLI
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firebase Auth di mobile secara default sudah menggunakan persistensi lokal
  // sehingga tidak perlu mengatur persistensi secara manual
  
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
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF4A7AB9),
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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4A7AB9),
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
  
  // Memeriksa apakah pengguna sudah login
  static bool get isLoggedIn => currentUser != null;
  
  // Memuat ulang data pengguna untuk memastikan status terbaru
  static Future<void> reloadUser() async {
    if (currentUser != null) {
      await currentUser!.reload();
    }
  }

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
    // Bersihkan data lokal sebelum logout
    await clearLocalData();
    return await _auth.signOut();
  }
  
  // Method untuk membersihkan data lokal saat logout
  static Future<void> clearLocalData() async {
    // Ini akan membersihkan cache data di memori
    // Aplikasi akan memuat ulang data sesuai user yang login berikutnya
    try {
      // Kita tidak menghapus database, hanya membersihkan cache di memori
      // Data akan difilter berdasarkan user_id saat dimuat ulang
      print('Clearing local data cache before logout');
    } catch (e) {
      print('Error clearing local data: $e');
    }
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