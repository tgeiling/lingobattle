import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'provider.dart';

class AuthService {
  final String baseUrl =
      'http://34.89.180.139:3000'; // Replace with your server's IP
  final storage = const FlutterSecureStorage();

  // Login function
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['accessToken'];
        await storage.write(key: 'authToken', value: token);
        return true;
      } else {
        print('Login failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Register function
  Future<bool> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Registration failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Guest access function
  Future<void> setGuestToken() async {
    final token = await getGuestToken();
    if (token != null) {
      await storage.write(key: 'authToken', value: token);
    } else {
      print('Failed to obtain guest token.');
    }
  }

  // Fetch guest token from the server
  Future<String?> getGuestToken() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/guestnode'));
      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['accessToken'];
        return token;
      } else {
        print('Failed to get guest token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting guest token: $e');
      return null;
    }
  }

  // Validate token function
  Future<bool> validateToken() async {
    final token = await storage.read(key: 'authToken');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validateToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['isValid'];
      } else {
        print('Token validation failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // Logout function (removes token from storage)
  Future<void> logout() async {
    await storage.delete(key: 'authToken');
    await setGuestToken();
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final token = await storage.read(key: 'authToken');
    if (token == null) return true;

    final expiration = getTokenExpiration(token);
    if (expiration == null) return true;

    return expiration.isBefore(DateTime.now());
  }

  // Decode the expiration date from the JWT token
  DateTime? getTokenExpiration(String token) {
    try {
      final payload = token.split('.')[1];
      final decoded = utf8.decode(base64.decode(base64.normalize(payload)));
      final payloadMap = json.decode(decoded);
      if (payloadMap is Map<String, dynamic>) {
        final exp = payloadMap['exp'];
        if (exp is int) {
          return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        }
      }
    } catch (e) {
      print('Error decoding token: $e');
    }
    return null;
  }

  Future<bool> isGuestToken() async {
    final token = await storage.read(key: 'authToken');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validateToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return !result['isValid'];
      } else {
        print('Failed to validate token: ${response.body}');
        return true;
      }
    } catch (e) {
      print("Error sending token validation request: $e");
      return true;
    }
  }
}

class LoginScreen extends StatefulWidget {
  final Function(bool) setAuthenticated;

  const LoginScreen({
    Key? key,
    required this.setAuthenticated,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _attemptLogin() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      final token = await _authService.storage.read(key: 'authToken');
      if (token != null) {
        // Load profile data (win streak, exp, completed levels)
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.loadPreferences();

        widget.setAuthenticated(true);
      } else {
        print("No token found after successful login");
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content:
                const Text('Invalid username or password. Please try again.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _attemptLogin,
                    child: const Text('Login'),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _attemptRegister() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await _authService.register(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      Navigator.pop(context); // Go back to login screen
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: const Text(
                'Username already exists or another issue occurred.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _attemptRegister,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
