import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_sign_in;
import '../models/account_model.dart';
import '../utils/user_notifier.dart';
import 'presence_service.dart';

class PagedAccountsResult {
  final List<CookieAccount> accounts;
  final int totalCount;

  const PagedAccountsResult({
    required this.accounts,
    required this.totalCount,
  });
}

class AccountsOverview {
  final int totalCount;
  final int liveCount;
  final int premiumCount;
  final int standardCount;
  final int basicCount;
  final int mobileCount;

  const AccountsOverview({
    this.totalCount = 0,
    this.liveCount = 0,
    this.premiumCount = 0,
    this.standardCount = 0,
    this.basicCount = 0,
    this.mobileCount = 0,
  });
}

class SupabaseService {
  // Configurable Supabase credentials (Can be changed in UI Settings or Config)
  static String supabaseUrl = 'https://tscysjowoubdwwaunxbe.supabase.co';
  static String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzY3lzam93b3ViZHd3YXVueGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzMzAyNTUsImV4cCI6MjEwMzkwNjI1NX0.LptRgeVBGCea0p-OwAAqEfg9rdEg0xleSslcsMDKfRE';

  /// Request Password Reset OTP email from Supabase Auth
  static Future<void> sendPasswordResetOtp(String email) async {
    final client = Supabase.instance.client;
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Verify Password Reset OTP token and authenticate recovery session
  static Future<bool> verifyPasswordResetOtp(String email, String token) async {
    final client = Supabase.instance.client;
    final response = await client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
    return response.session != null;
  }

  /// Update password with new password after recovery session is verified
  static Future<void> updatePassword(String newPassword) async {
    final client = Supabase.instance.client;
    await client.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
    await client.auth.signOut();
  }

  static Future<void>? _googleSignInInit;

  static Future<void> _ensureGoogleSignInInitialized() {
    const webClientId = '123668620740-p8piii7m4q7nmok4jeupi5oahbd2uv8p.apps.googleusercontent.com';
    _googleSignInInit ??= g_sign_in.GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: webClientId,
    );
    return _googleSignInInit!;
  }

  /// Sign in with Google via Native Google Sign In
  static Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      
      final googleUser = await g_sign_in.GoogleSignIn.instance.authenticate();
      
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final client = Supabase.instance.client;
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      return false;
    }
  }

  /// Handle Google post-login session setup (profiles check & upsert, shared preferences)
  /// Returns `true` if this user is newly registering via Google and needs onboarding setup,
  /// or `false` if existing user.
  static Future<bool> handleOAuthSession(Session session) async {
    final user = session.user;
    final userId = user.id;
    final email = user.email ?? '';
    final metadata = user.userMetadata ?? {};
    final defaultUsername = (metadata['full_name'] ?? metadata['name'] ?? metadata['username'] ?? (email.isNotEmpty ? email.split('@').first : 'Pengguna')).toString();
    final avatarUrl = metadata['avatar_url']?.toString();

    final prefs = await SharedPreferences.getInstance();
    final deviceId = DateTime.now().millisecondsSinceEpoch.toString();

    await prefs.setString('session_email', email);
    await prefs.setString('session_user_id', userId);
    await prefs.setString('session_device_id', deviceId);
    if (avatarUrl != null) {
      await prefs.setString('session_avatar_url', avatarUrl);
      UserNotifier.avatarUrl.value = avatarUrl;
    }

    // Check if user already exists in profiles table
    bool isNewUser = true;
    try {
      final existingProfile = await fetchUserProfile(userId);
      final hasCompletedLocal = prefs.getBool('onboarding_done_$userId') ?? false;

      if (existingProfile != null &&
          existingProfile['username'] != null &&
          existingProfile['username'].toString().trim().isNotEmpty &&
          hasCompletedLocal) {
        final savedUsername = existingProfile['username'].toString().trim();
        await prefs.setString('session_username', savedUsername);
        UserNotifier.username.value = savedUsername;
        isNewUser = false;
      } else {
        await prefs.setString('session_username', defaultUsername);
        UserNotifier.username.value = defaultUsername;
        isNewUser = true;
      }
    } catch (_) {
      await prefs.setString('session_username', defaultUsername);
      UserNotifier.username.value = defaultUsername;
      isNewUser = true;
    }

    // If existing user, ensure device_id is updated in profiles
    if (!isNewUser) {
      try {
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/profiles'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'id': userId,
            'device_id': deviceId,
          }),
        );
      } catch (_) {}
    }

    return isNewUser;
  }

  /// Complete Google new user profile setup with custom username
  static Future<bool> completeGoogleOnboarding({
    required String userId,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('session_device_id') ?? DateTime.now().millisecondsSinceEpoch.toString();
    final avatarUrl = prefs.getString('session_avatar_url');

    final cleanUsername = username.trim().isNotEmpty ? username.trim() : 'Pengguna';

    try {
      final res = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/profiles'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'id': userId,
          'username': cleanUsername,
          'device_id': deviceId,
          // ignore: use_null_aware_elements
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await prefs.setString('session_username', cleanUsername);
        await prefs.setBool('onboarding_done_$userId', true);
        UserNotifier.username.value = cleanUsername;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error completing Google onboarding: $e');
      return false;
    }
  }

  /// Authenticate user via Supabase Auth
  static Future<bool> login(String usernameOrEmail, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: usernameOrEmail,
        password: password,
      );
      
      if (response.session != null && response.user != null) {
        final userId = response.user!.id;
        
        final prefs = await SharedPreferences.getInstance();
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        
        await prefs.setString('session_email', usernameOrEmail);
        await prefs.setString('session_user_id', userId);
        await prefs.setString('session_device_id', deviceId);
        await prefs.setString('last_email', usernameOrEmail);
        
        // Update device_id in Supabase profiles using Upsert (Insert or Update)
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/profiles'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'id': userId,
            'device_id': deviceId,
          }),
        );

        // Fetch real username and avatar from profiles table
        final profile = await fetchUserProfile(userId);
        final realUsername = (profile != null && profile['username'] != null && profile['username'].toString().trim().isNotEmpty)
            ? profile['username'].toString().trim()
            : (usernameOrEmail.contains('@') ? usernameOrEmail.split('@').first : usernameOrEmail);
        
        await prefs.setString('session_username', realUsername);
        UserNotifier.username.value = realUsername;

        if (profile != null && profile['avatar_url'] != null) {
          final avatarUrl = profile['avatar_url'].toString();
          await prefs.setString('session_avatar_url', avatarUrl);
          UserNotifier.avatarUrl.value = avatarUrl;
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Validate single-device session
  static Future<String> validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('session_user_id');
      final localDeviceId = prefs.getString('session_device_id');
      
      if (userId == null || localDeviceId == null) return 'revoked';
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=device_id'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final remoteDeviceId = data[0]['device_id'];
          return remoteDeviceId == localDeviceId ? 'valid' : 'revoked';
        }
        return 'revoked';
      }
      return 'unavailable';
    } catch (e) {
      // If network fails, return unavailable to allow offline caching 
      // instead of forcefully logging out the user.
      return 'unavailable';
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    await prefs.remove('session_user_id');
    await prefs.remove('session_device_id');
    await prefs.remove('session_username');
    await prefs.remove('session_avatar_url');
    await UserNotifier.clear();
    try {
      await PresenceService.instance.stopTracking();
    } catch (_) {}
    try {
      await g_sign_in.GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  /// Ensure we have a valid userId, resolving from username, email, or device_id if needed
  static Future<String?> getOrResolveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('session_user_id');
    if (userId != null && userId.isNotEmpty) return userId;

    // 1. Try resolving from session_username or UserNotifier.username
    final savedUsername = (prefs.getString('session_username') ?? UserNotifier.username.value).trim();
    if (savedUsername.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?username=eq.${Uri.encodeComponent(savedUsername)}&select=id,username,avatar_url'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
          },
        );
        if (res.statusCode == 200) {
          final List<dynamic> list = jsonDecode(res.body);
          if (list.isNotEmpty && list[0]['id'] != null) {
            userId = list[0]['id'].toString();
            await prefs.setString('session_user_id', userId);
            return userId;
          }
        }
      } catch (e) {
        debugPrint('Resolve userId by username error: $e');
      }
    }

    // 2. Try resolving from device_id
    final deviceId = prefs.getString('session_device_id');
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?device_id=eq.${Uri.encodeComponent(deviceId)}&select=id,username,avatar_url'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
          },
        );
        if (res.statusCode == 200) {
          final List<dynamic> list = jsonDecode(res.body);
          if (list.isNotEmpty && list[0]['id'] != null) {
            userId = list[0]['id'].toString();
            await prefs.setString('session_user_id', userId);
            return userId;
          }
        }
      } catch (e) {
        debugPrint('Resolve userId by deviceId error: $e');
      }
    }

    return null;
  }

  /// Fetch user profile (username, avatar_url, expired_at) from server and sync to UserNotifier
  static Future<Map<String, dynamic>?> fetchUserProfile([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetUserId = userId ?? await getOrResolveUserId();
      if (targetUserId == null) return null;

      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$targetUserId&select=*'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final profile = data[0] as Map<String, dynamic>;
          
          // Sync real username from server
          if (profile['username'] != null && profile['username'].toString().trim().isNotEmpty) {
            final uName = profile['username'].toString().trim();
            await prefs.setString('session_username', uName);
            UserNotifier.username.value = uName;
          }

          // Sync real avatar from server
          final serverAvatar = profile['avatar_url']?.toString();
          if (serverAvatar != null && serverAvatar.isNotEmpty) {
            await prefs.setString('session_avatar_url', serverAvatar);
            UserNotifier.avatarUrl.value = serverAvatar;
          } else {
            // If avatar is null on server, clear local cache so app accurately reflects server
            await prefs.remove('session_avatar_url');
            UserNotifier.avatarUrl.value = null;
          }

          return profile;
        }
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
    return null;
  }

  /// Upload avatar image bytes to Supabase Storage bucket 'avatars'.
  /// Returns the public URL if uploaded to bucket successfully, or null if bucket is unavailable.
  static Future<String?> uploadAvatarToStorageBucket(Uint8List imageBytes, String userId) async {
    try {
      final fileName = '$userId.jpg';
      final uploadUrl = Uri.parse('$supabaseUrl/storage/v1/object/avatars/$fileName');

      final response = await http.post(
        uploadUrl,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true',
        },
        body: imageBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = '$supabaseUrl/storage/v1/object/public/avatars/$fileName?t=${DateTime.now().millisecondsSinceEpoch}';
        return publicUrl;
      } else {
        debugPrint('Storage bucket upload returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Storage bucket upload error: $e');
    }
    return null;
  }

  /// Update or upload user profile avatar to Supabase DB profiles table.
  /// If [rawBytes] is provided, it first attempts to upload the photo to Supabase Storage Bucket 'avatars'
  /// so you can view/preview actual image files in the Supabase Dashboard.
  /// If the bucket is not yet configured, it automatically falls back to storing base64 in profiles.avatar_url.
  static Future<bool> updateProfileAvatar(String? avatarDataOrUrl, {Uint8List? rawBytes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getOrResolveUserId();

      if (userId == null) {
        debugPrint('Update avatar failed: could not resolve user ID.');
        return false;
      }

      // If removing avatar (both are null / empty)
      if ((avatarDataOrUrl == null || avatarDataOrUrl.isEmpty) && rawBytes == null) {
        try {
          await http.delete(
            Uri.parse('$supabaseUrl/storage/v1/object/avatars/$userId.jpg'),
            headers: {
              'apikey': supabaseAnonKey,
              'Authorization': 'Bearer $supabaseAnonKey',
            },
          );
        } catch (_) {}

        final patchRes = await http.patch(
          Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'avatar_url': null}),
        );

        if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
          await prefs.remove('session_avatar_url');
          UserNotifier.avatarUrl.value = null;
          return true;
        }
        return false;
      }

      // 1. Try uploading to Storage Bucket 'avatars' first
      String? finalAvatarUrl;
      if (rawBytes != null && rawBytes.isNotEmpty) {
        final bucketUrl = await uploadAvatarToStorageBucket(rawBytes, userId);
        if (bucketUrl != null) {
          finalAvatarUrl = bucketUrl;
          debugPrint('Stored photo in Supabase Storage bucket: $finalAvatarUrl');
        }
      }

      // 2. Fallback to base64 if bucket upload was not successful
      finalAvatarUrl ??= avatarDataOrUrl;
      if (finalAvatarUrl == null || finalAvatarUrl.isEmpty) return false;

      // 3. Save finalAvatarUrl to profiles.avatar_url
      final patchResponse = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'avatar_url': finalAvatarUrl,
        }),
      );

      bool isSuccess = (patchResponse.statusCode == 200 || patchResponse.statusCode == 204);

      // If PATCH returned 200 but representation is empty list, or if not 200, try POST upsert
      if (!isSuccess || (patchResponse.statusCode == 200 && patchResponse.body.trim() == '[]')) {
        final postResponse = await http.post(
          Uri.parse('$supabaseUrl/rest/v1/profiles'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
          body: jsonEncode({
            'id': userId,
            'avatar_url': finalAvatarUrl,
          }),
        );

        isSuccess = (postResponse.statusCode == 200 ||
            postResponse.statusCode == 201 ||
            postResponse.statusCode == 204);
        if (!isSuccess) {
          debugPrint('Supabase avatar POST upsert error: ${postResponse.statusCode}: ${postResponse.body}');
        }
      }

      if (isSuccess) {
        // Sync local cache only after database confirms success
        await prefs.setString('session_avatar_url', finalAvatarUrl);
        UserNotifier.avatarUrl.value = finalAvatarUrl;
        return true;
      } else {
        debugPrint('Supabase avatar update error: ${patchResponse.statusCode}: ${patchResponse.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Update avatar exception: $e');
      return false;
    }
  }

  /// Update user username in profiles table
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getOrResolveUserId();
      if (userId == null) return false;

      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'username': newUsername,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await prefs.setString('session_username', newUsername);
        UserNotifier.username.value = newUsername;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update username error: $e');
      return false;
    }
  }

  /// Fetch user subscription expiry date
  static Future<Map<String, dynamic>?> fetchAnnouncement() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/app_settings?select=announcement_active,announcement_text,maintenance_mode&limit=1'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error fetching announcement: $e');
    }
    return null;
  }

  static Future<DateTime?> fetchExpiryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('session_user_id') ?? await getOrResolveUserId();
      if (userId == null) return null;

      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=expired_at'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['expired_at'] != null) {
          return DateTime.parse(data[0]['expired_at']);
        }
      }
    } catch (e) {
      print('Fetch expiry error: $e');
    }
    return null;
  }

  /// Check if current user package is active (not null and not expired)
  static Future<bool> isPackageActive() async {
    final expiry = await fetchExpiryDate();
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  /// Redeem a voucher code using Supabase RPC
  static Future<Map<String, dynamic>> redeemVoucher(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('session_user_id');
    if (userId == null) {
      return {'success': false, 'message': 'User tidak ditemukan. Silakan login ulang.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/redeem_voucher'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_user_id': userId,
          'p_code': code,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? 'Gagal menukar kode voucher. (Error ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }


  /// Register user via Supabase Auth
  static Future<void> register(String email, String password, String username) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'username': username,
        }
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error_description'] ?? errorData['msg'] ?? 'Register gagal');
    }

    // Attempt to upsert the username into the profiles table
    try {
      final responseData = jsonDecode(response.body);
      final userId = responseData['user']?['id'] ?? responseData['id'];
      if (userId != null) {
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/profiles'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'id': userId,
            'username': username,
          }),
        );
      }
    } catch (e) {
      print('Failed to upsert username to profiles: $e');
    }
  }

  /// Change user password
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('session_email');
    if (email == null) throw Exception('Email sesi tidak ditemukan. Silakan login ulang.');

    // 1. Verify current password by logging in
    final loginResponse = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': currentPassword,
      }),
    );

    if (loginResponse.statusCode != 200) {
      throw Exception('Password saat ini salah.');
    }

    final data = jsonDecode(loginResponse.body);
    final accessToken = data['access_token'];
    if (accessToken == null) throw Exception('Gagal mendapatkan token akses.');

    // 2. Update password
    final updateResponse = await http.put(
      Uri.parse('$supabaseUrl/auth/v1/user'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password': newPassword,
      }),
    );

    if (updateResponse.statusCode != 200) {
      final errorData = jsonDecode(updateResponse.body);
      throw Exception(errorData['error_description'] ?? errorData['msg'] ?? 'Gagal memperbarui password server.');
    }
  }


  /// Fetch fast overview of accounts (total count, live count, and plan breakdown) without heavy cookies
  static Future<AccountsOverview> fetchAccountsOverview() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/cookie_accounts?select=status,plan_name'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Prefer': 'count=exact',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        int total = 0;
        final contentRange = response.headers['content-range'];
        if (contentRange != null && contentRange.contains('/')) {
          total = int.tryParse(contentRange.split('/').last.trim()) ?? 0;
        }

        final List<dynamic> list = jsonDecode(response.body);
        if (total == 0) total = list.length;

        int live = 0;
        int premium = 0;
        int standard = 0;
        int basic = 0;
        int mobile = 0;

        for (final item in list) {
          final status = (item['status'] ?? '').toString().toUpperCase();
          final plan = (item['plan_name'] ?? '').toString().toLowerCase();

          if (status == 'LIVE') live++;
          if (plan.contains('premium')) {
            premium++;
          } else if (plan.contains('standard')) {
            standard++;
          } else if (plan.contains('basic')) {
            basic++;
          } else if (plan.contains('mobile')) {
            mobile++;
          }
        }

        return AccountsOverview(
          totalCount: total,
          liveCount: live,
          premiumCount: premium,
          standardCount: standard,
          basicCount: basic,
          mobileCount: mobile,
        );
      }
    } catch (_) {}
    return const AccountsOverview();
  }

  static const List<String> priorityCountries = [
    'ID', 'SG', 'MY', 'PH', 'TH', 'IN', 'US'
  ];
  static const String priorityCountriesPostgrestIn = 'in.(ID,SG,MY,PH,TH,IN,US)';

  /// Helper to build query filter parameters for Supabase REST API
  static String buildFilterParams({
    String? planName,
    String? searchQuery,
    String? regionFilter,
    bool prioritizeNearby = true,
  }) {
    String params = '';

    // Plan filter
    if (planName != null &&
        planName.isNotEmpty &&
        planName != 'Semua' &&
        planName != 'All') {
      params += '&plan_name=ilike.*$planName*';
    }

    final trimmedSearch = searchQuery?.trim() ?? '';
    final detectedCountry = trimmedSearch.isNotEmpty
        ? CookieAccount.detectCountryCode(trimmedSearch)
        : null;

    if (detectedCountry != null) {
      // User specifically searched for a country/region! Strictly filter by that country code
      params += '&country=eq.$detectedCountry';
    } else if (trimmedSearch.isNotEmpty) {
      // General keyword search (email, filename, phone)
      final q = Uri.encodeComponent(trimmedSearch);
      params += '&or=(email.ilike.*$q*,filename.ilike.*$q*,phone.ilike.*$q*)';

      if (regionFilter != null &&
          regionFilter.isNotEmpty &&
          regionFilter != 'Semua' &&
          regionFilter != 'All') {
        params += '&country=eq.$regionFilter';
      }
    } else {
      if (regionFilter != null &&
          regionFilter.isNotEmpty &&
          regionFilter != 'Semua' &&
          regionFilter != 'All') {
        params += '&country=eq.$regionFilter';
      }
    }

    return params;
  }

  /// Fetch accounts filtered by specific plan (default 5 accounts per page)
  static Future<PagedAccountsResult> fetchAccountsByPlan(
    String planName, {
    int limit = 5,
    int offset = 0,
    String? searchQuery,
    String? regionFilter,
    bool prioritizeNearby = true,
  }) async {
    try {
      final filter = buildFilterParams(
        planName: planName,
        searchQuery: searchQuery,
        regionFilter: regionFilter,
        prioritizeNearby: prioritizeNearby,
      );

      String query =
          '$supabaseUrl/rest/v1/cookie_accounts?select=*&order=created_at.desc&limit=$limit&offset=$offset$filter';

      var response = await http.get(
        Uri.parse(query),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Prefer': 'count=exact',
        },
      );

      int total = 0;
      final contentRange = response.headers['content-range'];
      if (contentRange != null && contentRange.contains('/')) {
        final countPart = contentRange.split('/').last.trim();
        total = int.tryParse(countPart) ?? 0;
      }

      List<CookieAccount> accounts = [];
      if (response.statusCode == 200 || response.statusCode == 206) {
        final List<dynamic> list = jsonDecode(response.body);
        accounts = list.map((json) => CookieAccount.fromJson(json)).toList();
        if (total == 0) total = accounts.length;
      }

      // Prioritize regional order: ID > SG > MY > PH > TH > IN > US > others

      // Prioritize regional order: ID > SG > MY > PH > TH > IN > US > others
      accounts.sort((a, b) => a.regionPriority.compareTo(b.regionPriority));

      return PagedAccountsResult(accounts: accounts, totalCount: total);
    } catch (_) {}
    return const PagedAccountsResult(accounts: [], totalCount: 0);
  }

  /// Fetch balanced mix across all 4 plans (~25% each: Basic, Standard, Premium, Mobile)
  static Future<({List<CookieAccount> accounts, int totalCount, Map<String, int> planTotals})>
      fetchBalancedAccounts({
    int basicOffset = 0,
    int standardOffset = 0,
    int premiumOffset = 0,
    int mobileOffset = 0,
    int countPerPlan = 3,
    String? searchQuery,
    String? regionFilter,
  }) async {
    final results = await Future.wait([
      fetchAccountsByPlan('Premium', limit: countPerPlan, offset: premiumOffset, searchQuery: searchQuery, regionFilter: regionFilter),
      fetchAccountsByPlan('Standard', limit: countPerPlan, offset: standardOffset, searchQuery: searchQuery, regionFilter: regionFilter),
      fetchAccountsByPlan('Basic', limit: countPerPlan, offset: basicOffset, searchQuery: searchQuery, regionFilter: regionFilter),
      fetchAccountsByPlan('Mobile', limit: countPerPlan, offset: mobileOffset, searchQuery: searchQuery, regionFilter: regionFilter),
    ]);

    final premRes = results[0];
    final stdRes = results[1];
    final bscRes = results[2];
    final mobRes = results[3];

    final combined = <CookieAccount>[
      ...premRes.accounts,
      ...stdRes.accounts,
      ...bscRes.accounts,
      ...mobRes.accounts,
    ];

    // Priority sort: ID, SG, MY, PH, TH, IN, US first
    combined.sort((a, b) => a.regionPriority.compareTo(b.regionPriority));

    final total = premRes.totalCount + stdRes.totalCount + bscRes.totalCount + mobRes.totalCount;

    return (
      accounts: combined,
      totalCount: total,
      planTotals: {
        'Premium': premRes.totalCount,
        'Standard': stdRes.totalCount,
        'Basic': bscRes.totalCount,
        'Mobile': mobRes.totalCount,
      },
    );
  }

  /// Fetch Cookie Accounts with pagination (default 10 accounts) and total DB count
  static Future<PagedAccountsResult> fetchCookieAccountsPaged({
    int limit = 10,
    int offset = 0,
    String? planFilter,
    String? searchQuery,
    String? regionFilter,
    bool prioritizeNearby = true,
  }) async {
    try {
      final filter = buildFilterParams(
        planName: planFilter,
        searchQuery: searchQuery,
        regionFilter: regionFilter,
        prioritizeNearby: prioritizeNearby,
      );

      String query =
          '$supabaseUrl/rest/v1/cookie_accounts?select=*&order=created_at.desc&limit=$limit&offset=$offset$filter';

      var response = await http.get(
        Uri.parse(query),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Prefer': 'count=exact',
        },
      );

      int total = 0;
      final contentRange = response.headers['content-range'];
      if (contentRange != null && contentRange.contains('/')) {
        final countPart = contentRange.split('/').last.trim();
        total = int.tryParse(countPart) ?? 0;
      }

      List<CookieAccount> accounts = [];
      if (response.statusCode == 200 || response.statusCode == 206) {
        final List<dynamic> list = jsonDecode(response.body);
        accounts = list.map((json) => CookieAccount.fromJson(json)).toList();
        if (total == 0) total = accounts.length;
      }

      accounts.sort((a, b) => a.regionPriority.compareTo(b.regionPriority));

      return PagedAccountsResult(accounts: accounts, totalCount: total);
    } catch (_) {
      return const PagedAccountsResult(accounts: [], totalCount: 0);
    }
  }

  /// Fetch counts for all plan categories simultaneously, taking search query and region into account
  static Future<Map<String, int>> fetchAllPlanCounts({
    String? searchQuery,
    String? regionFilter,
  }) async {
    try {
      final results = await Future.wait([
        _fetchSinglePlanCount(null, searchQuery: searchQuery, regionFilter: regionFilter),
        _fetchSinglePlanCount('Premium', searchQuery: searchQuery, regionFilter: regionFilter),
        _fetchSinglePlanCount('Standard', searchQuery: searchQuery, regionFilter: regionFilter),
        _fetchSinglePlanCount('Basic', searchQuery: searchQuery, regionFilter: regionFilter),
        _fetchSinglePlanCount('Mobile', searchQuery: searchQuery, regionFilter: regionFilter),
      ]);

      return {
        'Semua': results[0],
        'Premium': results[1],
        'Standard': results[2],
        'Basic': results[3],
        'Mobile': results[4],
      };
    } catch (_) {
      return {
        'Semua': 0,
        'Premium': 0,
        'Standard': 0,
        'Basic': 0,
        'Mobile': 0,
      };
    }
  }

  static Future<int> _fetchSinglePlanCount(
    String? planName, {
    String? searchQuery,
    String? regionFilter,
  }) async {
    try {
      final filter = buildFilterParams(
        planName: planName,
        searchQuery: searchQuery,
        regionFilter: regionFilter,
        prioritizeNearby: false,
      );

      final query = '$supabaseUrl/rest/v1/cookie_accounts?select=id&limit=0$filter';

      final response = await http.get(
        Uri.parse(query),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Prefer': 'count=exact',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentRange = response.headers['content-range'];
        if (contentRange != null && contentRange.contains('/')) {
          final countPart = contentRange.split('/').last.trim();
          return int.tryParse(countPart) ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Fetch Cookie Accounts from Supabase DB Table `cookie_accounts` with auto-pagination (>1000 accounts)
  static Future<List<CookieAccount>> fetchCookieAccounts() async {
    final List<CookieAccount> allAccounts = [];
    int offset = 0;
    const int batchSize = 1000;

    try {
      while (true) {
        final response = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/cookie_accounts?select=*&order=created_at.desc&limit=$batchSize&offset=$offset'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> list = jsonDecode(response.body);
          if (list.isEmpty) break;
          allAccounts.addAll(list.map((json) => CookieAccount.fromJson(json)));
          if (list.length < batchSize) break;
          offset += batchSize;
        } else {
          print('Fetch accounts batch error (offset $offset): ${response.statusCode} - ${response.body}');
          break;
        }
      }
      allAccounts.sort((a, b) => a.regionPriority.compareTo(b.regionPriority));
      return allAccounts;
    } catch (e) {
      print('Fetch error: $e');
      return allAccounts.isNotEmpty ? allAccounts : [];
    }
  }

  /// Add new Cookie Account to Supabase DB
  static Future<bool> addCookieAccount(CookieAccount account) async {
    try {
      final Map<String, dynamic> data = account.toJson();
      // Remove 'id' because Supabase generates it automatically as UUID
      data.remove('id'); 
      // Remove 'created_at' to use Supabase default timestamp
      data.remove('created_at');

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/cookie_accounts'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        print('Error inserting account: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      print('Add error: $e');
      return false;
    }
  }

  /// Delete Cookie Account by ID
  static Future<bool> deleteCookieAccount(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/cookie_accounts?id=eq.$id'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  /// Sync .txt files directly from Supabase Storage (bucket: cookies)
  static Future<int> syncTxtFilesFromStorage() async {
    int successCount = 0;
    
    // 1. List files in 'cookies' bucket
    final listResponse = await http.post(
      Uri.parse('$supabaseUrl/storage/v1/object/list/cookies'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "prefix": "",
        "limit": 100,
        "offset": 0,
        "sortBy": {"column": "name", "order": "asc"}
      }),
    );

    if (listResponse.statusCode != 200) {
      throw Exception('Gagal membaca bucket (Error ${listResponse.statusCode}): ${listResponse.body}. Pastikan Bucket "cookies" sudah di-set Public dan memiliki Storage Policy untuk SELECT.');
    }

    final List<dynamic> files = jsonDecode(listResponse.body);
    
    if (files.isEmpty) {
      throw Exception('Bucket "cookies" kosong atau file tidak ditemukan.');
    }

    for (var fileData in files) {
      final String filename = fileData['name'];
      
      if (!filename.toLowerCase().endsWith('.txt')) continue;

      // 2. Download file content
      final getResponse = await http.get(
        Uri.parse('$supabaseUrl/storage/v1/object/authenticated/cookies/$filename'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (getResponse.statusCode == 200) {
        final content = utf8.decode(getResponse.bodyBytes);
        
        // 3. Parse and Insert to DB
        final account = CookieAccount.fromRawText(
          content,
          filename: filename,
          id: DateTime.now().millisecondsSinceEpoch.toString() + successCount.toString(),
        );
        
        final addSuccess = await addCookieAccount(account);
        
        if (addSuccess) {
          successCount++;
          // 4. (Optional) Delete the file from storage after successful sync to avoid duplicates
          await http.delete(
            Uri.parse('$supabaseUrl/storage/v1/object/cookies/$filename'),
            headers: {
              'apikey': supabaseAnonKey,
              'Authorization': 'Bearer $supabaseAnonKey',
            },
          );
        }
      }
    }
    
    if (successCount == 0 && files.isNotEmpty) {
      throw Exception('Ditemukan file di bucket, tapi tidak ada file .txt yang berhasil diimpor.');
    }

    return successCount;
  }
}
