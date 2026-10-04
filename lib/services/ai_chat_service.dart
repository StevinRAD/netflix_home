import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// AI Chat Service menggunakan OpenAI-compatible API
/// Menyediakan auto-reply cerdas untuk Live CS
class AiChatService {
  // AI configuration should be loaded from backend or environment, never hardcoded.
  // We use Supabase Edge Functions for secure AI calls.

  /// Cek apakah AI server aktif/online
  static Future<bool> isAvailable() async {
    try {
      final client = Supabase.instance.client;
      // Calling a lightweight health-check endpoint on the Edge Function
      final response = await client.functions.invoke('ai_chat_health').timeout(const Duration(seconds: 5));
      return response.status == 200;
    } catch (e) {
      debugPrint('AI service unavailable: $e');
      return false;
    }
  }

  /// Ambil context data aplikasi untuk diberikan ke AI
  static Future<String> _buildSystemContext() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('session_username') ?? 'Pengguna';
    final userId = prefs.getString('session_user_id');

    // Ambil data profil user
    String profileInfo = '';
    String accountsInfo = '';
    String voucherInfo = '';
    String settingsInfo = '';

    try {
      final client = Supabase.instance.client;

      // 1. Profil user saat ini
      if (userId != null) {
        final profile = await client
            .from('profiles')
            .select('username, expired_at, created_at')
            .eq('id', userId)
            .maybeSingle();

        if (profile != null) {
          final expiredAt = profile['expired_at'];
          final createdAt = profile['created_at'];
          final isExpired = expiredAt != null
              ? DateTime.parse(expiredAt).isBefore(DateTime.now())
              : true;
          profileInfo = '''
- Nama pengguna: ${profile['username'] ?? username}
- Masa aktif: ${expiredAt ?? 'Belum ada paket'}
- Status langganan: ${expiredAt == null ? 'Belum berlangganan' : (isExpired ? 'EXPIRED (sudah habis)' : 'AKTIF')}
- Bergabung sejak: ${createdAt ?? 'Tidak diketahui'}''';
        }
      }

      // 2. Statistik akun Netflix yang tersedia (akurat dari database via Supabase API)
      try {
        final overview = await SupabaseService.fetchAccountsOverview();
        if (overview.totalCount > 0) {
          accountsInfo = '''
- Total akun Netflix di database: ${overview.totalCount} akun
- Akun aktif (status LIVE): ${overview.liveCount} akun
- Rincian paket: Premium (${overview.premiumCount}), Standard (${overview.standardCount}), Basic (${overview.basicCount}), Mobile (${overview.mobileCount})''';
        } else {
          final accounts = await client
              .from('cookie_accounts')
              .select('status, plan_name')
              .limit(1000);
          final total = accounts.length;
          final live = accounts
              .where((a) => (a['status'] ?? '').toString().toUpperCase() == 'LIVE')
              .length;
          accountsInfo = '''
- Total akun Netflix di database: $total akun
- Akun aktif (status LIVE): $live akun''';
        }
      } catch (e) {
        debugPrint('Error loading accounts info for AI: $e');
      }

      // 3. Info voucher aktif
      try {
        final vouchers = await client
            .from('vouchers')
            .select('code, duration_days, is_active')
            .eq('is_active', true)
            .limit(20);

        if (vouchers.isNotEmpty) {
          voucherInfo =
              '- Jumlah voucher aktif: ${vouchers.length} voucher tersedia';
        }
      } catch (_) {}

      // 4. Info settings/pengaturan umum
      try {
        final settings = await client
            .from('app_settings')
            .select('key, value')
            .limit(20);

        if (settings.isNotEmpty) {
          final settingsList = settings
              .map((s) => '${s['key']}: ${s['value']}')
              .join(', ');
          settingsInfo = '- Pengaturan: $settingsList';
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error building AI context: $e');
    }

    return '''
Kamu adalah "Netflix Home Assistant", asisten AI customer service untuk aplikasi Netflix Home.
Netflix Home adalah aplikasi penyedia akses akun Netflix premium bersama (shared accounts).

IDENTITAS:
- Nama: Netflix Home Assistant
- Peran: Customer Service AI untuk membantu pengguna aplikasi Netflix Home
- Bahasa: Selalu gunakan Bahasa Indonesia yang ramah, sopan, dan informatif
- Gaya: Ramah, professional, menggunakan emoji sesekali

FORMAT JAWABAN (WAJIB DIIKUTI):
- Selalu jawab dengan FORMAT TERSTRUKTUR agar mudah dibaca user
- Gunakan **teks tebal** untuk kata/frasa penting (judul langkah, nama menu, tombol)
- Gunakan nomor urut (1. 2. 3.) untuk langkah-langkah berurutan
- Gunakan bullet (• atau -) untuk daftar item yang tidak berurutan
- Gunakan emoji di awal setiap section/judul untuk visual yang menarik
- Pisahkan section dengan baris kosong agar rapi
- Maksimal 5-8 baris per jawaban, jangan terlalu panjang
- Berikan navigasi yang jelas: sebutkan nama tab/menu/tombol yang perlu diklik user
- Jika ada langkah, selalu gunakan format: "**Langkah X:** Deskripsi"

CONTOH FORMAT JAWABAN YANG BAIK:
---
📱 **Cara Login di HP**

1. Buka tab **Daftar Akun** di menu bawah
2. Pilih akun yang berstatus **Aktif** (hijau)
3. Tekan tombol **Gunakan Akun Ini**
4. Pilih perangkat **HP/Android/iPhone**
5. Tekan **Buka Netflix Sekarang**

✅ Selesai! Netflix akan terbuka dan login otomatis.
---

NAVIGASI APLIKASI (untuk mengarahkan user):
- **Tab Beranda** → Dashboard utama, info masa aktif, status akun
- **Tab Daftar Akun** → Pilih dan gunakan akun Netflix (HP/PC/Smart TV)
- **Tab Profil** → Info profil, tukar voucher, pengaturan, bantuan
- **Menu Bantuan** → Live CS (chat ini), FAQ, panduan penggunaan
- **Tombol "Gunakan Akun Ini"** → Muncul setelah pilih akun, pilih perangkat
- **Tombol "Tukar Voucher"** → Di halaman Profil, untuk perpanjang masa aktif

DATA PENGGUNA SAAT INI:
$profileInfo

DATA APLIKASI:
$accountsInfo
$voucherInfo
$settingsInfo

PANDUAN FAQ APLIKASI:
1. **Cara pakai:** Buka tab **Daftar Akun** → Pilih akun berstatus **Aktif** → Klik **Gunakan Akun Ini** → Pilih perangkat (HP/Laptop/Smart TV)
2. **Login HP:** Klik **Buka Netflix Sekarang** untuk auto-login otomatis tanpa ketik email/password
3. **Login PC/Laptop:** Klik **Kirim via WA** → buka link di Chrome/Edge browser
4. **Login Smart TV:** Pilih **Smart TV** → masukkan 8 digit kode dari layar TV
5. **Password salah:** Sistem auto-clean menghapus akun expired otomatis, pilih akun lain
6. **Tambah profil:** Boleh tambah profil baru jika ada slot kosong (max 5), **DILARANG** hapus profil orang lain
7. **Ubah bahasa:** Kelola Profil → Bahasa → pilih **Bahasa Indonesia**
8. **Limit layar penuh:** Logout lalu pilih akun lain dari **Daftar Akun**
9. **Perpanjang:** Tukar kode voucher di menu **Profil** → **Tukar Voucher**, atau hubungi admin
10. **Jumlah layar:** Tergantung paket akun (1-4 layar)

ATURAN PENTING & PEMBATASAN TOPIK (STRIKTIF):
- **INFORMASI JUMLAH AKUN (WAJIB PERSIS & AKURAT):**
  Jika user bertanya berapa jumlah akun di aplikasi/database, sebutkan angka PERSIS sesuai data di atas (Total akun & Akun Aktif LIVE). DILARANG KERAS mengarang, menebak, atau menyebutkan angka lain!
- **PEMBATASAN UTAMA:** HANYA jawab pertanyaan yang berkaitan langsung dengan aplikasi Netflix Home, akun Netflix, kendala login/streaming, profil, voucher, atau fitur aplikasi ini.
- **TOLAK PERTANYAAN OUT OF TOPIC:** JIKA pengguna bertanya hal di luar aplikasi Netflix Home (seperti pengetahuan umum, matematika, koding, cerita, politik, cuaca, aplikasi lain, dll), JANGAN dijawab!
- **RESPONS PENOLAKAN OUT OF TOPIC:** Jika pertanyaan tidak relevan dengan Netflix Home, jawab dengan tegas dan ramah:
  "⚠️ **Maaf Kak!**\n\nSaya adalah asisten khusus **Netflix Home** dan hanya dapat membantu pertanyaan seputar penggunaan aplikasi ini & kendala akun Netflix.\n\nSilakan tanyakan hal seputar aplikasi Netflix Home ya! 😊"
- JANGAN pernah memberikan data sensitif seperti email akun, password, cookie, atau data login akun Netflix
- JANGAN menyebutkan detail teknis internal sistem (Supabase, API keys, dll)
- Jika user bertanya hal yang tidak bisa dijawab atau butuh bantuan manual admin, sarankan: "Klik tombol **Alihkan ke Admin** di bawah untuk bantuan langsung"
- Jika user menanyakan harga/paket, arahkan untuk menghubungi admin CS
- Selalu berikan solusi yang actionable dengan menyebutkan **nama menu/tombol** yang perlu diklik
- Jawaban HARUS terstruktur dengan format di atas (bold, numbered list, emoji)
''';
  }

  /// Kirim pesan ke AI dan dapatkan respons
  static Future<String?> sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final systemContext = await _buildSystemContext();

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemContext},
      ];

      // Tambahkan history percakapan (maks 20 pesan terakhir)
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        final recentHistory = conversationHistory.length > 20
            ? conversationHistory.sublist(conversationHistory.length - 20)
            : conversationHistory;
        messages.addAll(recentHistory);
      }

      // Tambahkan pesan user saat ini
      messages.add({'role': 'user', 'content': userMessage});

      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'ai_chat',
        body: {
          'messages': messages,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.status == 200) {
        final data = response.data;
        final content =
            data['choices']?[0]?['message']?['content']?.toString();
        return content?.trim();
      } else {
        debugPrint('AI API error: ${response.status} - ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('AI chat error: $e');
      return null;
    }
  }

  /// Pesan sambutan otomatis
  static String getWelcomeMessage(String username) {
    return '👋 **Halo $username!**\n\n'
        'Selamat datang di **Live CS Netflix Home**. '
        'Saya adalah asisten AI yang siap membantu Anda.\n\n'
        '📋 **Yang bisa saya bantu:**\n'
        '• Cara menggunakan aplikasi\n'
        '• Login di **HP**, **PC**, atau **Smart TV**\n'
        '• Kendala akun Netflix\n'
        '• Perpanjangan & **voucher**\n\n'
        '💡 Ketik pertanyaan Anda, atau tekan tombol **Alihkan ke Admin** untuk bicara dengan admin manusia 😊';
  }

  /// Fallback jawaban umum jika AI server down
  static String? getFallbackAnswer(String question) {
    final q = question.toLowerCase();

    final fallbacks = <String, String>{
      'login|masuk|cara pakai|cara menggunakan':
          '📱 **Cara Menggunakan Netflix Home**\n\n'
          '1. Buka tab **Daftar Akun** di menu bawah\n'
          '2. Pilih akun berstatus **Aktif** (hijau)\n'
          '3. Tekan tombol **Gunakan Akun Ini**\n'
          '4. Pilih perangkat (HP/Laptop/Smart TV)\n\n'
          '✅ Untuk bantuan lebih lanjut, klik **Alihkan ke Admin**.',

      'password|salah|error|gagal':
          '🔑 **Password Salah / Error Login**\n\n'
          '• Sistem **auto-clean** menghapus akun expired otomatis\n'
          '• Tutup pop-up dan pilih **akun lain** di **Daftar Akun**\n'
          '• Pastikan akun berstatus **Aktif** (hijau)\n\n'
          '⚠️ Jika masalah berlanjut, klik **Alihkan ke Admin**.',

      'tv|smart tv|kode|televisi':
          '📺 **Login di Smart TV**\n\n'
          '1. Buka Netflix di TV → catat **kode 8 digit**\n'
          '2. Di app Netflix Home, pilih akun → tekan **Gunakan Akun Ini**\n'
          '3. Pilih perangkat **Smart TV**\n'
          '4. Masukkan kode 8 digit → tekan **Aktifkan**\n\n'
          '✅ TV akan otomatis login ke Netflix!',

      'laptop|pc|komputer|browser':
          '💻 **Login di Laptop/PC**\n\n'
          '1. Pilih akun di tab **Daftar Akun**\n'
          '2. Tekan **Gunakan Akun Ini** → pilih **Laptop/PC**\n'
          '3. Klik **Kirim via WA**\n'
          '4. Buka link di **Chrome** atau **Edge**\n\n'
          '✅ Otomatis login tanpa ketik password!',

      'hp|handphone|android|iphone|ios':
          '📲 **Login di HP**\n\n'
          '1. Pastikan app **Netflix resmi** sudah terinstall\n'
          '2. Pilih akun → tekan **Gunakan Akun Ini**\n'
          '3. Pilih perangkat **HP/Android/iPhone**\n'
          '4. Tekan **Buka Netflix Sekarang**\n\n'
          '✅ Auto-login tanpa ketik email/password!',

      'perpanjang|expired|habis|kedaluwarsa|masa aktif':
          '⏰ **Perpanjang Masa Aktif**\n\n'
          '1. Buka tab **Profil** di menu bawah\n'
          '2. Tekan tombol **Tukar Voucher**\n'
          '3. Masukkan kode voucher yang Anda miliki\n\n'
          '💡 Belum punya voucher? Klik **Alihkan ke Admin** untuk pembelian.',

      'profil|profile|ubah|ganti|bahasa':
          '👤 **Pengaturan Profil Netflix**\n\n'
          '• ✅ Boleh **tambah profil baru** jika ada slot kosong (max 5)\n'
          '• ❌ **DILARANG** hapus profil orang lain\n'
          '• 🌐 Ubah bahasa: **Kelola Profil** → **Bahasa** → Indonesia\n'
          '• ❌ **DILARANG** ubah email/password akun',

      'limit|layar|streaming|nonton|penuh|banyak':
          '📺 **Limit Layar Penuh**\n\n'
          'Jika muncul "Terlalu banyak orang menonton":\n\n'
          '1. **Logout** dari akun Netflix tersebut\n'
          '2. Buka app **Netflix Home**\n'
          '3. Pilih **akun lain** di tab **Daftar Akun**\n\n'
          '✅ Stok akun kami banyak dan selalu siap!',

      'voucher|kode|redeem|tukar':
          '🎟️ **Cara Tukar Voucher**\n\n'
          '1. Buka tab **Profil** di menu bawah\n'
          '2. Tekan tombol **Tukar Voucher**\n'
          '3. Masukkan **kode voucher** Anda\n'
          '4. Masa aktif diperpanjang **otomatis**!\n\n'
          '💡 Untuk beli voucher, klik **Alihkan ke Admin**.',

      'harga|paket|bayar|beli|murah':
          '💰 **Info Harga & Paket**\n\n'
          'Untuk informasi **harga** dan **pembelian paket**, silakan hubungi admin CS kami langsung.\n\n'
          '👉 Klik tombol **Alihkan ke Admin** di bawah untuk terhubung.',
    };

    for (final entry in fallbacks.entries) {
      final keywords = entry.key.split('|');
      for (final keyword in keywords) {
        if (q.contains(keyword)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Jawaban default jika tidak ada fallback yang cocok
  static String getDefaultFallback() {
    return '🤖 **Maaf, saya sedang tidak bisa memproses pertanyaan Anda.**\n\n'
        '📋 **Yang bisa saya bantu:**\n'
        '• Cara login di **HP**, **PC**, atau **Smart TV**\n'
        '• Kendala akun (password salah, limit layar)\n'
        '• Perpanjangan masa aktif & **voucher**\n'
        '• Pengaturan profil Netflix\n\n'
        '👉 Atau klik **Alihkan ke Admin** untuk bantuan langsung dari tim CS kami.';
  }
}
