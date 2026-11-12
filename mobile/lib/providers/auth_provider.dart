import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentLanguage = 'English';

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentLanguage => _currentLanguage;

  String tr(String key) => LocalizationService.tr(key, _currentLanguage);

  void setPreferredLanguage(String lang) {
    _currentLanguage = lang;
    LocalizationService.currentLanguage = lang;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferredLanguage: lang);
      ApiService.updateProfile(
        username: _currentUser!.username,
        newRegion: _currentUser!.defaultRegion,
        newLanguage: lang,
      );
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.login(username, password);
    _isLoading = false;

    if (result['success']) {
      _currentUser = result['user'];
      if (_currentUser?.preferredLanguage != null && _currentUser!.preferredLanguage.isNotEmpty) {
        _currentLanguage = _currentUser!.preferredLanguage;
        LocalizationService.currentLanguage = _currentLanguage;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    String defaultRegion = 'General/Standard',
    String preferredLanguage = 'English',
    String accountType = 'User',
    String securityQuestion = '',
    String securityAnswer = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.register(
      username: username,
      password: password,
      defaultRegion: defaultRegion,
      preferredLanguage: preferredLanguage,
      accountType: accountType,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String newRegion, String newLanguage) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.updateProfile(
      username: _currentUser!.username,
      newRegion: newRegion,
      newLanguage: newLanguage,
    );

    _isLoading = false;
    if (res['success'] == true) {
      _currentUser = _currentUser!.copyWith(
        defaultRegion: newRegion,
        preferredLanguage: newLanguage,
      );
      _currentLanguage = newLanguage;
      LocalizationService.currentLanguage = newLanguage;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return {'success': false, 'error': 'Not logged in'};
    return await ApiService.changePassword(
      username: _currentUser!.username,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
