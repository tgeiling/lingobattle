import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getAuthToken() async {
  const storage = FlutterSecureStorage();
  try {
    final String? token = await storage.read(key: 'authToken');
    return token;
  } catch (e) {
    print("Error reading token from secure storage: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> fetchProfile(String token) async {
  final Uri apiUrl = Uri.parse('http://34.159.152.1:3000/profile');

  try {
    final response = await http.get(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> profileData = jsonDecode(response.body);
      return profileData;
    } else {
      print('Failed to fetch profile: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error fetching profile: $e');
    return null;
  }
}

void fetchAndPrintProfile(String token) async {
  Map<String, dynamic>? profileData = await fetchProfile(token);

  if (profileData != null) {
    print('Profile Data: $profileData');
  } else {
    print('Failed to fetch profile or no data returned.');
  }
}

Future<bool> updateProfile({
  required String token,
  int? winStreak,
  int? exp,
  String? completedLevels, // Per-language progress
  String? title,
  Map<String, int>? eloMap, // Now supports multiple ELOs per language
  int? skillLevel,
}) async {
  final Uri apiUrl = Uri.parse('http://34.159.152.1:3000/updateProfile');

  Map<String, dynamic> body = {};

  if (winStreak != null) body['winStreak'] = winStreak;
  if (exp != null) body['exp'] = exp;
  if (completedLevels != null)
    body['completedLevels'] = completedLevels; // Send as map
  if (title != null) body['title'] = title;
  if (eloMap != null && eloMap.isNotEmpty) body['elo'] = eloMap; // Now a map
  if (skillLevel != null) body['skillLevel'] = skillLevel;

  try {
    final response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body), // Convert to JSON
    );

    if (response.statusCode == 200) {
      print('Profile updated successfully.');
      return true;
    } else {
      print('Failed to update profile: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error updating profile: $e');
    return false;
  }
}

int weekNumber(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1, 0, 0);
  final firstMonday = startOfYear.weekday;
  final daysInFirstWeek = 8 - firstMonday;
  final diff = date.difference(startOfYear);
  var weeks = ((diff.inDays - daysInFirstWeek) / 7).ceil();
  if (daysInFirstWeek > 3) {
    weeks += 1;
  }
  return weeks;
}

/* const String serverUrl = 'http://35.246.224.168/validate-receipt';

Future<bool> validateAppleReceipt(String receiptData) async {
  return await _validateReceipt(receiptData, platform: 'apple');
}

Future<bool> validateGoogleReceipt(String receiptData) async {
  return await _validateReceipt(receiptData, platform: 'google');
}

Future<bool> _validateReceipt(String receiptData, {required String platform}) async {
  try {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'platform': platform,
        'receiptData': receiptData,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['valid'] == true;
    } else {
      print('Failed to validate receipt: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error validating receipt: $e');
    return false;
  }
}
 */