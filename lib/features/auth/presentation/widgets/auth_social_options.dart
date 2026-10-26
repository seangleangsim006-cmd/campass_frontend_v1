import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthSocialOptions extends StatelessWidget {
  const AuthSocialOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Or continue with',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialSignInButton(
                label: 'Google',
                logo: Image.asset(
                  'assets/image/google.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialSignInButton(
                label: 'Facebook',
                logo: Image.asset(
                  'assets/image/facebook.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
      ],
    );
  }
}

class _SocialSignInButton extends StatelessWidget {
  const _SocialSignInButton({required this.label, required this.logo});

  final String label;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('$label sign-in is not configured yet.')),
          );
      },
      icon: SizedBox(width: 20, height: 24, child: Center(child: logo)),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
