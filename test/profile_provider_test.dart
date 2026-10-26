import 'package:flutter_test/flutter_test.dart';
import 'package:user_frontend/features/profile/domain/models/user_profile.dart';
import 'package:user_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:user_frontend/features/profile/presentation/providers/profile_provider.dart';

void main() {
  test('loads and updates profile data through the repository', () async {
    final repository = _FakeProfileRepository();
    final provider = ProfileProvider(repository: repository);
    addTearDown(provider.dispose);

    await provider.load();
    expect(provider.status, ProfileStatus.success);
    expect(provider.profile?.fullName, 'Sophea Chan');

    final updated = provider.profile!.copyWith(fullName: 'Sophea Dara');
    expect(await provider.updateProfile(updated), isTrue);
    expect(provider.profile?.fullName, 'Sophea Dara');
    expect(repository.updatedProfile, updated);
  });

  test('exposes repository errors instead of reporting success', () async {
    final provider = ProfileProvider(
      repository: _FakeProfileRepository(shouldFail: true),
    );
    addTearDown(provider.dispose);

    await provider.load();
    expect(provider.status, ProfileStatus.failure);
    expect(provider.profile, isNull);
    expect(provider.errorMessage, contains('Profile service unavailable'));
  });
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.shouldFail = false});

  final bool shouldFail;
  UserProfile? updatedProfile;

  @override
  Future<UserProfile> loadProfile() async {
    if (shouldFail) throw Exception('Profile service unavailable');
    return const UserProfile(
      id: 'demo-traveler',
      fullName: 'Sophea Chan',
      email: 'sophea.chan@example.com',
    );
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (shouldFail) throw Exception('Profile service unavailable');
    updatedProfile = profile;
    return profile;
  }
}
