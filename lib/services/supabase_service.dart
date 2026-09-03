import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';

class SupabaseService {
  // Configurable Supabase credentials (Can be changed in UI Settings or Config)
  static String supabaseUrl = 'https://tscysjowoubdwwaunxbe.supabase.co';
  static String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzY3lzam93b3ViZHd3YXVueGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzMzAyNTUsImV4cCI6MjEwMzkwNjI1NX0.LptRgeVBGCea0p-OwAAqEfg9rdEg0xleSslcsMDKfRE';

  /// Authenticate user via Supabase Auth
  static Future<bool> login(String usernameOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': usernameOrEmail,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['user']['id'];
        
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
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Validate single-device session
  static Future<bool> validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('session_user_id');
      final localDeviceId = prefs.getString('session_device_id');
      
      if (userId == null || localDeviceId == null) return false;
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=device_id'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final remoteDeviceId = data[0]['device_id'];
          return remoteDeviceId == localDeviceId;
        }
      }
      return false;
    } catch (e) {
      // If network fails, we might want to allow offline access or deny it.
      // Deny for strict single-device policy.
      return false;
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    await prefs.remove('session_user_id');
    await prefs.remove('session_device_id');
  }

  /// Fetch user subscription expiry date
  static Future<DateTime?> fetchExpiryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('session_user_id');
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

  /// Fetch Cookie Accounts from Supabase DB Table `cookie_accounts`
  static Future<List<CookieAccount>> fetchCookieAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/cookie_accounts?select=*&order=created_at.desc'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => CookieAccount.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch error: $e');
    }
    return [];
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
