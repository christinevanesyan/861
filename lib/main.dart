import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CasinoCompanionApp());
}

class CasinoCompanionApp extends StatelessWidget {
  const CasinoCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casino Companion: Total Manager',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final storage = StorageService();
    final isFirstLaunch = await storage.isFirstLaunch();

    // Add a small delay for splash screen
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isFirstLaunch
              ? const OnboardingScreen()
              : const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.casino,
              size: 80,
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: 24),
            Text(
              'CASINO COMPANION',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'TOTAL MANAGER',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.accentBlue,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
