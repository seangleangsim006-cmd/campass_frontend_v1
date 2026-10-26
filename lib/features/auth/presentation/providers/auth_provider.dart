import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, success, failure }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? MockAuthRepository();

  final AuthRepository _repository;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  AppUser? currentUser;
  AuthStatus status = AuthStatus.idle;
  String? generalError;

  bool get isLoading => status == AuthStatus.loading;

  void clearError() {
    generalError = null;
    notifyListeners();
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    generalError = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  bool validateLoginForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      generalError = 'Email and password are required.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }

    generalError = null;
    status = AuthStatus.idle;
    notifyListeners();
    return true;
  }

  bool validateRegisterForm() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      generalError = 'Please complete all fields.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      generalError = 'Password must be at least 6 characters long.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      generalError = 'Passwords do not match.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }

    generalError = null;
    status = AuthStatus.idle;
    notifyListeners();
    return true;
  }

  Future<bool> login() async {
    if (!validateLoginForm()) {
      return false;
    }

    status = AuthStatus.loading;
    generalError = null;
    notifyListeners();

    try {
      currentUser = await _repository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      generalError = error.message;
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    } catch (_) {
      generalError = 'Unable to sign in right now. Please try again.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register() async {
    if (!validateRegisterForm()) {
      return false;
    }

    status = AuthStatus.loading;
    generalError = null;
    notifyListeners();

    try {
      currentUser = await _repository.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      generalError = error.message;
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    } catch (_) {
      generalError = 'Unable to create your account right now.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      generalError = 'Enter your email address to reset your password.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }

    status = AuthStatus.loading;
    generalError = null;
    notifyListeners();

    try {
      await _repository.resetPassword(email: email);
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      generalError = error.message;
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    } catch (_) {
      generalError = 'Unable to reset password at the moment.';
      status = AuthStatus.failure;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
