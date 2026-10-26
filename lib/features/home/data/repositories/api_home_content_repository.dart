import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/home_event.dart';
import '../../domain/models/home_phrase.dart';
import '../../domain/repositories/home_content_repository.dart';

class ApiHomeContentRepository implements HomeContentRepository {
  ApiHomeContentRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<HomeEvent>> loadEvents() async {
    final response = await _client.get('/events');
    return _readData(response)
        .map(
          (json) =>
              HomeEvent.fromApiJson(json, languageCode: _client.languageCode),
        )
        .toList();
  }

  @override
  Future<List<HomePhrase>> loadPhrases({String? categorySlug}) async {
    final normalizedSlug = categorySlug?.trim().toLowerCase();
    final response = await _client.get(
      '/phrases',
      queryParameters: normalizedSlug == null || normalizedSlug.isEmpty
          ? null
          : normalizedSlug == 'emergency'
          ? {'emergency': 1}
          : {'category': normalizedSlug},
    );
    return _readData(response)
        .map(
          (json) =>
              HomePhrase.fromApiJson(json, languageCode: _client.languageCode),
        )
        .toList();
  }

  List<Map<String, Object?>> _readData(Map<String, Object?> response) {
    final data = response['data'];
    if (data is! List) {
      throw const ApiException('The content response is missing its data.');
    }
    return data.map((item) {
      if (item is! Map) {
        throw const ApiException('The content response contains invalid data.');
      }
      return Map<String, Object?>.from(item);
    }).toList();
  }
}
