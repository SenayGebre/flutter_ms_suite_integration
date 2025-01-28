// lib/screens/auth/login_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ms_suite/ms_auth_service.dart';
import 'package:universal_html/html.dart' as html;

// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final bool isMicrosoftLinked;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.isMicrosoftLinked = false,
  });
}

// lib/services/auth/custom_auth_service.dart
class CustomAuthService {
  static final CustomAuthService _instance = CustomAuthService._internal();
  User? _currentUser;

  factory CustomAuthService() {
    return _instance;
  }

  CustomAuthService._internal();

  User? get currentUser => _currentUser;

  // Simulate login with fake credentials
  Future<bool> login(String email, String password) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Mock credentials for testing
    if (email == 'test@bank.com' && password == 'password123') {
      _currentUser = User(
        id: '12345',
        email: email,
        name: 'Test User',
      );
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _msAuthService = MSAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    var uri = Uri.parse(html.window.location.href);
    print(uri);
  }

  Future<void> _handleLogin() async {
    Navigator.of(context).pushReplacementNamed('/ms-link');
    return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await CustomAuthService().login(
        _emailController.text,
        _passwordController.text,
      );

      if (kDebugMode || success) {
        Navigator.of(context).pushReplacementNamed('/ms-link');
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Login'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Test Credentials:\nEmail: test@bank.com\nPassword: password123',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
