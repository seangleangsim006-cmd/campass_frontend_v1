import 'package:flutter/material.dart';

const _onboardingOrange = Color(0xFFFF6B00);

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 5),
          width: index == currentPage ? 22 : 7,
          height: 5,
          decoration: BoxDecoration(
            color: index == currentPage ? _onboardingOrange : Colors.white70,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
