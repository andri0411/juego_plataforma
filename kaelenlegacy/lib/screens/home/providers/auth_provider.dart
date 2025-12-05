import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _currentUser;
  bool _isLoading = true;

  bool get isLoggedIn => _currentUser != null;
  String? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _currentUser = await _storage.read(key: 'current_user');
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String email, String password, String username) async {
    // Check if user already exists
    final existing = await _storage.read(key: 'user_$email');
    if (existing != null) {
      return false; // User already exists
    }
    // Save password and username
    await _storage.write(key: 'user_$email', value: password);
    await _storage.write(key: 'username_$email', value: username);
    return true;
  }

  Future<bool> login(String email, String password) async {
    final storedPassword = await _storage.read(key: 'user_$email');
    if (storedPassword == password) {
      _currentUser = email;
      await _storage.write(key: 'current_user', value: email);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.delete(key: 'current_user');
    notifyListeners();
  }
}
