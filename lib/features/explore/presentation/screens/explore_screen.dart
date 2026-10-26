import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/repositories/api_destination_repository.dart';
import '../../../home/data/repositories/api_place_repository.dart';
import '../../../home/data/mock/home_content.dart';
import '../../../home/domain/models/destination.dart';
import '../../../home/domain/repositories/destination_repository.dart';
import '../../../home/presentation/widgets/destination_image.dart';
import '../../../../shared/widgets/skeleton_placeholder.dart';

typedef DestinationLoader = Future<List<HomeDestination>> Function();

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    required this.savedDestinations,
    required this.onToggleFavorite,
    this.loadDestinations,
    this.destinationRepository,
    super.key,
  });

  final Set<String> savedDestinations;
  final ValueChanged<HomeDestination> onToggleFavorite;
  final DestinationLoader? loadDestinations;
  final DestinationRepository? destinationRepository;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  late final DestinationRepository _destinationRepository;
  List<HomeDestination> _destinations = const [];
  List<Destination> _availableDestinations = const [];
  Set<String>? _selectedPlaceSlugs;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _selectedDestinationSlug;
  double _minimumRating = 0;
  _DestinationSort _sort = _DestinationSort.recommended;
  bool _isLoading = true;
  bool _isLoadingAvailableDestinations = true;
  bool _isLoadingDestinationPlaces = false;
  String? _errorMessage;
  String? _availableDestinationsError;
  String? _destinationPlacesError;

  @override
  void initState() {
    super.initState();
    _destinationRepository =
        widget.destinationRepository ?? ApiDestinationRepository(ApiClient());
    _loadDestinations();
    _loadAvailableDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loader =
          widget.loadDestinations ?? ApiPlaceRepository(ApiClient()).loadPlaces;
      final destinations = await loader();
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load places. Please try again.';
      });
    }
  }

  Future<void> _loadAvailableDestinations() async {
    setState(() {
      _isLoadingAvailableDestinations = true;
      _availableDestinationsError = null;
    });

    try {
      final destinations = await _destinationRepository.loadDestinations();
      if (!mounted) return;
      setState(() {
        _availableDestinations = destinations;
        _isLoadingAvailableDestinations = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingAvailableDestinations = false;
        _availableDestinationsError = error.toString();
      });
    }
  }

  Future<void> _selectDestination(
    Destination? destination, {
    bool forceReload = false,
  }) async {
    if (destination == null) {
      setState(() {
        _selectedDestinationSlug = null;
        _selectedPlaceSlugs = null;
        _destinationPlacesError = null;
        _isLoadingDestinationPlaces = false;
      });
      return;
    }
    if (_selectedDestinationSlug == destination.slug &&
        !_isLoadingDestinationPlaces &&
        !forceReload) {
      return;
    }

    setState(() {
      _selectedDestinationSlug = destination.slug;
      _selectedPlaceSlugs = null;
      _destinationPlacesError = null;
      _isLoadingDestinationPlaces = true;
    });

    try {
      final details = await _destinationRepository.loadDestination(
        destination.slug,
      );
      if (!mounted || _selectedDestinationSlug != destination.slug) return;
      setState(() {
        _selectedPlaceSlugs = details.places.map((place) => place.slug).toSet();
        _isLoadingDestinationPlaces = false;
      });
    } on Exception catch (error) {
      if (!mounted || _selectedDestinationSlug != destination.slug) return;
      setState(() {
        _destinationPlacesError = error.toString();
        _isLoadingDestinationPlaces = false;
      });
    }
  }

  List<HomeDestination> get _visibleDestinations {
    final query = _searchQuery.trim().toLowerCase();
    final results = _destinations.where((destination) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          destination.category.toLowerCase() ==
              _selectedCategory.toLowerCase() ||
          destination.categorySlug?.toLowerCase() ==
              _selectedCategory.toLowerCase().replaceAll(RegExp(r's$'), '');
      final matchesDestination =
          _selectedPlaceSlugs == null ||
          _selectedPlaceSlugs!.contains(destination.key);
      final matchesSearch =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query) ||
          destination.category.toLowerCase().contains(query);
      final matchesRating =
          (double.tryParse(destination.rating) ?? 0) >= _minimumRating;
      return matchesCategory &&
          matchesDestination &&
          matchesSearch &&
          matchesRating;
    }).toList();

    switch (_sort) {
      case _DestinationSort.recommended:
        break;
      case _DestinationSort.highestRated:
        results.sort(
          (a, b) => double.parse(b.rating).compareTo(double.parse(a.rating)),
        );
      case _DestinationSort.name:
        results.sort((a, b) => a.name.compareTo(b.name));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...homeCategories.map((category) => category.filterCategory),
    ];
    final destinations = _visibleDestinations;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Cambodia',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Find places that make your journey unforgettable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search places...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: AppColors.border),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Destination',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildDestinationFilters(),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showAdvancedFilters,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Advanced filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Places',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!_isLoading && _errorMessage == null)
                      Text(
                        '${destinations.length} ${destinations.length == 1 ? 'place' : 'places'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  const _ExploreDestinationSkeleton(),
                  if (index < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          )
        else if (_destinationPlacesError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ExploreMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load destination places',
              message: _destinationPlacesError!,
              actionLabel: 'Try again',
              onAction: () {
                final selectedDestination = _availableDestinations
                    .where(
                      (destination) =>
                          destination.slug == _selectedDestinationSlug,
                    )
                    .firstOrNull;
                if (selectedDestination != null) {
                  _selectDestination(selectedDestination, forceReload: true);
                }
              },
            ),
          )
        else if (_isLoadingDestinationPlaces)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  const _ExploreDestinationSkeleton(),
                  if (index < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          )
        else if (_errorMessage != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ExploreMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load places',
              message: _errorMessage!,
              actionLabel: 'Try again',
              onAction: _loadDestinations,
            ),
          )
        else if (destinations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ExploreMessage(
              icon: Icons.search_off_rounded,
              title: 'No places found',
              message: 'Try changing your search or filters.',
              actionLabel: 'Clear filters',
              onAction: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _selectedDestinationSlug = null;
                  _selectedPlaceSlugs = null;
                  _destinationPlacesError = null;
                  _minimumRating = 0;
                  _sort = _DestinationSort.recommended;
                });
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 900
                    ? 4
                    : width >= 620
                    ? 3
                    : 2;
                return SliverGrid.builder(
                  itemCount: destinations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.69,
                  ),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return _ExploreDestinationCard(
                      destination: destination,
                      isFavorite: widget.savedDestinations.contains(
                        destination.key,
                      ),
                      onToggleFavorite: () =>
                          widget.onToggleFavorite(destination),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDestinationFilters() {
    if (_isLoadingAvailableDestinations) {
      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final width in [120.0, 94.0, 108.0])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkeletonPlaceholder(
                  child: SkeletonPlaceholder.block(
                    width: width,
                    height: 36,
                    radius: 20,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (_availableDestinationsError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Could not load destinations: $_availableDestinationsError',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: _loadAvailableDestinations,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_availableDestinations.isEmpty) {
      return const SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No destinations available yet.'),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDestinations.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final destination = index == 0
              ? null
              : _availableDestinations[index - 1];
          final label = destination?.name ?? 'All destinations';
          return ChoiceChip(
            label: Text(label),
            selected: _selectedDestinationSlug == destination?.slug,
            onSelected: (_) => _selectDestination(destination),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _selectedDestinationSlug == destination?.slug
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: AppColors.border),
          );
        },
      ),
    );
  }

  Future<void> _showAdvancedFilters() async {
    final result = await showModalBottomSheet<_AdvancedFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) =>
          _AdvancedFilterSheet(minimumRating: _minimumRating, sort: _sort),
    );
    if (result == null || !mounted) return;
    setState(() {
      _minimumRating = result.minimumRating;
      _sort = result.sort;
    });
  }
}

class _ExploreDestinationSkeleton extends StatelessWidget {
  const _ExploreDestinationSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPlaceholder(
      child: Container(
        key: const ValueKey('explore_destination_skeleton'),
        height: 156,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SkeletonPlaceholder.block(
              width: 120,
              height: double.infinity,
              radius: 12,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonPlaceholder.block(width: 82, height: 12),
                  const Spacer(),
                  SkeletonPlaceholder.block(width: 150, height: 18),
                  const SizedBox(height: 9),
                  SkeletonPlaceholder.block(width: 190, height: 12),
                  const SizedBox(height: 7),
                  SkeletonPlaceholder.block(width: 120, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedFilter {
  const _AdvancedFilter({required this.minimumRating, required this.sort});

  final double minimumRating;
  final _DestinationSort sort;
}

enum _DestinationSort { recommended, highestRated, name }

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({required this.minimumRating, required this.sort});

  final double minimumRating;
  final _DestinationSort sort;

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late double _minimumRating = widget.minimumRating;
  late _DestinationSort _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advanced filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close filters',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Minimum rating',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final rating in [0.0, 4.5, 4.8])
                  ChoiceChip(
                    label: Text(rating == 0 ? 'Any' : '$rating+'),
                    selected: _minimumRating == rating,
                    onSelected: (_) => setState(() => _minimumRating = rating),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<_DestinationSort>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const [
                DropdownMenuItem(
                  value: _DestinationSort.recommended,
                  child: Text('Recommended'),
                ),
                DropdownMenuItem(
                  value: _DestinationSort.highestRated,
                  child: Text('Highest rated'),
                ),
                DropdownMenuItem(
                  value: _DestinationSort.name,
                  child: Text('Name: A to Z'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sort = value);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _minimumRating = 0;
                        _sort = _DestinationSort.recommended;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _AdvancedFilter(
                        minimumRating: _minimumRating,
                        sort: _sort,
                      ),
                    ),
                    child: const Text('Show places'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreDestinationCard extends StatelessWidget {
  const _ExploreDestinationCard({
    required this.destination,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final HomeDestination destination;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

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
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => context.push(
                RouteNames.destinationDetails.replaceFirst(
                  ':destination',
                  Uri.encodeComponent(destination.key),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DestinationArtwork(destination: destination),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 10, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                destination.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFE2A747),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              destination.rating,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: onToggleFavorite,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                foregroundColor: isFavorite
                    ? AppColors.secondary
                    : AppColors.textPrimary,
              ),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
              ),
            ),
          ),
        ],
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
        errorBuilder: (context, error, stackTrace) => _illustration(),
      );
    }
    return _illustration();
  }

  Widget _illustration() {
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
          size: 54,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _ExploreMessage extends StatelessWidget {
  const _ExploreMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 46),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
