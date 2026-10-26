import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/repositories/api_place_repository.dart';
import '../../../home/domain/repositories/place_repository.dart';
import '../../../home/data/mock/home_content.dart';
import '../../../home/presentation/widgets/destination_image.dart';
import '../widgets/destination_detail_skeleton.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    required this.destinationName,
    this.placeRepository,
    super.key,
  });

  final String destinationName;
  final PlaceRepository? placeRepository;

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  final _scrollController = ScrollController();
  final _visitorInfoKey = GlobalKey();
  late final PageController _imagePageController;
  late Future<HomeDestination> _destination;
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _destination = _repository.loadPlace(widget.destinationName);
  }

  PlaceRepository get _repository =>
      widget.placeRepository ?? ApiPlaceRepository(ApiClient());

  @override
  void dispose() {
    _scrollController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDestination>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DestinationDetailSkeleton();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load this place.'),
                  TextButton(
                    onPressed: () => setState(
                      () => _destination = _repository.loadPlace(
                        widget.destinationName,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildDestination(context, snapshot.data!);
      },
    );
  }

  Widget _buildDestination(BuildContext context, HomeDestination destination) {
    final photos = destination.photos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(destination, photos),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  destination.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${destination.location}, Cambodia',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE2A747),
                      size: 20,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      destination.rating,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 23, top: 3),
                  child: Text(
                    '${_formatReviewCount(destination.reviewCount)} reviews',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: destination.tags
                      .map((tag) => _CategoryChip(label: tag))
                      .toList(),
                ),
                const SizedBox(height: 28),
                const _SectionEyebrow(label: '03 · DESCRIPTION'),
                const SizedBox(height: 8),
                Text(
                  'About This Place',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  destination.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _isDescriptionExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.history,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                destination.visitorExperience,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _isDescriptionExpanded = !_isDescriptionExpanded,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      _isDescriptionExpanded ? 'Read less' : 'Read more',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  key: _visitorInfoKey,
                  child: const _SectionEyebrow(
                    label: '04 · VISITOR INFORMATION',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Travel Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _TravelInformationGrid(destination: destination),
                const SizedBox(height: 28),
                const _SectionEyebrow(label: '05 · LOCATION AND GALLERY'),
                const SizedBox(height: 8),
                Text(
                  'Location and Photos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _MapPreview(destination: destination),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Photo Gallery',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: photos.isEmpty
                      ? _DestinationArtwork(destination: destination)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) => _GalleryThumbnail(
                            asset: photos[index],
                            onTap: () {
                              _imagePageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                              setState(() => _currentImageIndex = index);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DestinationActionBar(
        onPlanVisit: _scrollToVisitorInfo,
        onGetDirections: () => _openDirections(destination),
      ),
    );
  }

  Widget _buildImageCarousel(HomeDestination destination, List<String> photos) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photos.isEmpty)
          _DestinationArtwork(destination: destination)
        else
          PageView.builder(
            controller: _imagePageController,
            itemCount: photos.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) => DestinationImage(
              source: photos[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _DestinationArtwork(destination: destination),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x28000000), Colors.transparent],
              stops: [0, 0.55],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${_currentImageIndex + 1} / ${photos.isEmpty ? 1 : photos.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scrollToVisitorInfo() async {
    final sectionContext = _visitorInfoKey.currentContext;
    if (sectionContext != null) {
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  Future<void> _openDirections(HomeDestination destination) async {
    final mapUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': destination.mapQuery,
      'query_place_id': '',
    });
    final opened = await launchUrl(
      mapUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open a maps application.')),
      );
    }
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(1)}k';
    }
    return '$count';
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TravelInformationGrid extends StatelessWidget {
  const _TravelInformationGrid({required this.destination});

  final HomeDestination destination;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.schedule_outlined, 'Opening hours', destination.openingHours),
      (Icons.confirmation_num_outlined, 'Entrance fee', destination.ticketInfo),
      (Icons.wb_sunny_outlined, 'Best time', destination.bestTimeToVisit),
      (Icons.timelapse_rounded, 'Visit duration', destination.visitDuration),
    ];

    return Column(
      children: [
        for (var index = 0; index < items.length; index += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InformationCard(
                  icon: items[index].$1,
                  title: items[index].$2,
                  detail: items[index].$3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InformationCard(
                  icon: items[index + 1].$1,
                  title: items[index + 1].$2,
                  detail: items[index + 1].$3,
                ),
              ),
            ],
          ),
          if (index + 2 < items.length) const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        _InformationCard(
          icon: Icons.checkroom_outlined,
          title: 'Dress code and visitor guidelines',
          detail: destination.dressCode,
          isWide: true,
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.isWide = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(height: 9),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.destination});

  final HomeDestination destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _MapPatternPainter()),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.secondary,
                    size: 42,
                    shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Map preview',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.place_outlined,
              color: AppColors.primary,
              size: 19,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                destination.address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  const _MapPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE5EFEC),
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final narrowRoadPaint = Paint()
      ..color = const Color(0xFFC7D8D0)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roads = [
      Path()
        ..moveTo(-10, size.height * 0.72)
        ..cubicTo(
          size.width * 0.24,
          size.height * 0.48,
          size.width * 0.55,
          size.height * 0.83,
          size.width + 10,
          size.height * 0.48,
        ),
      Path()
        ..moveTo(size.width * 0.23, -10)
        ..cubicTo(
          size.width * 0.47,
          size.height * 0.28,
          size.width * 0.33,
          size.height * 0.69,
          size.width * 0.76,
          size.height + 10,
        ),
      Path()
        ..moveTo(-10, size.height * 0.22)
        ..cubicTo(
          size.width * 0.33,
          size.height * 0.31,
          size.width * 0.71,
          size.height * 0.12,
          size.width + 10,
          size.height * 0.27,
        ),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, narrowRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPatternPainter oldDelegate) => false;
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DestinationImage(
          source: asset,
          width: 150,
          height: 112,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 150,
            child: Icon(Icons.image_not_supported),
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
          size: 96,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _DestinationActionBar extends StatelessWidget {
  const _DestinationActionBar({
    required this.onPlanVisit,
    required this.onGetDirections,
  });

  final VoidCallback onPlanVisit;
  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your next adventure',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPlanVisit,
                    icon: const Icon(Icons.event_note_outlined, size: 18),
                    label: const Text('Plan your visit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onGetDirections,
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Get Directions'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(46),
                    ),
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
