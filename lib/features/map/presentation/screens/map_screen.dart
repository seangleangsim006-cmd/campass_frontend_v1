import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/map_provider.dart';
import '../../../home/data/mock/home_content.dart';
import '../../../home/presentation/widgets/destination_image.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.savedDestinations,
    required this.onToggleFavorite,
    super.key,
  });

  final Set<String> savedDestinations;
  final ValueChanged<HomeDestination> onToggleFavorite;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = context.watch<MapProvider>();
    final destinations = mapState.visibleDestinations;
    final selectedDestination = mapState.selectedDestination;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (mapState.showList)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 178, 16, 20),
                itemCount: destinations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _DestinationListTile(
                  destination: destinations[index],
                  onTap: () => _openDetails(destinations[index]),
                ),
              ),
            ),
          )
        else
          Positioned.fill(
            child: FlutterMap(
              mapController: mapState.mapController,
              options: const MapOptions(
                initialCenter: MapProvider.cambodiaCenter,
                initialZoom: 6.2,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'user_frontend',
                ),
                MarkerLayer(
                  markers: [
                    for (final destination in destinations)
                      Marker(
                        point: LatLng(
                          destination.latitude,
                          destination.longitude,
                        ),
                        width: 128,
                        height: 54,
                        alignment: Alignment.topCenter,
                        child: _DestinationMarker(
                          destination: destination,
                          isSelected: destination == selectedDestination,
                          onTap: () => context
                              .read<MapProvider>()
                              .selectDestination(destination),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
            ],
          ),
        ),
        if (!mapState.showList) ...[
          Positioned(
            top: 160,
            right: 16,
            child: _MapModeButton(
              icon: Icons.view_list_rounded,
              tooltip: 'Show destination list',
              onPressed: context.read<MapProvider>().showDestinationList,
            ),
          ),
          Positioned(
            right: 16,
            bottom: selectedDestination == null ? 24 : 220,
            child: Column(
              children: [
                _MapModeButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () => context.read<MapProvider>().zoomBy(1),
                ),
                const SizedBox(height: 8),
                _MapModeButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () => context.read<MapProvider>().zoomBy(-1),
                ),
                const SizedBox(height: 12),
                _MapModeButton(
                  icon: Icons.gps_fixed_rounded,
                  tooltip: 'Current location',
                  onPressed: mapState.isLocating ? null : _showCurrentLocation,
                ),
                const SizedBox(height: 8),
                _MapModeButton(
                  icon: Icons.travel_explore_rounded,
                  tooltip: 'Recenter map on Cambodia',
                  onPressed: context.read<MapProvider>().recenterOnCambodia,
                ),
              ],
            ),
          ),
        ] else
          Positioned(
            top: 160,
            right: 16,
            child: _MapModeButton(
              icon: Icons.map_outlined,
              tooltip: 'Show map',
              onPressed: context.read<MapProvider>().showMap,
            ),
          ),
        if (!mapState.showList && selectedDestination != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _DestinationPreviewCard(
              destination: selectedDestination,
              isSaved: widget.savedDestinations.contains(
                selectedDestination.key,
              ),
              onToggleFavorite: () =>
                  widget.onToggleFavorite(selectedDestination),
              onViewDetails: () => _openDetails(selectedDestination),
              onGetDirections: () => _openDirections(selectedDestination),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final mapState = context.watch<MapProvider>();
    return Material(
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: _searchController,
        onChanged: context.read<MapProvider>().setSearchQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search places in Cambodia',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mapState.searchQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    context.read<MapProvider>().setSearchQuery('');
                  },
                  icon: const Icon(Icons.close),
                ),
              IconButton(
                tooltip: 'Filter destinations',
                onPressed: _showCategoryFilter,
                icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
              ),
            ],
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final mapState = context.watch<MapProvider>();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MapProvider.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = MapProvider.categories[index];
          final isSelected = category == mapState.selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) =>
                context.read<MapProvider>().selectCategory(category),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Future<void> _showCategoryFilter() async {
    final mapState = context.read<MapProvider>();
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter destinations',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final category in MapProvider.categories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category),
                  trailing: mapState.selectedCategory == category
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                ),
            ],
          ),
        ),
      ),
    );

    if (category == null || !mounted) return;
    context.read<MapProvider>().selectCategory(category);
  }

  Future<void> _showCurrentLocation() async {
    final message = await context.read<MapProvider>().showCurrentLocation();
    if (message != null) _showLocationMessage(message);
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDetails(HomeDestination destination) {
    context.push(
      RouteNames.destinationDetails.replaceFirst(
        ':destination',
        Uri.encodeComponent(destination.key),
      ),
    );
  }

  Future<void> _openDirections(HomeDestination destination) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': destination.mapQuery,
    });
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final HomeDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              destination.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.secondary,
            size: 30,
            shadows: [Shadow(color: Colors.white, blurRadius: 4)],
          ),
        ],
      ),
    );
  }
}

class _MapModeButton extends StatelessWidget {
  const _MapModeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.textPrimary,
        icon: Icon(icon),
      ),
    );
  }
}

class _DestinationPreviewCard extends StatelessWidget {
  const _DestinationPreviewCard({
    required this.destination,
    required this.isSaved,
    required this.onToggleFavorite,
    required this.onViewDetails,
    required this.onGetDirections,
  });

  final HomeDestination destination;
  final bool isSaved;
  final VoidCallback onToggleFavorite;
  final VoidCallback onViewDetails;
  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: destination.photos.isEmpty
                        ? ColoredBox(
                            color: destination.accent.withValues(alpha: 0.15),
                            child: Icon(
                              destination.icon,
                              color: destination.accent,
                              size: 32,
                            ),
                          )
                        : DestinationImage(
                            source: destination.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: destination.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    destination.icon,
                                    color: destination.accent,
                                    size: 32,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.province,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFE6A53B),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isSaved ? 'Remove from saved' : 'Save destination',
                  onPressed: onToggleFavorite,
                  color: isSaved
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  icon: Icon(
                    isSaved ? Icons.favorite_rounded : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onGetDirections,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Get Directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onViewDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
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

class _DestinationListTile extends StatelessWidget {
  const _DestinationListTile({required this.destination, required this.onTap});

  final HomeDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: destination.accent.withValues(alpha: 0.15),
          child: Icon(destination.icon, color: destination.accent),
        ),
        title: Text(
          destination.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${destination.province} · ${destination.category}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
