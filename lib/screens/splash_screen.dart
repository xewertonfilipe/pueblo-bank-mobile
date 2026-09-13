import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../firebase_options.dart';
import '../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scale = Tween(begin: 0.9, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await FirebaseAppCheck.instance.activate(providerAndroid: const AndroidDebugProvider());
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível conectar. Verifique sua internet e tente novamente.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: const Icon(Icons.account_balance, size: 96, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pueblo Bank', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: _bootstrap,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
