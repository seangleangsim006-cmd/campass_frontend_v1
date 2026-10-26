import '../models/destination.dart';

abstract interface class DestinationRepository {
  Future<List<Destination>> loadDestinations();

  Future<DestinationDetails> loadDestination(String slug);
}
