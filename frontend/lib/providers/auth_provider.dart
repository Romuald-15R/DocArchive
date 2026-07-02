import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // ✅ Getter public pour accéder à l'API (ex: upload photo)
  ApiService get api => _api;

  AuthProvider() {
    _checkToken();
  }

  Future<void> _checkToken() async {
    String? token = await _storage.read(key: 'token');
    if (token != null) {
      await fetchCurrentUser();
    }
  }

  // Connexion : envoie {email, password} (JSON)
  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('auth/login', {
        'email': email,
        'password': password,
      });
      await _storage.write(key: 'token', value: response['access_token']);
      await fetchCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final data = await _api.get('users/me');
      _currentUser = User.fromJson(data);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      logout();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Inscription : envoie nom, email, password, role
  Future<bool> register(String nom, String email, String password, String role) async {
    try {
      await _api.post('auth/register', {
        'nom': nom,
        'email': email,
        'password': password,
        'role': role,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _api.put('users/me', updates);
      _currentUser = User.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}