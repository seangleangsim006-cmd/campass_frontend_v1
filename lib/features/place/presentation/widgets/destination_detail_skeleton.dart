import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DestinationDetailSkeleton extends StatefulWidget {
  const DestinationDetailSkeleton({super.key});

  @override
  State<DestinationDetailSkeleton> createState() =>
      _DestinationDetailSkeletonState();
}

class _DestinationDetailSkeletonState extends State<DestinationDetailSkeleton>
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
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
        child: CustomScrollView(
          key: const ValueKey('destination_detail_skeleton'),
          slivers: [
            const SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.border,
              flexibleSpace: FlexibleSpaceBar(
                background: ColoredBox(color: AppColors.border),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: [
                  _bar(width: 230, height: 30),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _bar(width: 180, height: 15),
                      const Spacer(),
                      _bar(width: 42, height: 15),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bar(width: 95, height: 12),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _bar(width: 78, height: 28, radius: 16),
                      const SizedBox(width: 8),
                      _bar(width: 88, height: 28, radius: 16),
                      const SizedBox(width: 8),
                      _bar(width: 72, height: 28, radius: 16),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _bar(width: 115, height: 12),
                  const SizedBox(height: 12),
                  _bar(width: 200, height: 22),
                  const SizedBox(height: 12),
                  _bar(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  _bar(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  _bar(width: 250, height: 14),
                  const SizedBox(height: 32),
                  _bar(width: 160, height: 22),
                  const SizedBox(height: 14),
                  _bar(width: double.infinity, height: 120, radius: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bar({
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
