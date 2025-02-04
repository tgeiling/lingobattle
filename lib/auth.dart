import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider.dart';
import 'services.dart';

class AuthService {
  final String baseUrl =
      'http://34.159.152.1:3000'; // Replace with your server's IP
  final storage = const FlutterSecureStorage();

  // Login function
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final token = jsonDecode(
            response.body)['token']; // Key should match the server response
        if (token != null) {
          await storage.write(key: 'authToken', value: token);
          return true;
        } else {
          print('Token is null');
          return false;
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        print(
            'Login failed: ${response.statusCode}, ${errorResponse['message']}');
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

    bool test = expiration.isBefore(DateTime.now());
    print(test);

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

  void _attemptLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool success = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final levelProvider = Provider.of<LevelNotifier>(context, listen: false);

    if (success) {
      final token = await getAuthToken();

      if (token != null) {
        final profileData = await fetchProfile(token);

        if (profileData != null && profileData.containsKey('completedLevels')) {
          await prefs.clear();

          if (profileData.containsKey('username')) {
            profileProvider.setUsername(profileData['username']);
          }
          if (profileData.containsKey('winStreak')) {
            profileProvider.setWinStreak(profileData['winStreak']);
          }
          if (profileData.containsKey('exp')) {
            profileProvider.setExp(profileData['exp']);
          }
          if (profileData.containsKey('title')) {
            profileProvider.setTitle(profileData['title']);
          }
          if (profileData.containsKey('elo')) {
            profileProvider.setElo(profileData['elo']);
          }
          if (profileData.containsKey('skillLevel')) {
            profileProvider.setSkillLevel(profileData['skillLevel']);
          }

          if (profileData.containsKey('completedLevels')) {
            dynamic completedLevelsData = profileData['completedLevels'];

            profileProvider.setCompletedLevels(completedLevelsData);
          }

          await profileProvider.savePreferences();
          levelProvider.loadLevelsAfterStart();

          widget.setAuthenticated(true);
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          // If no profile data exists, create initial profile
          getAuthToken().then((token) {
            if (token != null) {
              updateProfile(
                token: token,
                winStreak: profileProvider.winStreak,
                exp: profileProvider.exp,
                title: profileProvider.title,
                elo: profileProvider.elo,
                skillLevel: profileProvider.skilllevel,
                completedLevels: profileProvider.completedLevelsJson,
              ).then((success) {
                if (success) {
                  print("Profile updated successfully.");
                } else {
                  print("Failed to update profile.");
                }
              });
            } else {
              print("No auth token available.");
            }
          });

          profileProvider.loadPreferences();
          widget.setAuthenticated(true);
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        print("No token found after successful login");
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              "Login Failed",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Invalid credentials. Please try again.",
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child:
                    const Text("Close", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                child: Image.asset('assets/logo.png',
                    width: MediaQuery.of(context).size.width * 0.15),
              ),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
              style: const TextStyle(color: Colors.black),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              style: const TextStyle(color: Colors.black),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _attemptLogin,
              child: const SizedBox(
                width: double.infinity,
                child: Center(
                    child: Text("Login", style: TextStyle(fontSize: 18))),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(
                    child: Text("Register", style: TextStyle(fontSize: 18))),
              ),
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
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.setUsername(_usernameController.text);
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
