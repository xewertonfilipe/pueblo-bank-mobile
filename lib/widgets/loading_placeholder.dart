import 'package:flutter/material.dart';

class LoadingPlaceholder extends StatefulWidget {
  const LoadingPlaceholder({
    required this.width,
    required this.height,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<LoadingPlaceholder> createState() => _LoadingPlaceholderState();
}

class _LoadingPlaceholderState extends State<LoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
