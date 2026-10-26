import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/models/home_event.dart';
import '../../../home/presentation/widgets/destination_image.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({required this.event, super.key});

  final HomeEvent event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: const Color(0xFF28636A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: const EdgeInsetsDirectional.fromSTEB(72, 0, 20, 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF28636A), Color(0xFF153B40)],
                      ),
                    ),
                  ),
                  if (event.imageUrl != null)
                    DestinationImage(source: event.imageUrl!)
                  else ...[
                    Positioned(
                      right: -28,
                      top: 24,
                      child: Icon(
                        Icons.celebration_outlined,
                        size: 230,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      top: 92,
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: Color(0xFFFFC56B),
                      ),
                    ),
                  ],
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x30000000),
                          Color(0x15000000),
                          Color(0xB8000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                if (event.isOngoing == true)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        Icons.circle,
                        size: 10,
                        color: Color(0xFF25875A),
                      ),
                      label: Text('Ongoing'),
                    ),
                  ),
                if (event.location.isNotEmpty) ...[
                  _EventInformationRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: event.location,
                  ),
                  const SizedBox(height: 14),
                ],
                if (event.nextStartsOn?.isNotEmpty == true) ...[
                  _EventInformationRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Next date',
                    value: event.nextStartsOn!,
                  ),
                  const SizedBox(height: 22),
                ],
                Text(
                  'About this event',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.description.isNotEmpty
                      ? event.description
                      : 'Event details are not available yet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInformationRow extends StatelessWidget {
  const _EventInformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
