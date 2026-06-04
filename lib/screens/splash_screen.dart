import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_card.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Route to Login page after 3 seconds
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tosca,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenH = constraints.maxHeight;
          final double centerY = screenH / 2;
          const double logoSize = 110.0;
          const double bandHeight = 70.0;
          const double logoHalf = logoSize / 2;
          const double bandHalf = bandHeight / 2;

          return Stack(
            children: [
              // 1. Cream band — center of band = screen vertical center
              Positioned(
                top: centerY - bandHalf,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  height: bandHeight,
                  color: AppColors.creamBand,
                ),
              ),

              // 2. Logo card — center of logo = screen vertical center (ON the band)
              Positioned(
                top: centerY - logoHalf,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Center(child: LogoCard(size: logoSize)),
                ),
              ),

              // 3. Brand text + slogan — below the logo
              Positioned(
                top: centerY + logoHalf + 22,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        "PresGo",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Hadir Tepat, Pasti Tercatat",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Loading indicator at bottom
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
