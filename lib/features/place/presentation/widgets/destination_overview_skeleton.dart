import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DestinationOverviewSkeleton extends StatefulWidget {
  const DestinationOverviewSkeleton({super.key});

  @override
  State<DestinationOverviewSkeleton> createState() =>
      _DestinationOverviewSkeletonState();
}

class _DestinationOverviewSkeletonState
    extends State<DestinationOverviewSkeleton>
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
          key: const ValueKey('destination_overview_skeleton'),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
              sliver: SliverList.list(
                children: [
                  _bar(width: 145, height: 16),
                  const SizedBox(height: 12),
                  _bar(width: 290, height: 14),
                  const SizedBox(height: 8),
                  _bar(width: 220, height: 14),
                  const SizedBox(height: 24),
                  _bar(width: 190, height: 22),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 226,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => Container(
                    width: 196,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: _bar(width: double.infinity, height: 132),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bar(width: 145, height: 15),
                              const SizedBox(height: 8),
                              _bar(width: 90, height: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
              sliver: SliverList.list(
                children: [
                  _bar(width: 150, height: 22),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _bar(width: 62, height: 32, radius: 16),
                      const SizedBox(width: 8),
                      _bar(width: 84, height: 32, radius: 16),
                      const SizedBox(width: 8),
                      _bar(width: 76, height: 32, radius: 16),
                    ],
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.builder(
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 212,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _bar(width: double.infinity, height: 116),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bar(width: 140, height: 15),
                            const SizedBox(height: 8),
                            _bar(width: 80, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
              sliver: SliverList.list(
                children: [
                  _bar(width: 120, height: 22),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 126,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) => Container(
                        width: 164,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
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
