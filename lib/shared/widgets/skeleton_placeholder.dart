import 'package:flutter/material.dart';

class SkeletonPlaceholder extends StatefulWidget {
  const SkeletonPlaceholder({required this.child, super.key});

  final Widget child;

  @override
  State<SkeletonPlaceholder> createState() => _SkeletonPlaceholderState();

  static Widget block({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonPlaceholderState extends State<SkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.5 + 3 * progress, 0),
            end: Alignment(-0.5 + 3 * progress, 0),
            colors: const [
              Color(0xFFDCE3E4),
              Color(0xFFF4F7F7),
              Color(0xFFDCE3E4),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
