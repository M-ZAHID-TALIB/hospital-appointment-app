import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _userId;
  String? _userName;
  String? _userRole;
  bool _isLoading = false;

  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userId != null;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userName = prefs.getString('user_name');
    _userRole = prefs.getString('user_role');
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password, role);
      if (result['status'] == 'success') {
        final user = result['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user['id']);
        await prefs.setString('user_name', user['name']);
        await prefs.setString('user_role', user['role']);

        _userId = user['id'];
        _userName = user['name'];
        _userRole = user['role'];
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String role,
    String? contact,
    String? age,
    String? address,
    String? city,
    String? specialization,
    String? username,
    int? fee,
    String? qualifications,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _apiService.register(
        name: name,
        email: email,
        password: password,
        gender: gender,
        role: role,
        contact: contact,
        age: age,
        address: address,
        city: city,
        specialization: specialization,
        username: username,
        fee: fee,
        qualifications: qualifications,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userId = null;
    _userName = null;
    _userRole = null;
    notifyListeners();
  }
}
