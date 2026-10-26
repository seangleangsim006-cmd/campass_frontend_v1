import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/repositories/api_destination_repository.dart';
import '../../../home/domain/models/destination.dart';
import '../../../home/domain/repositories/destination_repository.dart';
import '../../../home/presentation/widgets/destination_image.dart';
import '../widgets/destination_overview_skeleton.dart';

class DestinationOverviewScreen extends StatefulWidget {
  const DestinationOverviewScreen({
    required this.destinationSlug,
    this.destinationRepository,
    super.key,
  });

  final String destinationSlug;
  final DestinationRepository? destinationRepository;

  @override
  State<DestinationOverviewScreen> createState() =>
      _DestinationOverviewScreenState();
}

class _DestinationOverviewScreenState extends State<DestinationOverviewScreen> {
  late Future<DestinationDetails> _destination;
  late final DestinationRepository _repository;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _repository =
        widget.destinationRepository ?? ApiDestinationRepository(ApiClient());
    _destination = _repository.loadDestination(widget.destinationSlug);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DestinationDetails>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DestinationOverviewSkeleton();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load this destination.'),
                  TextButton(onPressed: _retryLoad, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        return _buildDestination(context, snapshot.data!);
      },
    );
  }

  void _retryLoad() {
    setState(() {
      _destination = _repository.loadDestination(widget.destinationSlug);
    });
  }

  Widget _buildDestination(
    BuildContext context,
    DestinationDetails destination,
  ) {
    final categories =
        destination.places
            .map((place) => place.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visiblePlaces = destination.places.where((place) {
      return _selectedCategory == 'All' ||
          place.category.trim() == _selectedCategory;
    }).toList();
    final featuredPlaces = destination.places
        .where((place) => place.isFeatured)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _hero(destination),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                destination.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.list(
              children: [
                if (destination.region.isNotEmpty)
                  Text(
                    destination.region,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (destination.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    destination.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
                if (featuredPlaces.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _sectionTitle(context, 'Featured attractions'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 226,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredPlaces.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) => _FeaturedPlaceCard(
                        place: featuredPlaces[index],
                        onTap: () => _openPlace(featuredPlaces[index]),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                _sectionTitle(context, 'Explore Places'),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', ...categories].map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = category),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (destination.places.isEmpty) ...[
                  const SizedBox(height: 20),
                  const _EmptyPlacesState(
                    message:
                        'There are no places listed for this destination yet.',
                  ),
                ] else if (visiblePlaces.isEmpty) ...[
                  const SizedBox(height: 20),
                  const _EmptyPlacesState(
                    message: 'No places match this category.',
                  ),
                ],
              ],
            ),
          ),
          if (_hasTravelInformation(destination))
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverList.list(
                children: [
                  _sectionTitle(context, 'Travel information'),
                  const SizedBox(height: 12),
                  if (_available(destination.bestTimeToVisit))
                    _InformationRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Best time to visit',
                      value: destination.bestTimeToVisit!,
                    ),
                  if (_available(destination.howToGetThere))
                    _InformationRow(
                      icon: Icons.directions_outlined,
                      title: 'How to get there',
                      value: destination.howToGetThere!,
                    ),
                  if (_available(destination.entranceFees))
                    _InformationRow(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Entrance or travel fees',
                      value: destination.entranceFees!,
                    ),
                  if (_available(destination.accessibility))
                    _InformationRow(
                      icon: Icons.accessible_forward_outlined,
                      title: 'Accessibility',
                      value: destination.accessibility!,
                    ),
                  if (_available(destination.travelTips))
                    _InformationRow(
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Travel tips',
                      value: destination.travelTips!,
                    ),
                ],
              ),
            ),
          if (visiblePlaces.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              sliver: SliverGrid.builder(
                itemCount: visiblePlaces.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 212,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final place = visiblePlaces[index];
                  return _PlaceCard(
                    key: ValueKey('destination_place_card_${place.slug}'),
                    place: place,
                    onTap: () => _openPlace(place),
                  );
                },
              ),
            ),
          if (destination.galleryUrls.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverList.list(
                children: [
                  _sectionTitle(context, 'Photos'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 126,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: destination.galleryUrls.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) => _GalleryThumbnail(
                        key: ValueKey('destination_gallery_$index'),
                        imageUrl: destination.galleryUrls[index],
                        onTap: () => _showPhotoViewer(
                          context,
                          destination.galleryUrls,
                          index,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero(DestinationDetails destination) {
    final gallery = destination.galleryUrls;
    final cover = destination.imageUrl;
    final heroImages = gallery.isNotEmpty
        ? gallery
        : cover == null
        ? const <String>[]
        : [cover];
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      title: Text(destination.name),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
       
        background: heroImages.isEmpty
            ? const _DestinationPlaceholder()
            : PageView.builder(
                itemCount: heroImages.length,
                itemBuilder: (context, index) => DestinationImage(
                  source: heroImages[index],
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  void _openPlace(DestinationPlace place) {
    if (place.slug.isEmpty) return;
    context.push(
      RouteNames.destinationDetails.replaceFirst(
        ':destination',
        Uri.encodeComponent(place.slug),
      ),
    );
  }

  Future<void> _showPhotoViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          _PhotoViewer(images: images, initialIndex: initialIndex),
    );
  }

  bool _hasTravelInformation(DestinationDetails destination) =>
      _available(destination.bestTimeToVisit) ||
      _available(destination.howToGetThere) ||
      _available(destination.entranceFees) ||
      _available(destination.accessibility) ||
      _available(destination.travelTips);

  bool _available(String? value) => value != null && value.trim().isNotEmpty;

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({required this.place, required this.onTap});

  final DestinationPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 196,
    child: _PlaceCard(
      key: ValueKey('featured_place_card_${place.slug}'),
      place: place,
      onTap: onTap,
      imageHeight: 132,
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.imageHeight = 116,
  });

  final DestinationPlace place;
  final VoidCallback onTap;
  final double imageHeight;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: place.imageUrl == null
                ? const _PlaceImageFallback()
                : DestinationImage(source: place.imageUrl!),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      if (place.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFE2A747),
                        ),
                        const SizedBox(width: 2),
                        Text(place.rating!.toStringAsFixed(1)),
                      ] else if (place.distanceKm != null) ...[
                        const Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text('${place.distanceKm!.toStringAsFixed(1)} km'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 164,
    child: Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DestinationImage(source: imageUrl),
      ),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => InteractiveViewer(
            child: Center(
              child: DestinationImage(
                source: widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Close photo viewer',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Text(
              '${_currentIndex + 1} / ${widget.images.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    ),
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      minLeadingWidth: 24,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(value),
      ),
    ),
  );
}

class _EmptyPlacesState extends StatelessWidget {
  const _EmptyPlacesState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}

class _PlaceImageFallback extends StatelessWidget {
  const _PlaceImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE8E5DF),
    child: Center(
      child: Icon(Icons.place_outlined, color: AppColors.primary, size: 34),
    ),
  );
}

class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.neutral],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.explore_outlined, size: 64, color: Colors.white70),
      ),
    );
  }
}
