import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const AuthException('Please provide a valid email address.');
    }

    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters long.');
    }

    return AppUser(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Khmer Explorer',
      email: email.trim(),
    );
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (name.trim().isEmpty) {
      throw const AuthException('Please enter your full name.');
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const AuthException('Please provide a valid email address.');
    }

    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters long.');
    }

    return AppUser(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (email.trim().isEmpty) {
      throw const AuthException('Please enter your email address.');
    }

    final isValidEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email.trim());

    if (!isValidEmail) {
      throw const AuthException('Enter a valid email to reset your password.');
    }
  }
}
