// lib/services/auth/ms_auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:ms_suite/main.dart';

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

  void _initializeOAuth() async {
    final config = Config(
      tenant: '628e5b42-58ff-4fe8-aed5-c7652f22a45d',
      clientId: '625a3fb5-9bea-439f-a16c-ff17c4efb9bb',
      scope: 'User.Read Calendars.ReadWrite',
      // Web-specific redirect URI
      redirectUri: kIsWeb
          ? 'http://localhost:3000/callback' // Development
          // ? 'https://your-domain.com/auth.html'  // Production
          : 'msauth://YOUR_PACKAGE_NAME/callback',
      // Web-specific settings
      webUseRedirect: true, // Use redirect instead of popup for web
      // Optional: Configure prompt behavior
      prompt: 'select_account', navigatorKey: navigatorKey,
    );
    _oauth = AadOAuth(config);

    // try {
    //   await Future.delayed(
    //       Duration(seconds: 3)); // Simulate initialization delay
    //   await _oauth.login();
    // } catch (e) {
    //   print('Initialization error: $e');
    // }
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
      print("senay");
      print(token);

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
        // logout();
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

  Future<void> handleMsAuthChange() async {
    var uri = Uri.parse(html.window.location.href);
    print(uri);
    print(uri.queryParameters['code']);
    // if (uri.queryParameters['code'] != null) {
    //   await _oauth.getToken(uri.queryParameters['code']);
    //   await _storeAuthData(await _oauth.getAccessToken());
    //   await _fetchUserProfile(await _oauth.getAccessToken());
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['error'] != null) {
    //   print('Error: ${uri.queryParameters['error']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['error_description'] != null) {
    //   print('Error Description: ${uri.queryParameters['error_description']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['error_uri'] != null) {
    //   print('Error URI: ${uri.queryParameters['error_uri']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['state'] != null) {
    //   print('State: ${uri.queryParameters['state']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['session_state'] != null) {
    //   print('Session State: ${uri.queryParameters['session_state']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['prompt'] != null) {
    //   print('Prompt: ${uri.queryParameters['prompt']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['client-request-id'] != null) {
    //   print('Client Request ID: ${uri.queryParameters['client-request-id']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['client_id'] != null) {
    //   print('Client ID: ${uri.queryParameters['client_id']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['redirect_uri'] != null) {
    //   print('Redirect URI: ${uri.queryParameters['redirect_uri']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['response_mode'] != null) {
    //   print('Response Mode: ${uri.queryParameters['response_mode']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['response_type'] != null) {
    //   print('Response Type: ${uri.queryParameters['response_type']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }

    // if (uri.queryParameters['scope'] != null) {
    //   print('Scope: ${uri.queryParameters['scope']}');
    //   html.window.history.pushState({}, '', uri.path);
    // }
  }
}
