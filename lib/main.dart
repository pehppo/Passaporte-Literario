import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'dart:io'; // Para checar plataforma
import 'package:window_size/window_size.dart'; // Para controlar tamanho da janela

// Notifier global para tema em tempo real
ValueNotifier<String> temaNotifier = ValueNotifier('Sistema');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start in a mode that shows only the status bar (top) and hides the
  // system navigation (bottom) so the app appears full-screen without
  // the soft navigation buttons.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

  // Optional: make status/navigation bar icons use light content for dark background
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: const Color(0xFF141425),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Configura janela no desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Passaporte Literário');
    setWindowMinSize(const Size(360, 780));
    setWindowMaxSize(const Size(360, 780));
    setWindowFrame(const Rect.fromLTWH(100, 100, 360, 780)); // x, y, width, height
  }

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final savedTheme = prefs.getString('selectedTheme') ?? 'Sistema';
  temaNotifier.value = savedTheme;

  runApp(PassaporteApp(isLoggedIn: isLoggedIn));
}

class PassaporteApp extends StatelessWidget {
  final bool isLoggedIn;
  const PassaporteApp({super.key, required this.isLoggedIn});

  ThemeMode _themeMode(String tema) {
    switch (tema) {
      case 'Claro':
        return ThemeMode.light;
      case 'Escuro':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: temaNotifier,
      builder: (context, temaAtual, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0066FF),
            scaffoldBackgroundColor: const Color(0xFFF0F0F0),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0066FF),
            scaffoldBackgroundColor: const Color(0xFF141425),
          ),
          themeMode: _themeMode(temaAtual),
          home: SplashScreen(isLoggedIn: isLoggedIn),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF141425),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: SizedBox(
            height: screenHeight * 0.6,
            width: screenWidth * 0.6,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
