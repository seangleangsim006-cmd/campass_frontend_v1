import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_phrase.dart';
import 'destination_image.dart';

class HomePhraseCard extends StatelessWidget {
  const HomePhraseCard({required this.phrase, super.key});

  final HomePhrase phrase;

  @override
  Widget build(BuildContext context) {
    final hasImage = phrase.imageUrl != null && phrase.imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DestinationImage(
                source: phrase.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 160,
                  child: ColoredBox(
                    color: Color(0xFFE8E5DF),
                    child: Center(child: Icon(Icons.image_not_supported_outlined)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            phrase.meaning,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phrase.khmerText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (phrase.romanization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              phrase.romanization,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (phrase.phonetic.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Phonetic: ${phrase.phonetic}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
