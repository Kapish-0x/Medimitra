import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../network/api_client.dart';
import '../config/app_config.dart';
import 'package:dio/dio.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? specialization;
  final bool? isVerifiedDoctor;
  final Map<String, dynamic>? healthProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.specialization,
    this.isVerifiedDoctor,
    this.healthProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'patient',
        phone: json['phone'],
        specialization: json['specialization'],
        isVerifiedDoctor: json['isVerifiedDoctor'],
        healthProfile: json['healthProfile'],
      );

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';
  bool get isAdmin => role == 'admin';
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  final _storage = const FlutterSecureStorage();
  final _api = ApiClient.instance.dio;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  // ── Initialize: restore session ───────────────────────────────────────────
  Future<void> init() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        final res = await _api.get(ApiEndpoints.me);
        _user = UserModel.fromJson(res.data['user']);
      }
    } catch (_) {
      await _clearStorage();
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? specialization,
    String? licenseNumber,
  }) async {
    _setLoading(true);
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (specialization != null) 'specialization': specialization,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
      };

      final res = await _api.post(ApiEndpoints.register, data: body);
      await _saveTokens(res.data);
      _user = UserModel.fromJson(res.data['user']);
      _error = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      await _saveTokens(res.data);
      _user = UserModel.fromJson(res.data['user']);
      _error = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      await _api.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
    } catch (_) {}
    await _clearStorage();
    _user = null;
    notifyListeners();
  }

  // ── Update local user ─────────────────────────────────────────────────────
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  String _extractError(DioException e) {
    return e.response?.data?['message'] ?? 'An error occurred. Please try again.';
  }
}
