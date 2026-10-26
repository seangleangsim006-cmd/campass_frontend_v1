import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'Khmer Compass',
      },
    );
    return _readAuthenticatedUser(response);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'country_code': 'KH',
        'preferred_language': _client.languageCode,
      },
    );
    return _readAuthenticatedUser(response);
  }

  @override
  Future<void> resetPassword({required String email}) {
    throw const AuthException('Password reset is not available yet.');
  }

  @override
  Future<void> signOut() async {
    if (!_client.isAuthenticated) return;
    await _client.post('/auth/logout');
    await _client.setToken(null);
  }

  Future<AppUser> _readAuthenticatedUser(Map<String, Object?> response) async {
    final token = response['token'];
    final user = response['user'];
    if (token is! String || token.isEmpty || user is! Map) {
      throw const ApiException('Authentication response is incomplete.');
    }
    final userJson = Map<String, Object?>.from(user);
    await _client.setToken(token);
    return AppUser(
      id: userJson['id']?.toString() ?? '',
      name: userJson['name'] is String ? userJson['name'] as String : '',
      email: userJson['email'] is String ? userJson['email'] as String : '',
      avatarUrl: userJson['avatar_url'] is String
          ? userJson['avatar_url'] as String
          : null,
    );
  }
}
