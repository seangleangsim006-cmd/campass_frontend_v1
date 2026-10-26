import 'package:flutter/material.dart';

import '../../data/onboarding_content.dart';

const _onboardingOrange = Color(0xFFFF6B00);

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({super.key, required this.page});

  final OnboardingContent page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (page.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        page.categoryIcon,
                        color: _onboardingOrange,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        page.category!,
                        style: const TextStyle(
                          color: Color(0xFF252525),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                page.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
