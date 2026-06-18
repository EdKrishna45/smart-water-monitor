import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/user_profile.dart';

class AuthService {
  static String get _baseUrl {
    return 'https://smart-water-monitor-api.onrender.com';
  }
  static const String _keyCurrentUser = 'current_user';
  static bool firebaseInitialized = false;

  Future<void> setDemoMode(bool isDemo) async {
    // No-op
  }

  // Demo mode is now effectively disabled since we have a real backend
  Future<bool> isDemoMode() async {
    return false;
  }

  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': displayName,
        'phone_number': (phoneNumber != null && phoneNumber.trim().isNotEmpty) ? phoneNumber.trim() : null,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserProfile(
        uid: data['uid'],
        email: data['email'],
        displayName: data['name'],
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${data['uid']}',
        phoneNumber: data['phone_number'],
        createdAt: DateTime.now(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, user.toJson());
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to register');
    }
  }

  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email_or_phone': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserProfile(
        uid: data['uid'],
        email: data['email'],
        displayName: data['name'],
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=${data['uid']}',
        phoneNumber: data['phone_number'],
        createdAt: DateTime.now(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, user.toJson());
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to login');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyCurrentUser);
    if (userJson != null) {
      return UserProfile.fromJson(userJson);
    }
    return null;
  }

  Future<UserProfile> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: kIsWeb 
            ? '1021000348027-5as4rejvr7jvl8i55eqi6ico8urqs1ul.apps.googleusercontent.com' 
            : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Sign in aborted by user.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'name': googleUser.displayName ?? googleUser.email.split('@')[0],
          'google_id': googleUser.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserProfile(
          uid: data['uid'],
          email: data['email'],
          displayName: data['name'],
          photoUrl: googleUser.photoUrl ?? 'https://api.dicebear.com/7.x/bottts/png?seed=${data['uid']}',
          phoneNumber: data['phone_number'],
          createdAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyCurrentUser, user.toJson());
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to authenticate with Google on backend.');
      }
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<String> sendPasswordResetOtp(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contact': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['otp'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to send OTP');
    }
  }

  Future<void> resetPasswordAfterOtp(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contact': email,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to reset password');
    }
  }

  Future<bool> changePassword(String uid, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to change password');
    }
  }
  Future<UserProfile> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? photoBase64,
  }) async {
    final Map<String, dynamic> requestBody = {};
    if (name != null) requestBody['name'] = name;
    if (phoneNumber != null) requestBody['phone_number'] = phoneNumber;
    if (photoBase64 != null) requestBody['photo_base64'] = photoBase64;

    final response = await http.put(
      Uri.parse('$_baseUrl/auth/profile/$uid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currentUser = await getCurrentUser();
      
      final updatedUser = UserProfile(
        uid: data['uid'],
        email: data['email'],
        displayName: data['name'],
        photoUrl: data['photo_url'] ?? currentUser?.photoUrl ?? 'https://api.dicebear.com/7.x/bottts/png?seed=${data['uid']}',
        phoneNumber: data['phone_number'],
        createdAt: currentUser?.createdAt ?? DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, updatedUser.toJson());
      return updatedUser;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update profile');
    }
  }
}
