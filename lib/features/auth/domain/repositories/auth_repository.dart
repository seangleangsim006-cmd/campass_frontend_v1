import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> resetPassword({required String email});

  Future<void> signOut() async {}
}
