import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum HomeSkeletonType {
  event,
  destinations,
  destinationGrid,
  phrase,
  phraseList,
  phraseCarousel,
}

class HomeContentSkeleton extends StatefulWidget {
  const HomeContentSkeleton({required this.type, super.key});

  final HomeSkeletonType type;

  @override
  State<HomeContentSkeleton> createState() => _HomeContentSkeletonState();
}

class _HomeContentSkeletonState extends State<HomeContentSkeleton>
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
      child: _buildSkeleton(),
    );
  }

  Widget _buildSkeleton() {
    return switch (widget.type) {
      HomeSkeletonType.event => _eventSkeleton(),
      HomeSkeletonType.destinations => _destinationsSkeleton(),
      HomeSkeletonType.destinationGrid => _destinationGridSkeleton(),
      HomeSkeletonType.phrase => _phraseSkeleton(),
      HomeSkeletonType.phraseList => _phraseListSkeleton(),
      HomeSkeletonType.phraseCarousel => _phraseCarouselSkeleton(),
    };
  }

  Widget _eventSkeleton() {
    return Container(
      key: const ValueKey('home_event_skeleton'),
      height: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 115, height: 12),
          const Spacer(),
          _bar(width: 190, height: 23),
          const SizedBox(height: 9),
          _bar(width: 130, height: 12),
          const SizedBox(height: 10),
          _bar(width: double.infinity, height: 10),
        ],
      ),
    );
  }

  Widget _destinationsSkeleton() {
    return SizedBox(
      key: const ValueKey('home_destinations_skeleton'),
      height: 272,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) => Container(
          width: 274,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 82, height: 25, radius: 16),
              const Spacer(),
              _bar(width: 145, height: 12),
              const SizedBox(height: 8),
              _bar(width: 190, height: 20),
              const SizedBox(height: 7),
              _bar(width: 220, height: 11),
            ],
          ),
        ),
      ),
    );
  }

  Widget _destinationGridSkeleton() {
    return SizedBox(
      key: const ValueKey('home_destination_grid_skeleton'),
      height: 248,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 170,
        ),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _bar(width: 104, height: 16),
              const SizedBox(height: 7),
              _bar(width: 76, height: 11),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phraseSkeleton() {
    return Column(
      key: const ValueKey('home_phrase_skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(width: 220, height: 23),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 160, height: 18),
              const SizedBox(height: 14),
              _bar(width: 190, height: 26),
              const SizedBox(height: 12),
              _bar(width: 125, height: 14),
              const SizedBox(height: 7),
              _bar(width: 145, height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phraseListSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(width: 190, height: 24),
        const SizedBox(height: 16),
        for (var index = 0; index < 4; index++) ...[
          Container(
            height: 170,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 160, height: 18),
                const SizedBox(height: 14),
                _bar(width: 190, height: 26),
                const SizedBox(height: 12),
                _bar(width: 125, height: 14),
                const SizedBox(height: 7),
                _bar(width: 145, height: 12),
              ],
            ),
          ),
          if (index < 3) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _phraseCarouselSkeleton() {
    return SizedBox(
      key: const ValueKey('home_phrase_carousel_skeleton'),
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 280,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 160, height: 18),
              const SizedBox(height: 14),
              _bar(width: 190, height: 26),
              const SizedBox(height: 12),
              _bar(width: 125, height: 14),
              const SizedBox(height: 7),
              _bar(width: 145, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar({
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
