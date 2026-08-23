import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

/// Authentication state provider managing JWT bearer tokens and user roles
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isOperator => _currentUser?.isOperator ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static String? currentToken;

  /// Sign up with email, password, name, and optional role
  Future<bool> register({
    required String email,
    required String password,
    String? name,
    String role = 'customer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'name': name?.trim() ?? 'EV User',
        }),
      );

      final json = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _token = json['token']?.toString();
        currentToken = _token;
        _currentUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);

        // Update role if selected as operator
        if (role == 'operator') {
          await updateRole('operator');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json['error']?.toString() ?? json['message']?.toString() ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log in with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final json = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _token = json['token']?.toString();
        currentToken = _token;
        _currentUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = json['error']?.toString() ?? json['message']?.toString() ?? 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user role during onboarding
  Future<bool> updateRole(String newRole) async {
    if (_token == null) return false;
    try {
      final res = await http.patch(
        Uri.parse(ApiConfig.updateRole),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'role': newRole}),
      );

      final json = jsonDecode(res.body);
      if (res.statusCode == 200 && json['user'] != null) {
        _currentUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Switch role locally for previewing
  void togglePreviewRole() {
    if (_currentUser == null) return;
    final newRole = _currentUser!.role == 'operator' ? 'customer' : 'operator';
    _currentUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: _currentUser!.name,
      phone: _currentUser!.phone,
      role: newRole,
      emailVerified: _currentUser!.emailVerified,
    );
    notifyListeners();
  }

  /// Sign out
  void logout() {
    _currentUser = null;
    _token = null;
    currentToken = null;
    notifyListeners();
  }
}
