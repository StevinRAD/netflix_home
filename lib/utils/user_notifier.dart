import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages reactive user profile state (username & avatar) across all screens.
class UserNotifier {
  static final ValueNotifier<String> username = ValueNotifier<String>('');
  static final ValueNotifier<String?> avatarUrl = ValueNotifier<String?>(null)
    ..addListener(_syncAvatarBytes);
  static final ValueNotifier<Uint8List?> avatarBytes = ValueNotifier<Uint8List?>(null);

  /// Synchronize and memoize base64 bytes once whenever avatarUrl changes
  static void _syncAvatarBytes() {
    final raw = avatarUrl.value;
    if (raw == null || raw.isEmpty) {
      avatarBytes.value = null;
      return;
    }
    if (!raw.startsWith('http')) {
      try {
        final clean = raw.contains(',') ? raw.split(',').last : raw;
        avatarBytes.value = base64Decode(clean.trim());
      } catch (e) {
        debugPrint('UserNotifier base64 decode error: $e');
        avatarBytes.value = null;
      }
    } else {
      avatarBytes.value = null;
    }
  }

  /// Manually update avatar with pre-decoded bytes (fast path)
  static void setAvatarBytes(Uint8List? bytes, String? urlOrBase64) {
    avatarBytes.value = bytes;
    avatarUrl.value = urlOrBase64;
  }

  /// Load cached user profile data from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('session_username');
      final savedAvatar = prefs.getString('session_avatar_url');

      if (savedUsername != null && savedUsername.isNotEmpty) {
        username.value = savedUsername;
      }
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        avatarUrl.value = savedAvatar;
        _syncAvatarBytes();
      }
    } catch (e) {
      debugPrint('UserNotifier init error: $e');
    }
  }

  /// Update user profile data in memory & cache
  static Future<void> update({String? newUsername, String? newAvatarUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    if (newUsername != null) {
      username.value = newUsername;
      await prefs.setString('session_username', newUsername);
    }
    if (newAvatarUrl != null) {
      avatarUrl.value = newAvatarUrl;
      _syncAvatarBytes();
      await prefs.setString('session_avatar_url', newAvatarUrl);
    }
  }

  /// Clear user profile data on logout
  static Future<void> clear() async {
    username.value = '';
    avatarUrl.value = null;
    avatarBytes.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_username');
    await prefs.remove('session_avatar_url');
  }
}
