import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/mock/home_content.dart';
import '../../data/repositories/api_destination_repository.dart';
import '../../data/repositories/api_home_content_repository.dart';
import '../../data/repositories/api_place_repository.dart';
import '../../domain/models/destination.dart';
import '../../domain/models/home_event.dart';
import '../../domain/models/home_phrase.dart';
import '../../domain/repositories/destination_repository.dart';
import '../../domain/repositories/home_content_repository.dart';
import '../../domain/repositories/place_repository.dart';
import '../widgets/home_content_skeleton.dart';
import '../widgets/destination_image.dart';
import '../widgets/home_phrase_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.initialNavigationIndex = 0,
    this.placeRepository,
    this.destinationRepository,
    this.homeContentRepository,
    super.key,
  });

  final int initialNavigationIndex;
  final PlaceRepository? placeRepository;
  final DestinationRepository? destinationRepository;
  final HomeContentRepository? homeContentRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _eventPageController = PageController();
  Timer? _eventSlideTimer;
  late final PlaceRepository _placeRepository;
  late final DestinationRepository _destinationRepository;
  late final HomeContentRepository _homeContentRepository;
  late int _selectedNavigation;
  List<HomeDestination> _destinations = const [];
  List<Destination> _destinationCards = const [];
  List<HomeEvent> _events = const [];
  List<HomePhrase> _phrases = const [];
  String _searchQuery = '';
  Set<String> _savedDestinations = {};
  int _currentEventPage = 0;
  String? _loadError;
  String? _destinationLoadError;
  String? _eventLoadError;
  String? _phraseLoadError;
  bool _isLoadingPlaces = true;
  bool _isLoadingDestinations = true;
  bool _isLoadingEvents = true;
  bool _isLoadingPhrases = true;

  @override
  void initState() {
    super.initState();
    _selectedNavigation = widget.initialNavigationIndex;
    _placeRepository =
        widget.placeRepository ?? ApiPlaceRepository(ApiClient());
    _destinationRepository =
        widget.destinationRepository ?? ApiDestinationRepository(ApiClient());
    _homeContentRepository =
        widget.homeContentRepository ?? ApiHomeContentRepository(ApiClient());
    _loadPlaces();
    _loadDestinations();
    _loadEvents();
    _loadPhrases();
  }

  Future<void> _loadPlaces() async {
    if (mounted && !_isLoadingPlaces) {
      setState(() {
        _isLoadingPlaces = true;
        _loadError = null;
      });
    }
    try {
      final places = await _placeRepository.loadPlaces();
      final savedSlugs = await _placeRepository.loadSavedPlaceSlugs();
      if (!mounted) return;
      setState(() {
        _destinations = places;
        _savedDestinations = savedSlugs;
        _loadError = null;
        _isLoadingPlaces = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoadingPlaces = false;
      });
    }
  }

  Future<void> _loadDestinations() async {
    if (mounted && !_isLoadingDestinations) {
      setState(() {
        _isLoadingDestinations = true;
        _destinationLoadError = null;
      });
    }
    try {
      final destinations = await _destinationRepository.loadDestinations();
      if (!mounted) return;
      setState(() {
        _destinationCards = destinations;
        _destinationLoadError = null;
        _isLoadingDestinations = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _destinationLoadError = error.toString();
        _isLoadingDestinations = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    if (mounted && !_isLoadingEvents) {
      setState(() {
        _isLoadingEvents = true;
        _eventLoadError = null;
      });
    }
    try {
      final events = await _homeContentRepository.loadEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _currentEventPage = 0;
        _eventLoadError = null;
        _isLoadingEvents = false;
      });
      if (_eventPageController.hasClients) {
        _eventPageController.jumpToPage(0);
      }
      _startEventSlideshow();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _eventLoadError = error.toString();
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _loadPhrases() async {
    if (mounted && !_isLoadingPhrases) {
      setState(() {
        _isLoadingPhrases = true;
        _phraseLoadError = null;
      });
    }
    try {
      final phrases = await _homeContentRepository.loadPhrases();
      if (!mounted) return;
      setState(() {
        _phrases = phrases;
        _phraseLoadError = null;
        _isLoadingPhrases = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _phraseLoadError = error.toString();
        _isLoadingPhrases = false;
      });
    }
  }

  List<HomeDestination> get _visibleDestinations {
    return _destinations.where((destination) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query) ||
          destination.category.toLowerCase().contains(query);
      final matchesSaved =
          _selectedNavigation != 3 ||
          _savedDestinations.contains(destination.key);
      return matchesSearch && matchesSaved;
    }).toList();
  }

  void _startEventSlideshow() {
    _eventSlideTimer?.cancel();
    if (_events.length < 2) return;

    _eventSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          _selectedNavigation != 0 ||
          !_eventPageController.hasClients) {
        return;
      }
      final nextPage = (_currentEventPage + 1) % _events.length;
      _eventPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _eventSlideTimer?.cancel();
    _eventPageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _selectedNavigation == 4
            ? ProfileScreen(
                onSelectTab: (index) {
                  setState(() => _selectedNavigation = index);
                },
              )
            : _selectedNavigation == 3
            ? _buildSavedPage()
            : _selectedNavigation == 2
            ? ChangeNotifierProvider(
                create: (_) => MapProvider(destinations: _destinations),
                child: MapScreen(
                  savedDestinations: _savedDestinations,
                  onToggleFavorite: _toggleSaved,
                ),
              )
            : _selectedNavigation == 1
            ? ExploreScreen(
                savedDestinations: _savedDestinations,
                onToggleFavorite: _toggleSaved,
                loadDestinations: _placeRepository.loadPlaces,
                destinationRepository: _destinationRepository,
              )
            : _buildDiscoverPage(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavigation,
        onDestinationSelected: (index) {
          setState(() => _selectedNavigation = index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: strings.homeTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: strings.exploreTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: strings.mapTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: strings.savedTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: strings.profileTab,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverPage() {
    final destinations = _visibleDestinations;

    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Find your next adventure',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 26, height: 1.15),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearchField()),
        ),
        if (_searchQuery.isEmpty &&
            (_isLoadingEvents || _events.isNotEmpty || _eventLoadError != null))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildAdminHighlight()),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
          sliver: SliverToBoxAdapter(child: _buildDestinationHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: _buildDestinationCards(),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeading(
              'Featured Places',
              trailing: 'See all',
              onTrailingTap: () => setState(() => _selectedNavigation = 1),
            ),
          ),
        ),
        if (_isLoadingPlaces)
          const SliverToBoxAdapter(
            child: HomeContentSkeleton(type: HomeSkeletonType.destinations),
          )
        else if (_loadError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadPlaces,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (destinations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No places found. Try another search or category.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 272,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) => _FeaturedDestinationCard(
                    destination: destinations[index],
                    isSaved: _savedDestinations.contains(
                      destinations[index].key,
                    ),
                    onSave: () => _toggleSaved(destinations[index]),
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          sliver: SliverToBoxAdapter(child: _buildEverydayPhrase()),
        ),
      ],
    );
  }

  Widget _buildEverydayPhrase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Essential Everyday Phrases',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.phrases),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'See all',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingPhrases)
          const HomeContentSkeleton(type: HomeSkeletonType.phraseCarousel)
        else if (_phraseLoadError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_phraseLoadError!, textAlign: TextAlign.center),
              TextButton(onPressed: _loadPhrases, child: const Text('Retry')),
            ],
          )
        else if (_phrases.isEmpty)
          const Text('No phrases are available yet.')
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _phrases.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 280,
                child: HomePhraseCard(phrase: _phrases[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminHighlight() {
    if (_isLoadingEvents) {
      return const HomeContentSkeleton(type: HomeSkeletonType.event);
    }
    if (_events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_eventLoadError!, textAlign: TextAlign.center),
          TextButton(onPressed: _loadEvents, child: const Text('Retry')),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            key: const ValueKey('home_event_slideshow'),
            controller: _eventPageController,
            itemCount: _events.length,
            onPageChanged: (index) {
              setState(() => _currentEventPage = index);
            },
            itemBuilder: (context, index) => _EventBannerCard(
              event: _events[index],
              onExplore: () =>
                  context.push(RouteNames.eventDetails, extra: _events[index]),
            ),
          ),
        ),
        if (_events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < _events.length; index++)
                GestureDetector(
                  onTap: () => _eventPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentEventPage ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: index == _currentEventPage
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.explore, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KHMER COMPASS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Your guide to Cambodia',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search places...',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: IconButton(
          tooltip: 'Clear search and filters',
          onPressed: () => setState(() {
            _searchController.clear();
            _searchQuery = '';
          }),
          icon: const Icon(Icons.tune_rounded),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDestinationHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore by destination',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Discover places across Cambodia',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _selectedNavigation = 1),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'See all',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCards() {
    if (_isLoadingDestinations) {
      return const SliverToBoxAdapter(
        child: HomeContentSkeleton(type: HomeSkeletonType.destinationGrid),
      );
    }
    if (_destinationLoadError != null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 168,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load destinations.',
                  textAlign: TextAlign.center,
                ),
                Text(
                  _destinationLoadError!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _loadDestinations,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_destinationCards.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 168,
          child: Center(child: Text('No destinations available yet.')),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 248,
        child: GridView.builder(
          key: const ValueKey('home_destination_grid'),
          scrollDirection: Axis.horizontal,
          itemCount: _destinationCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 170,
          ),
          itemBuilder: (context, index) {
            final destination = _destinationCards[index];
            return _DestinationCard(
              destination: destination,
              onTap: () => context.push(
                RouteNames.destinationOverview.replaceFirst(
                  ':destination',
                  Uri.encodeComponent(destination.slug),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeading(
    String title, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTrailingTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(trailing),
          ),
      ],
    );
  }

  Widget _buildSavedPage() {
    final saved = _visibleDestinations;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saved places',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${saved.length} ${saved.length == 1 ? 'place' : 'places'}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your favorite destinations, ready for your next adventure.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoadingPlaces)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_loadError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load your saved places.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _loadPlaces,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (saved.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Icon(
                          Icons.bookmark_outline_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Your next adventure starts here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Save places you love and they will be waiting for you here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: saved.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _SavedDestinationTile(
                destination: saved[index],
                onRemove: () => _toggleSaved(saved[index]),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _toggleSaved(HomeDestination destination) async {
    final slug = destination.key;
    final saved = !_savedDestinations.contains(slug);
    try {
      await _placeRepository.setPlaceSaved(slug, saved: saved);
      if (!mounted) return;
      setState(() {
        if (saved) {
          _savedDestinations.add(slug);
        } else {
          _savedDestinations.remove(slug);
        }
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _EventBannerCard extends StatelessWidget {
  const _EventBannerCard({required this.event, required this.onExplore});

  final HomeEvent event;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28636A), Color(0xFF153B40)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (event.imageUrl != null)
            DestinationImage(
              source: event.imageUrl!,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.expand(),
            )
          else
            Positioned(
              right: -20,
              top: -36,
              child: Icon(
                Icons.temple_buddhist,
                size: 190,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x20000000),
                  Color(0xC9000000),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFFFFC56B),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'FEATURED EVENT',
                      style: TextStyle(
                        color: Color(0xFFFFD58C),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                if (event.location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (event.description.isNotEmpty) const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: onExplore,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC56B),
                        foregroundColor: AppColors.neutral,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDestinationCard extends StatelessWidget {
  const _FeaturedDestinationCard({
    required this.destination,
    required this.isSaved,
    required this.onSave,
  });

  final HomeDestination destination;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 264,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(
              RouteNames.destinationDetails.replaceFirst(
                ':destination',
                Uri.encodeComponent(destination.key),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _DestinationArtwork(destination: destination),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Colors.transparent,
                        Color(0xDD000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      destination.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: isSaved
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: onSave,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: isSaved
                          ? AppColors.secondary
                          : AppColors.textPrimary,
                    ),
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              destination.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Color(0xFFFFC56B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        destination.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          size: 82,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _SavedDestinationTile extends StatelessWidget {
  const _SavedDestinationTile({
    required this.destination,
    required this.onRemove,
  });

  final HomeDestination destination;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(destination.rating);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RouteNames.destinationDetails.replaceFirst(
            ':destination',
            Uri.encodeComponent(destination.key),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 96,
                  child: destination.imageAsset == null
                      ? _buildArtworkFallback()
                      : DestinationImage(
                          source: destination.imageAsset!,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildArtworkFallback(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (destination.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: destination.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          destination.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: destination.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 7),
                    Text(
                      destination.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            destination.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rating != null && rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFB547),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            destination.rating,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (destination.reviewCount > 0) ...[
                            const SizedBox(width: 5),
                            Text(
                              '(${destination.reviewCount})',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Remove from saved',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkFallback() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [destination.accent, AppColors.neutral],
      ),
    ),
    child: Center(
      child: Icon(destination.icon, size: 36, color: Colors.white70),
    ),
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination, required this.onTap});

  final Destination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 244,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (destination.imageUrl != null)
                DestinationImage(source: destination.imageUrl!)
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.neutral],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.explore_outlined,
                      color: Colors.white38,
                      size: 56,
                    ),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.34, 1],
                    colors: [
                      Color(0x08000000),
                      Color(0x12000000),
                      Color(0xD9000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (destination.region.isNotEmpty)
                      Text(
                        destination.region,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
