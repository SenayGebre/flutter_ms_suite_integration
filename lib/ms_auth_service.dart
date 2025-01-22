// lib/services/auth/ms_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';

// Custom exceptions for better error handling
class MSAuthException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  MSAuthException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'MSAuthException: $message ${code != null ? '(Code: $code)' : ''}';
}

// Microsoft user profile model
class MSUserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  MSUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  factory MSUserProfile.fromJson(Map<String, dynamic> json) {
    return MSUserProfile(
      id: json['id'],
      displayName: json['displayName'],
      email: json['mail'] ?? json['userPrincipalName'],
      photoUrl: json['photoUrl'],
    );
  }
}

class MSAuthService {
  static final MSAuthService _instance = MSAuthService._internal();
  late final AadOAuth _oauth;
  final _storage = FlutterSecureStorage();

  MSUserProfile? _userProfile;
  DateTime? _tokenExpiryTime;

  // Constants
  static const String _storageKeyToken = 'ms_access_token';
  static const String _storageKeyExpiry = 'ms_token_expiry';
  static const String _storageKeyRefreshToken = 'ms_refresh_token';
  static const String _storageKeyUserId = 'ms_user_id';

  // Getters
  MSUserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _userProfile != null;

  factory MSAuthService() {
    return _instance;
  }

  MSAuthService._internal() {
    _initializeOAuth();
  }

  void _initializeOAuth() {
    final config = Config(
      tenant: 'YOUR_TENANT_ID',
      clientId: 'YOUR_CLIENT_ID',
      scope: 'User.Read Calendars.ReadWrite',
      // Web-specific redirect URI
      redirectUri: kIsWeb
          ? 'http://localhost:3000/auth.html' // Development
          // ? 'https://your-domain.com/auth.html'  // Production
          : 'msauth://YOUR_PACKAGE_NAME/callback',
      // Web-specific settings
      webUseRedirect: true, // Use redirect instead of popup for web
      // Optional: Configure prompt behavior
      prompt: 'select_account', navigatorKey: GlobalKey<NavigatorState>(),
    );
    _oauth = AadOAuth(config);
  }

  // Initialize the service and restore session if available
  Future<void> initialize() async {
    try {
      final storedToken = await _storage.read(key: _storageKeyToken);
      final storedExpiry = await _storage.read(key: _storageKeyExpiry);

      if (storedToken != null && storedExpiry != null) {
        final expiry = DateTime.parse(storedExpiry);
        if (expiry.isAfter(DateTime.now())) {
          // Token is still valid, fetch user profile
          await _fetchUserProfile(storedToken);
        } else {
          // Token expired, try to refresh
          await _refreshToken();
        }
      }
    } catch (e) {
      print('Error initializing MS Auth Service: $e');
      await logout(); // Clear potentially corrupted data
    }
  }

  // Link Microsoft account
  Future<bool> linkMicrosoftAccount() async {
    try {
      // Start OAuth flow
      await _oauth.login();
      final token = await _oauth.getAccessToken();

      if (token == null) {
        throw MSAuthException('Failed to obtain access token');
      }

      // Fetch and store user profile
      await _fetchUserProfile(token);

      // Store authentication data
      await _storeAuthData(token);

      return true;
    } catch (e) {
      print('Error linking Microsoft account: $e');
      await logout(); // Clean up on failure
      rethrow;
    }
  }

  // Get access token with automatic refresh if needed
  Future<String?> getAccessToken() async {
    try {
      if (_tokenExpiryTime?.isBefore(DateTime.now()) ?? true) {
        await _refreshToken();
      }
      return await _storage.read(key: _storageKeyToken);
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  // Refresh token
  Future<void> _refreshToken() async {
    try {
      await _oauth.login();
      final newToken = await _oauth.getAccessToken();

      if (newToken == null) {
        throw MSAuthException('Failed to refresh token');
      }

      await _storeAuthData(newToken);
    } catch (e) {
      print('Error refreshing token: $e');
      await logout();
      rethrow;
    }
  }

  // Store authentication data securely
  Future<void> _storeAuthData(String token) async {
    final expiry = DateTime.now()
        .add(Duration(hours: 1)); // Token typically expires in 1 hour

    await Future.wait([
      _storage.write(key: _storageKeyToken, value: token),
      _storage.write(key: _storageKeyExpiry, value: expiry.toIso8601String()),
    ]);

    _tokenExpiryTime = expiry;
  }

  // Fetch user profile from Microsoft Graph API
  Future<void> _fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userProfile = MSUserProfile.fromJson(data);
        await _storage.write(key: _storageKeyUserId, value: _userProfile?.id);
      } else {
        throw MSAuthException(
          'Failed to fetch user profile',
          code: response.statusCode.toString(),
          details: response.body,
        );
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  // Check if token is valid
  Future<bool> isTokenValid() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Logout and clear all stored data
  Future<void> logout() async {
    try {
      await _oauth.logout();
      await Future.wait([
        _storage.delete(key: _storageKeyToken),
        _storage.delete(key: _storageKeyExpiry),
        _storage.delete(key: _storageKeyRefreshToken),
        _storage.delete(key: _storageKeyUserId),
      ]);

      _userProfile = null;
      _tokenExpiryTime = null;
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }
}
