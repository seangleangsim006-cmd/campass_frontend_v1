import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'demo-traveler',
    fullName: 'Sophea Chan',
    email: 'sophea.chan@example.com',
    phoneNumber: '+855 12 345 678',
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    return _profile;
  }
}
