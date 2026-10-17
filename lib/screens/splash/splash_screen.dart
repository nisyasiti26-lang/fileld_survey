import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // WARNA TEMA PINK
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFBE185D);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color backgroundPink = Color(0xFFFFF7FB);

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFCE7F3),
              Color(0xFFFBCFE8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IKON APLIKASI
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: primaryPink,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment,
                  size: 75,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              // NAMA APLIKASI
              const Text(
                'Field Survey',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkPink,
                ),
              ),

              const SizedBox(height: 10),

              // DESKRIPSI APLIKASI
              const Text(
                'Aplikasi Mobile Berbasis Flutter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9D174D),
                ),
              ),

              const SizedBox(height: 35),

              // LOADING
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryPink,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Memuat aplikasi...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFBE185D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
