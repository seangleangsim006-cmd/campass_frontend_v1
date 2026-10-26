import '../../../../core/network/api_image_url.dart';

class HomePhrase {
  const HomePhrase({
    required this.meaning,
    required this.khmerText,
    required this.romanization,
    required this.phonetic,
    this.categorySlug,
    this.imageUrl,
  });

  final String meaning;
  final String khmerText;
  final String romanization;
  final String phonetic;
  final String? categorySlug;
  final String? imageUrl;

  factory HomePhrase.fromApiJson(
    Map<String, Object?> json, {
    String languageCode = 'en',
  }) {
    return HomePhrase(
      meaning: _readText(json['meaning'] ?? json['english_text'], languageCode),
      khmerText: _readText(json['khmer_text'], languageCode),
      romanization: _readText(
        json['romanization'] ?? json['pronunciation'],
        languageCode,
      ),
      phonetic: _readText(json['phonetic'], languageCode),
      categorySlug: _readCategorySlug(json['category']),
      imageUrl: _readImageUrl(json),
    );
  }
}

String? _readCategorySlug(Object? value) {
  if (value is Map && value['slug'] is String) {
    return (value['slug'] as String).toLowerCase();
  }
  return null;
}

String? _readImageUrl(Map<String, Object?> json) {
  final imageValue =
      json['image_url'] ??
      json['imageUrl'] ??
      json['image'] ??
      json['photo_url'] ??
      json['cover_image_url'] ??
      json['thumbnail_url'] ??
      json['icon_url'];

  if (imageValue is Map) {
    final embeddedUrl =
        imageValue['url'] ??
        imageValue['path'] ??
        imageValue['src'] ??
        imageValue['image'] ??
        imageValue['image_url'];
    return _normalizeImageUrl(embeddedUrl);
  }

  return _normalizeImageUrl(imageValue);
}

String? _normalizeImageUrl(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return resolveApiImageUrl(normalized);
}

String _readText(Object? value, String languageCode) {
  if (value is String) return value;
  if (value is Map) {
    final text =
        value[languageCode] ??
        value['en'] ??
        value['name'] ??
        value['title'] ??
        value.values.firstOrNull;
    return text is String ? text : '';
  }
  return '';
}
