import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home/presentation/widgets/destination_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/user_profile.dart';
import '../../../../shared/widgets/skeleton_placeholder.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ProfileProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(provider.load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final strings = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.profileTitle,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 25),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Privacy and security',
                          onPressed: () =>
                              context.push(RouteNames.profilePrivacy),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (provider.isLoading && provider.profile == null)
                      const _ProfileSkeleton()
                    else if (provider.status == ProfileStatus.failure &&
                        provider.profile == null)
                      _ProfileLoadError(
                        message: provider.errorMessage ?? 'Please try again.',
                        onRetry: provider.load,
                      )
                    else if (provider.profile case final profile?)
                      _ProfileContent(
                        profile: profile,
                        onSelectTab: widget.onSelectTab,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPlaceholder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const ValueKey('profile_skeleton'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonPlaceholder.block(
                      width: 64,
                      height: 64,
                      radius: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonPlaceholder.block(width: 150, height: 18),
                          const SizedBox(height: 9),
                          SkeletonPlaceholder.block(width: 190, height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      Expanded(
                        child: SkeletonPlaceholder.block(
                          width: double.infinity,
                          height: 58,
                          radius: 12,
                        ),
                      ),
                      if (index < 2) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SkeletonPlaceholder.block(width: 135, height: 22),
          const SizedBox(height: 12),
          SkeletonPlaceholder.block(
            width: double.infinity,
            height: 150,
            radius: 18,
          ),
          const SizedBox(height: 28),
          SkeletonPlaceholder.block(width: 105, height: 22),
          const SizedBox(height: 12),
          SkeletonPlaceholder.block(
            width: double.infinity,
            height: 230,
            radius: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onSelectTab});

  final UserProfile profile;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          profile: profile,
          onEdit: () => context.push(RouteNames.profileEdit),
        ),
        const SizedBox(height: 26),
        Text('Your travel', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _TravelStatistics(profile: profile),
        const SizedBox(height: 28),
        _SectionHeading(
          title: 'Recent activity',
          actionLabel: 'Travel history',
          onAction: () => context.push(RouteNames.profileHistory),
        ),
        const SizedBox(height: 14),
        _RecentDestinations(destinations: profile.recentPlaces),
        const SizedBox(height: 28),
        Text('Account', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _AccountMenu(onSelectTab: onSelectTab),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Khmer Compass · Version 1.0.0',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.info_outline_rounded),
      title: const Text('Log out?'),
      content: const Text(
        'You will need to sign in again to access your account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await context.read<AuthRepository>().signOut();
      if (context.mounted) context.go(RouteNames.login);
    } on Exception catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: photoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.primary,
                  )
                : ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (profile.phoneNumber?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              profile.phoneNumber!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(160, 44),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelStatistics extends StatelessWidget {
  const _TravelStatistics({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    const statistics = [
      (icon: Icons.place_outlined, label: 'Places visited'),
      (icon: Icons.favorite_border, label: 'Saved places'),
      (icon: Icons.luggage_outlined, label: 'Trips planned'),
    ];
    final values = [
      profile.visitedPlaceCount,
      profile.savedPlaceCount,
      profile.plannedTripCount,
    ];
    return Row(
      children: [
        for (var index = 0; index < statistics.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(statistics[index].icon, color: AppColors.primary),
                  const SizedBox(height: 7),
                  Text(
                    '${values[index]}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statistics[index].label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _RecentDestinations extends StatelessWidget {
  const _RecentDestinations({required this.destinations});

  final List<ProfilePlace> destinations;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Places you mark as visited will appear here.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return SizedBox(
            width: 194,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (destination.imageUrl != null)
                    DestinationImage(
                      source: destination.imageUrl!,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildRecentPlaceFallback(),
                    )
                  else
                    _buildRecentPlaceFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          destination.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPlaceFallback() => ColoredBox(
    color: AppColors.primary.withValues(alpha: 0.12),
    child: const Center(
      child: Icon(Icons.landscape_outlined, color: AppColors.primary),
    ),
  );
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = [
      _MenuItem(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update personal information',
        onTap: () => context.push(RouteNames.profileEdit),
      ),
      _MenuItem(
        icon: Icons.luggage_outlined,
        title: 'My Trips',
        subtitle: 'View planned trips',
        onTap: () => context.push(RouteNames.profileTrips),
      ),
      _MenuItem(
        icon: Icons.favorite_border,
        title: 'Favorite Places',
        subtitle: 'View saved places',
        onTap: () => onSelectTab(3),
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        title: 'Travel History',
        subtitle: 'Previously visited places',
        onTap: () => context.push(RouteNames.profileHistory),
      ),
      _MenuItem(
        icon: Icons.language_rounded,
        title: strings.languageSettings,
        subtitle: 'Khmer, English, or Chinese',
        onTap: () => context.pushNamed(RouteNames.languageSelectionRouteName),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Manage notification preferences',
        onTap: () => context.push(RouteNames.profileNotifications),
      ),
      _MenuItem(
        icon: Icons.lock_outline_rounded,
        title: 'Privacy & Security',
        subtitle: 'Account and privacy settings',
        onTap: () => context.push(RouteNames.profilePrivacy),
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        subtitle: 'Get assistance',
        onTap: () => context.push(RouteNames.profileHelp),
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        title: 'About App',
        subtitle: 'Information and version',
        onTap: () => context.push(RouteNames.profileAbout),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 62, endIndent: 14),
            _AccountMenuItem(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}. ${item.subtitle}',
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
