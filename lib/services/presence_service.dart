import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  RealtimeChannel? _channel;
  String? _currentUserId;
  String? _currentUsername;
  bool _isTracking = false;
  bool _hasLoggedAppOpen = false;
  Timer? _heartbeatTimer;

  static PresenceService get instance => _instance;

  /// Start tracking user presence and log app opening
  Future<void> startTracking() async {
    if (_isTracking && _channel != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('session_user_id');
      var username = prefs.getString('session_username') ?? 'Pengguna';

      if (userId == null || userId.isEmpty) {
        userId = await SupabaseService.getOrResolveUserId();
      }

      if (userId == null || userId.isEmpty) {
        debugPrint('[PresenceService] No valid userId found, skipping presence tracking.');
        return;
      }

      _currentUserId = userId;
      _currentUsername = username;
      _isTracking = true;

      // Register lifecycle observer to handle background / foreground transitions
      WidgetsBinding.instance.removeObserver(this);
      WidgetsBinding.instance.addObserver(this);

      // Join Realtime Presence channel
      _initPresenceChannel();

      // Log App Open event once per active session
      if (!_hasLoggedAppOpen) {
        _hasLoggedAppOpen = true;
        _logAppOpen(userId, username);
      }

      // Keep heartbeat alive every 45 seconds
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        _trackCurrentState();
      });
    } catch (e) {
      debugPrint('[PresenceService] Error starting presence: $e');
    }
  }

  void _initPresenceChannel() {
    try {
      _channel?.unsubscribe();
      final client = Supabase.instance.client;
      _channel = client.channel('online-users');

      _channel!.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('[PresenceService] Subscribed to online-users channel.');
          await _trackCurrentState();
        }
      });
    } catch (e) {
      debugPrint('[PresenceService] Error init channel: $e');
    }
  }

  Future<void> _trackCurrentState() async {
    if (_channel == null || _currentUserId == null) return;
    try {
      await _channel?.track({
        'user_id': _currentUserId,
        'username': _currentUsername ?? 'Pengguna',
        'online_at': DateTime.now().toUtc().toIso8601String(),
        'platform': 'flutter_app',
      });
    } catch (e) {
      debugPrint('[PresenceService] Error tracking presence: $e');
    }
  }

  Future<void> _untrackCurrentState() async {
    try {
      await _channel?.untrack();
    } catch (e) {
      debugPrint('[PresenceService] Error untracking: $e');
    }
  }

  /// Stop tracking when logging out
  Future<void> stopTracking() async {
    _isTracking = false;
    _hasLoggedAppOpen = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    WidgetsBinding.instance.removeObserver(this);

    try {
      await _untrackCurrentState();
      await _channel?.unsubscribe();
      _channel = null;
    } catch (e) {
      debugPrint('[PresenceService] Error stopping presence: $e');
    }
  }

  /// Record app open in activity_logs table for dashboard history
  Future<void> _logAppOpen(String userId, String username) async {
    try {
      final url = Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/activity_logs');
      await http.post(
        url,
        headers: {
          'apikey': SupabaseService.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'action': 'APP_OPEN',
          'entity_type': 'user',
          'entity_id': userId,
          'description': 'Pengguna $username membuka aplikasi',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('[PresenceService] Failed to log app open: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint('[PresenceService] App resumed -> Tracking online');
      _trackCurrentState();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached ||
               state == AppLifecycleState.hidden) {
      debugPrint('[PresenceService] App in background -> Untracking online');
      _untrackCurrentState();
    }
  }
}
