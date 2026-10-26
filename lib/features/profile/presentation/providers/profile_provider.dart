import 'package:flutter/foundation.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, success, failure }

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this._repository});

  final ProfileRepository _repository;

  UserProfile? _profile;
  ProfileStatus _status = ProfileStatus.idle;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  ProfileStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;

  Future<void> load() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.loadProfile();
      _status = ProfileStatus.success;
    } on Exception catch (error) {
      _errorMessage = 'Could not load your profile: $error';
      _status = ProfileStatus.failure;
    }
    notifyListeners();
  }

  Future<bool> updateProfile(UserProfile profile) async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.updateProfile(profile);
      _status = ProfileStatus.success;
      notifyListeners();
      return true;
    } on Exception catch (error) {
      _errorMessage = 'Could not save your profile: $error';
      _status = ProfileStatus.failure;
      notifyListeners();
      return false;
    }
  }
}
