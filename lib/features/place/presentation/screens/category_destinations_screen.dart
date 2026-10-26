import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/mock/home_content.dart';
import '../../../home/data/repositories/api_place_repository.dart';
import '../../../home/domain/repositories/place_repository.dart';
import '../../../home/presentation/widgets/destination_image.dart';
import '../../../../shared/widgets/skeleton_placeholder.dart';

class CategoryDestinationsScreen extends StatefulWidget {
  const CategoryDestinationsScreen({
    required this.category,
    this.placeRepository,
    super.key,
  });

  final String category;
  final PlaceRepository? placeRepository;

  @override
  State<CategoryDestinationsScreen> createState() =>
      _CategoryDestinationsScreenState();
}

class _CategoryDestinationsScreenState
    extends State<CategoryDestinationsScreen> {
  late Future<List<HomeDestination>> _destinations;

  PlaceRepository get _repository =>
      widget.placeRepository ?? ApiPlaceRepository(ApiClient());

  @override
  void initState() {
    super.initState();
    _destinations = _repository.loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeDestination>>(
      future: _destinations,
      builder: (context, snapshot) {
        final category = widget.category;
        final normalizedCategory = category.toLowerCase().replaceAll(
          RegExp(r's$'),
          '',
        );
        final destinations =
            snapshot.data
                ?.where(
                  (destination) =>
                      destination.categorySlug?.toLowerCase() ==
                          normalizedCategory ||
                      destination.category.toLowerCase() ==
                          category.toLowerCase(),
                )
                .toList() ??
            const <HomeDestination>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(category),
            backgroundColor: AppColors.background,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const _CategoryDestinationsSkeleton()
              : snapshot.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load places. Please try again.'),
                      TextButton(
                        onPressed: () => setState(
                          () => _destinations = _repository.loadPlaces(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : destinations.isEmpty
              ? Center(child: Text('No destinations found in $category.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: destinations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => _CategoryDestinationCard(
                    destination: destinations[index],
                  ),
                ),
        );
      },
    );
  }
}

class _CategoryDestinationsSkeleton extends StatelessWidget {
  const _CategoryDestinationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPlaceholder(
      child: ListView.separated(
        key: const ValueKey('category_destinations_skeleton'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SkeletonPlaceholder.block(width: 138, height: double.infinity, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonPlaceholder.block(width: 80, height: 11),
                    const Spacer(),
                    SkeletonPlaceholder.block(width: 150, height: 18),
                    const SizedBox(height: 8),
                    SkeletonPlaceholder.block(width: 185, height: 12),
                    const SizedBox(height: 8),
                    SkeletonPlaceholder.block(width: 210, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDestinationCard extends StatelessWidget {
  const _CategoryDestinationCard({required this.destination});

  final HomeDestination destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 140,
        child: InkWell(
          onTap: () => context.push(
            RouteNames.destinationDetails.replaceFirst(
              ':destination',
              Uri.encodeComponent(destination.key),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 118,
                height: double.infinity,
                child: _DestinationArtwork(destination: destination),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              destination.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFE2A747),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        destination.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationArtwork extends StatelessWidget {
  const _DestinationArtwork({required this.destination});

  final HomeDestination destination;

  @override
  Widget build(BuildContext context) {
    final imageAsset = destination.imageAsset;
    if (imageAsset != null) {
      return DestinationImage(
        source: imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildIllustration(),
      );
    }
    return _buildIllustration();
  }

  Widget _buildIllustration() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [destination.accent, AppColors.neutral],
        ),
      ),
      child: Center(
        child: Icon(
          destination.icon,
          size: 48,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
