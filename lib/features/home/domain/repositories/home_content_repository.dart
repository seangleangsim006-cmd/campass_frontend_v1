import '../models/home_event.dart';
import '../models/home_phrase.dart';

abstract interface class HomeContentRepository {
  Future<List<HomeEvent>> loadEvents();

  Future<List<HomePhrase>> loadPhrases({String? categorySlug});
}
