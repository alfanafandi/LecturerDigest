import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/screens/main_wrapper.dart';
import 'package:lecturer_digest/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for loading indicator
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _pulseAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Navigate based on Auth status after 3 seconds
    Timer(const Duration(seconds: 3), () {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Gradient Mesh simulation
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 100, spreadRadius: 100),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20), // Spacer
                  
                  // Identity Cluster
                  Column(
                    children: [
                      // Logo Box
                      const BrandLogo(size: 140, hasShadow: true),
                      const SizedBox(height: 48),
                      // Text Branding
                      Text(
                        'LectureDigest',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.onBackground,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'BELAJAR CERDAS, LEBIH MUDAH.',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          letterSpacing: 2.0, // wide tracking
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom Area
                  Column(
                    children: [
                      // Loading bar
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionalTranslation(
                              translation: Offset(_pulseAnimation.value, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primary, AppTheme.primaryContainer],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memproses materi...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.outlineVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      // Footer
                      Opacity(
                        opacity: 0.3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 32, height: 1, color: AppTheme.outlineVariant),
                            const SizedBox(width: 8),
                            const Text(
                              'V 2.0 ACADEMIC FLOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 32, height: 1, color: AppTheme.outlineVariant),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
