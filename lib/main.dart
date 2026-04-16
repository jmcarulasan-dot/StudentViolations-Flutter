import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/violation_provider.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guard_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/sao_dashboard.dart';
import 'screens/guidance_dashboard.dart';
import 'models/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Required before using async in main
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseService.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// ── Official ACLC College of Mandaue Brand Colors ─────────────────────────────
class ACLCColors {
  static const red       = Color(0xFFFD070C);
  static const navy      = Color(0xFF0F136E);
  static const navyLight = Color(0xFF1A1F8F);
  static const redDark   = Color(0xFFB80004);
  static const white     = Colors.white;
  static const gray      = Color(0xFFF5F7FA);
  static const cardBg    = Color(0xFFFFFFFF);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ViolationProvider()),
      ],
      child: MaterialApp(
        title: 'ACLC Student Violation System',
        debugShowCheckedModeBanner: false,
        // Start at splash to check session before going to login or dashboard
        home: const SplashScreen(),
        routes: {
          '/login':     (context) => const LoginScreen(),
          '/register':  (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardWrapper(),
        },
        theme: ThemeData(
          useMaterial3: true,

          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: ACLCColors.navy,
            onPrimary: Colors.white,
            secondary: ACLCColors.navy,
            onSecondary: Colors.white,
            error: ACLCColors.red,
            onError: Colors.white,
            surface: ACLCColors.cardBg,
            onSurface: Colors.black87,
            background: ACLCColors.gray,
            onBackground: Colors.black87,
          ),

          scaffoldBackgroundColor: ACLCColors.gray,

          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 3,
            backgroundColor: ACLCColors.navy,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            shadowColor: ACLCColors.navy,
          ),

          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: ACLCColors.cardBg,
            surfaceTintColor: ACLCColors.cardBg,
            shadowColor: ACLCColors.navy.withOpacity(0.15),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: ACLCColors.navy,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: ACLCColors.navy.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: ACLCColors.navy,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: ACLCColors.navy,
              side: const BorderSide(color: ACLCColors.navy, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
            prefixIconColor: ACLCColors.navy,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE1EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ACLCColors.navy, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ACLCColors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),

          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey.shade100,
            selectedColor: ACLCColors.navy.withOpacity(0.15),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ACLCColors.navy,
            ),
            side: const BorderSide(color: ACLCColors.navy, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: ACLCColors.navy,
            foregroundColor: Colors.white,
            elevation: 4,
          ),

          dividerTheme: DividerThemeData(
            color: Colors.grey.shade200,
            thickness: 1,
          ),

          snackBarTheme: SnackBarThemeData(
            backgroundColor: ACLCColors.navy,
            contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
            bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
            titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: ACLCColors.navy),
            titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: ACLCColors.navy),
            titleSmall: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: ACLCColors.navy),
            labelLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 0.8),
          ),
        ),
      ),
    );
  }
}

// ── Splash Screen — checks saved session before routing ───────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user was previously logged in
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.currentUser != null) {
      // User session found — go directly to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // No session — go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show ACLC logo while checking session
    return const Scaffold(
      backgroundColor: Color(0xFF0F136E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'ACLC Student Violation System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Router ──────────────────────────────────────────────────────────
class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const LoginScreen();
        switch (user.role) {
          case UserRole.guard:    return const GuardDashboard();
          case UserRole.student:  return const StudentDashboard();
          case UserRole.sao:      return const SAODashboard();
          case UserRole.guidance: return const GuidanceDashboard();
          default:                return const LoginScreen();
        }
      },
    );
  }
}