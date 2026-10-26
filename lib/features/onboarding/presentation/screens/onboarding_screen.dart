import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/route_names.dart';
import '../../data/onboarding_content.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_page_indicator.dart';

const _onboardingOrange = Color(0xFFFF6B00);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _onboardingCompletedKey = 'onboarding_completed';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == OnboardingContent.pages.length - 1;

  void _goToPage(int index) {
    if (index < 0 || index >= OnboardingContent.pages.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_onboardingCompletedKey, true);
    if (!saved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save onboarding progress.')),
      );
      return;
    }
    if (mounted) {
      context.go('${RouteNames.languageSelection}?require_auth=true');
    }
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _goToPage(_currentPage + 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = OnboardingContent.pages[_currentPage];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: Image.network(
                page.imageAsset,
                key: ValueKey(page.imageAsset),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF52717C),
                            Color(0xFF203F46),
                            Color(0xFF0F292D),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Colors.transparent,
                      Color(0x33000000),
                      Color(0xE6000000),
                    ],
                    stops: [0, 0.28, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (_currentPage == 0)
                          const Expanded(child: _CambodiaBrand())
                        else
                          const Spacer(),
                        TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: OnboardingContent.pages.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          child: OnboardingPageContent(
                            page: OnboardingContent.pages[index],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        OnboardingPageIndicator(
                          pageCount: OnboardingContent.pages.length,
                          currentPage: _currentPage,
                        ),
                        const Spacer(),
                        _NavigationButton(
                          isLastPage: _isLastPage,
                          onPressed: _nextPage,
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight < 600 ? 4 : 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CambodiaBrand extends StatelessWidget {
  const _CambodiaBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.temple_buddhist_rounded,
            color: _onboardingOrange,
            size: 27,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambodia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Explore · Discover · Experience',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({required this.isLastPage, required this.onPressed});

  final bool isLastPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isLastPage ? 'Get Started' : 'Next';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: _onboardingOrange,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
