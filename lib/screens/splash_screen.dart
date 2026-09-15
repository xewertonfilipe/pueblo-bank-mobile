import 'package:flutter/material.dart';

import '../app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.error, this.onRetry, super.key});

  final String? error;
  final VoidCallback? onRetry;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween(begin: 0.9, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                child: const Icon(Icons.account_balance,
                    size: 96, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pueblo Bank',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600)),
            if (widget.error != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(widget.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white)),
                onPressed: widget.onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
