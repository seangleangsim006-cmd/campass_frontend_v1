import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/api_home_content_repository.dart';
import '../../domain/models/home_phrase.dart';
import '../../domain/repositories/home_content_repository.dart';
import '../widgets/home_phrase_card.dart';
import '../widgets/home_content_skeleton.dart';
import '../../../../core/network/api_client.dart';

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({this.repository, super.key});

  final HomeContentRepository? repository;

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen> {
  static const _categories = [
    ('greetings', 'Greetings'),
    ('food', 'Food'),
    ('shopping', 'Shopping'),
    ('hotel', 'Hotel'),
    ('emergency', 'Emergency'),
  ];

  late final HomeContentRepository _repository;
  late Future<List<HomePhrase>> _phrases;
  String? _selectedCategorySlug;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiHomeContentRepository(ApiClient());
    _phrases = _repository.loadPhrases();
  }

  void _retry() {
    setState(() {
      _phrases = _loadSelectedPhrases();
    });
  }

  Future<List<HomePhrase>> _loadSelectedPhrases() {
    return _repository.loadPhrases(categorySlug: _selectedCategorySlug);
  }

  void _selectCategory(String? slug) {
    if (_selectedCategorySlug == slug) return;
    setState(() {
      _selectedCategorySlug = slug;
      _phrases = _loadSelectedPhrases();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Everyday Phrases')),
    body: Column(
      children: [
        _buildCategoryFilters(),
        Expanded(
          child: FutureBuilder<List<HomePhrase>>(
            future: _phrases,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: HomeContentSkeleton(type: HomeSkeletonType.phraseList),
                );
              }
              if (snapshot.hasError) {
                return _MessageState(
                  message: 'Could not load phrases: ${snapshot.error}',
                  actionLabel: 'Retry',
                  onAction: _retry,
                );
              }
              final phrases = snapshot.data ?? const [];
              if (phrases.isEmpty) {
                return _MessageState(
                  message: _selectedCategorySlug == null
                      ? 'No phrases are available yet.'
                      : 'No phrases are available in this category yet.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: phrases.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    HomePhraseCard(phrase: phrases[index]),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildCategoryFilters() => SizedBox(
    height: 58,
    child: ListView(
      key: const ValueKey('phrase_category_filters'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      scrollDirection: Axis.horizontal,
      children: [
        _categoryChip(label: 'All', slug: null),
        for (final (slug, label) in _categories)
          _categoryChip(label: label, slug: slug),
      ],
    ),
  );

  Widget _categoryChip({required String label, required String? slug}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedCategorySlug == slug,
        onSelected: (_) => _selectCategory(slug),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
