import 'package:go_router/go_router.dart';
import '../screens/login/splash_screen.dart';
import '../screens/login/welcome_screen.dart';
import '../screens/login/auth_screen.dart';
import '../screens/homepage.dart';
import '../screens/jadwal_perkuliahan.dart';
import '../screens/jadwal_kerja_kelompok.dart';
import '../screens/settings.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_email_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/about_screen.dart';
import '../screens/faq_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => WelcomeScreen()),
      GoRoute(path: '/auth', builder: (_, __) => AuthScreen()),
      GoRoute(path: '/homepage', builder: (_, __) => Homepage()),
      GoRoute(path: '/jadwal-perkuliahan', builder: (_, __) => JadwalPerkuliahan()),
      GoRoute(path: '/jadwal-kerja-kelompok', builder: (_, __) => JadwalKerjaKelompok()),
      GoRoute(path: '/settings', builder: (_, __) => SettingsPage()),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/email',
        builder: (context, state) => ChangeEmailScreen(),
      ),
      GoRoute(
        path: '/settings/password',
        builder: (context, state) => ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/help',
        builder: (context, state) => HelpCenterScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => FAQScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => AboutScreen(),
      ),
    ],
  );
}
