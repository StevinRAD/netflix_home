import 'package:flutter/material.dart';

class LanguageNotifier {
  // true = Indonesian, false = English
  static final ValueNotifier<bool> isIndonesian = ValueNotifier<bool>(true);

  static const Map<String, Map<String, String>> _dict = {
    // === General ===
    'close': {'id': 'Tutup', 'en': 'Close'},
    'cancel': {'id': 'Batal', 'en': 'Cancel'},
    'save': {'id': 'Simpan', 'en': 'Save'},

    // === Login Screen ===
    'fill_fields': {'id': 'Mohon isi Username / Email dan Password', 'en': 'Please enter Username / Email and Password'},
    'login_failed': {'id': 'Login Gagal: Periksa kembali email & password Anda.', 'en': 'Login Failed: Please check your email & password.'},
    'register_failed': {'id': 'Gagal Mendaftar. Silakan coba lagi.', 'en': 'Registration Failed. Please try again.'},
    'help_center': {'id': 'Pusat Bantuan Login', 'en': 'Login Help Center'},
    'customer_service': {'id': '💬 Layanan Pelanggan (Admin)', 'en': '💬 Customer Service (Admin)'},
    'help_desc': {'id': 'Jika Anda lupa kata sandi, akun terkendala, atau ingin melakukan perpanjangan masa aktif, silakan hubungi Customer Service kami.', 'en': 'If you forgot your password, have account issues, or want to extend your active period, please contact our Customer Service.'},
    'contact_admin': {'id': 'Hubungi Admin via WhatsApp', 'en': 'Contact Admin via WhatsApp'},
    'sign_in': {'id': 'Sign In', 'en': 'Sign In'},
    'sign_up': {'id': 'Sign Up', 'en': 'Sign Up'},
    'login_desc': {'id': 'Masuk ke akun Netflix Home Anda', 'en': 'Sign in to your Netflix Home account'},
    'register_desc': {'id': 'Daftar Akun Baru', 'en': 'Create a New Account'},
    'username_label': {'id': 'Nama Pengguna (Untuk Dashboard)', 'en': 'Username (For Dashboard)'},
    'username_hint': {'id': 'Contoh: Budi Store', 'en': 'Example: Budi Store'},
    'email': {'id': 'Email', 'en': 'Email'},
    'email_hint': {'id': 'admin@netflix.com', 'en': 'admin@netflix.com'},
    'password': {'id': 'Password', 'en': 'Password'},
    'remember_me': {'id': 'Ingat Saya', 'en': 'Remember Me'},
    'need_help': {'id': 'Butuh Bantuan?', 'en': 'Need Help?'},
    'btn_signin': {'id': 'SIGN IN TO DASHBOARD', 'en': 'SIGN IN TO DASHBOARD'},
    'btn_register': {'id': 'DAFTAR SEKARANG', 'en': 'REGISTER NOW'},
    'toggle_register': {'id': 'Belum punya akun? Daftar Akun', 'en': 'Don\'t have an account? Sign Up'},
    'toggle_login': {'id': 'Sudah punya akun? Masuk', 'en': 'Already have an account? Sign In'},
    'login_guide_title': {'id': '📌 Panduan Login:', 'en': '📌 Login Guide:'},
    'login_guide_1': {'id': '• Masukkan email/username & password yang didapatkan dari Admin.', 'en': '• Enter the email/username & password provided by Admin.'},
    'login_guide_2': {'id': '• Pastikan koneksi internet Anda stabil.', 'en': '• Ensure your internet connection is stable.'},
    'login_guide_3': {'id': '• Tekan "SIGN IN TO DASHBOARD" untuk melanjutkan.', 'en': '• Press "SIGN IN TO DASHBOARD" to continue.'},

    // === Dashboard Screen ===
    'home': {'id': 'Beranda', 'en': 'Home'},
    'active_period': {'id': 'Sisa Masa Aktif', 'en': 'Remaining Active Period'},
    'days': {'id': 'Hari', 'en': 'Days'},
    'extend': {'id': 'Perpanjang', 'en': 'Extend'},
    'expired': {'id': 'Masa Aktif Habis!', 'en': 'Active Period Expired!'},
    'total_availability': {'id': 'Total Ketersediaan Akun', 'en': 'Total Account Availability'},
    'total_accounts': {'id': 'Total Akun', 'en': 'Total Accounts'},
    'live_accounts': {'id': 'Akun Live', 'en': 'Live Accounts'},
    'package_availability': {'id': 'Ketersediaan Paket', 'en': 'Package Availability'},
    'available': {'id': 'Tersedia', 'en': 'Available'},
    'open_account_list': {'id': 'Buka Daftar Akun Netflix', 'en': 'Open Netflix Account List'},

    // === Accounts Screen ===
    'account_list': {'id': 'Daftar Akun Netflix', 'en': 'Netflix Account List'},
    'filter_package': {'id': 'Filter Paket:', 'en': 'Filter Package:'},
    'all_packages': {'id': 'Semua Paket', 'en': 'All Packages'},
    'no_accounts': {'id': 'Tidak ada akun yang sesuai kriteria.', 'en': 'No accounts match the criteria.'},
    'loading_accounts': {'id': 'Sedang memuat data akun...', 'en': 'Loading account data...'},
    'account_details': {'id': 'Detail Akun', 'en': 'Account Details'},
    'country': {'id': 'Negara', 'en': 'Country'},
    'package': {'id': 'Paket', 'en': 'Package'},
    'quality': {'id': 'Kualitas', 'en': 'Quality'},
    'max_streams': {'id': 'Limit Streaming', 'en': 'Stream Limit'},
    'payment_status': {'id': 'Status Pembayaran', 'en': 'Payment Status'},
    'member_since': {'id': 'Mulai Berlangganan', 'en': 'Member Since'},
    'next_billing': {'id': 'Tagihan Berikutnya', 'en': 'Next Billing'},
    'get_account_link': {'id': 'Ambil Akun & Dapatkan Link', 'en': 'Get Account & Link'},
    'choose_login_method': {'id': 'Pilih Metode Masuk', 'en': 'Choose Login Method'},
    'copy_raw_link': {'id': 'Salin Link Bawaan', 'en': 'Copy Raw Link'},
    'copy_raw_link_desc': {'id': 'Salin format teks berisi akun & link', 'en': 'Copy text format containing account & links'},
    'copy': {'id': 'Salin', 'en': 'Copy'},
    'laptop_pc': {'id': 'Laptop / PC', 'en': 'Laptop / PC'},
    'send_pc_link': {'id': 'Kirim link khusus PC ke WhatsApp', 'en': 'Send special PC link to WhatsApp'},
    'send_via_wa': {'id': 'Kirim via WA', 'en': 'Send via WA'},
    'mobile_mode': {'id': 'Mode Mobile (Android/iOS)', 'en': 'Mobile Mode (Android/iOS)'},
    'mobile_mode_desc': {'id': 'Login langsung di aplikasi HP Anda', 'en': 'Login directly in your mobile app'},
    'open_app': {'id': 'Buka Aplikasi', 'en': 'Open App'},
    'tv_link': {'id': 'Smart TV (Link TV9)', 'en': 'Smart TV (TV9 Link)'},
    'tv_link_desc': {'id': 'Masukkan 8 digit kode yang muncul di layar TV', 'en': 'Enter the 8 digit code shown on your TV screen'},
    'open_tv_link': {'id': 'Buka Link TV9', 'en': 'Open TV9 Link'},
    'qr_code': {'id': 'QR Code Login (Scan HP)', 'en': 'QR Code Login (Phone Scan)'},
    'qr_code_desc': {'id': 'Arahkan kamera HP lain ke layar untuk scan', 'en': 'Point another phone camera to screen to scan'},
    'show_qr': {'id': 'Tampilkan QR', 'en': 'Show QR'},
    'scan_to_login': {'id': 'Scan untuk otomatis login', 'en': 'Scan to auto-login'},

    // === Profile Screen ===
    'profile_settings': {'id': 'Profil & Pengaturan', 'en': 'Profile & Settings'},
    'joined_since': {'id': 'Bergabung sejak', 'en': 'Joined since'},
    'help_center_title': {'id': 'PUSAT BANTUAN & PANDUAN', 'en': 'HELP CENTER & GUIDES'},
    'guide_login': {'id': 'Panduan Login Awal', 'en': 'Initial Login Guide'},
    'guide_login_desc': {'id': 'Buka kembali panduan pemakaian interaktif pertama kali', 'en': 'Reopen the interactive initial usage guide'},
    'guide_dashboard': {'id': 'Panduan Fitur Dashboard', 'en': 'Dashboard Features Guide'},
    'guide_dashboard_desc': {'id': 'Penjelasan lengkap fungsi tiap tombol di Beranda', 'en': 'Complete explanation of each button function on Home'},
    'guide_device': {'id': 'Cara Login Perangkat (PC, HP, TV)', 'en': 'Device Login Guide (PC, Phone, TV)'},
    'guide_device_desc': {'id': 'Petunjuk lengkap cara membuka link di berbagai device', 'en': 'Complete guide on opening links on various devices'},
    'cs_whatsapp': {'id': 'Customer Service WhatsApp (24/7)', 'en': 'Customer Service WhatsApp (24/7)'},
    'cs_whatsapp_desc': {'id': 'Hubungi admin jika ada kendala akun atau login', 'en': 'Contact admin for account or login issues'},
    'settings_security': {'id': 'PENGATURAN & KEAMANAN', 'en': 'SETTINGS & SECURITY'},
    'dark_mode': {'id': 'Mode Gelap (Dark Theme)', 'en': 'Dark Mode'},
    'dark_active': {'id': 'Tema Gelap Aktif', 'en': 'Dark Theme Active'},
    'light_active': {'id': 'Tema Terang Aktif', 'en': 'Light Theme Active'},
    'change_language': {'id': 'Ganti Bahasa', 'en': 'Change Language'},
    'lang_indonesian': {'id': 'Bahasa Indonesia', 'en': 'Indonesian'},
    'lang_english': {'id': 'English', 'en': 'English'},
    'about_app': {'id': 'Tentang Aplikasi', 'en': 'About App'},
    'change_password': {'id': 'Ganti Kata Sandi', 'en': 'Change Password'},
    'logout': {'id': 'Keluar Akun', 'en': 'Logout'},
    'confirm_logout': {'id': 'Konfirmasi Keluar', 'en': 'Confirm Logout'},
    'confirm_logout_desc': {'id': 'Apakah Anda yakin ingin keluar dari akun ini?', 'en': 'Are you sure you want to log out from this account?'},
    'guide_device_title': {'id': 'Panduan Login Perangkat', 'en': 'Device Login Guide'},
    'guide_pc_title': {'id': '💻 Komputer / Laptop', 'en': '💻 Computer / Laptop'},
    'guide_pc_desc': {'id': 'Tekan "Kirim via WA" pada opsi Laptop/PC untuk mengirim link khusus PC ke perangkat komputer Anda, lalu klik link tersebut di sana.', 'en': 'Press "Send via WA" on the Laptop/PC option to send the special PC link to your computer, then click the link there.'},
    'guide_phone_title': {'id': '📱 HP Android & iPhone', 'en': '📱 Android & iPhone'},
    'guide_phone_desc': {'id': 'Tekan tombol "Buka" opsi HP atau scan "QR Code" dengan kamera HP. Lalu tekan "Buka Aplikasi" untuk otomatis login di aplikasi Netflix.', 'en': 'Press the "Open" button on Mobile option or scan "QR Code". Then press "Open App" to auto-login to the Netflix app.'},
    'guide_tv_title': {'id': '📺 Smart TV (Link TV9)', 'en': '📺 Smart TV (TV9 Link)'},
    'guide_tv_desc': {'id': 'Buka link TV9 di HP/Laptop Anda. Masukkan kode angka 8 digit yang muncul di layar Smart TV Anda untuk menghubungkan.', 'en': 'Open the TV9 link on your Phone/Laptop. Enter the 8-digit code shown on your Smart TV screen to connect.'},
    'current_password': {'id': 'Password Saat Ini', 'en': 'Current Password'},
    'new_password': {'id': 'Password Baru', 'en': 'New Password'},
    'confirm_new_password': {'id': 'Konfirmasi Password Baru', 'en': 'Confirm New Password'},
    'password_mismatch': {'id': 'Password baru tidak cocok atau masih kosong!', 'en': 'New passwords do not match or are empty!'},
    'password_updated': {'id': '✅ Password berhasil diperbarui!', 'en': '✅ Password successfully updated!'},

    // === About Screen ===
    'created_by': {'id': 'Dibuat Oleh', 'en': 'Created By'},
    'app_version': {'id': 'Versi Aplikasi', 'en': 'App Version'},
    'app_features': {'id': 'Fitur Unggulan', 'en': 'Key Features'},
    'feat_1': {'id': '✅ Manajemen Akun Netflix Otomatis', 'en': '✅ Automatic Netflix Account Management'},
    'feat_2': {'id': '✅ Generate Link Tanpa Password', 'en': '✅ Generate Link Without Password'},
    'feat_3': {'id': '✅ Sinkronisasi Database Real-time', 'en': '✅ Real-time Database Synchronization'},
    'feat_4': {'id': '✅ Validasi Akun Cerdas', 'en': '✅ Smart Account Validation'},
    
    // === Onboarding ===
    'onboarding_title_1': {'id': 'Kenali Dashboard Anda', 'en': 'Know Your Dashboard'},
    'onboarding_desc_1': {'id': 'Di sini Anda bisa memantau sisa masa aktif langganan Anda dan menghubungi admin jika sudah hampir habis.', 'en': 'Here you can monitor your remaining active subscription and contact admin when it is about to expire.'},
    'onboarding_title_2': {'id': 'Pantau Ketersediaan', 'en': 'Monitor Availability'},
    'onboarding_desc_2': {'id': 'Lihat secara langsung berapa total akun Netflix yang tersedia dan siap digunakan saat ini.', 'en': 'See exactly how many Netflix accounts are available and ready to use right now.'},
    'onboarding_title_3': {'id': 'Kategori Paket Lengkap', 'en': 'Complete Package Categories'},
    'onboarding_desc_3': {'id': 'Kami menyediakan berbagai varian akun mulai dari Basic hingga Premium sesuai kebutuhan Anda.', 'en': 'We provide various account variants from Basic to Premium according to your needs.'},
    'onboarding_title_4': {'id': 'Mulai Nonton!', 'en': 'Start Watching!'},
    'onboarding_desc_4': {'id': 'Tekan tombol ini untuk masuk ke halaman daftar akun dan mengambil link Netflix.', 'en': 'Press this button to enter the account list page and get the Netflix link.'},

    // === Dashboard Guide ===
    'guide_features': {'id': 'Kenali Fitur Netflix Home', 'en': 'Know Netflix Home Features'},
    'guide_features_desc': {'id': 'Panduan visual fungsi-fungsi yang ada di halaman utama (Beranda) aplikasi Netflix Home.', 'en': 'Visual guide of functions on the Netflix Home dashboard.'},
    'guide_1_title': {'id': '1. Banner Info Langganan', 'en': '1. Subscription Info Banner'},
    'guide_1_desc': {'id': 'Menampilkan sisa masa aktif akun Anda. Jika habis, Anda tidak bisa mengambil akun baru. Terdapat tombol WhatsApp di sana untuk perpanjang.', 'en': 'Displays your remaining active period. If expired, you cannot get new accounts. There is a WhatsApp button to extend.'},
    'guide_2_title': {'id': '2. Statistik Total Akun', 'en': '2. Total Accounts Stats'},
    'guide_2_desc': {'id': 'Menunjukkan jumlah total akun yang ada di sistem Netflix Home dan berapa jumlah akun yang sedang berstatus "Live" (aktif & siap pakai).', 'en': 'Shows the total number of accounts in the system and how many are currently "Live" (active & ready to use).'},
    'guide_3_title': {'id': '3. Ketersediaan Paket', 'en': '3. Package Availability'},
    'guide_3_desc': {'id': 'Menampilkan jumlah akun spesifik berdasarkan masing-masing jenis paket langganan Netflix yang tersedia.', 'en': 'Displays the specific number of accounts based on each available Netflix subscription package type.'},
    'guide_4_title': {'id': '4. Tombol Mulai Nonton', 'en': '4. Start Watching Button'},
    'guide_4_desc': {'id': 'Tombol pintasan (shortcut) merah besar di bagian bawah. Tekan tombol ini untuk langsung pindah ke halaman Daftar Akun tempat Anda mengambil link Netflix.', 'en': 'A large red shortcut button at the bottom. Press this to jump directly to the Account List page where you can get Netflix links.'},
    
    // Default text format (if not mapped)
    'wa_pc_message': {
      'id': 'Link netflix ini pakai untuk pc dan tekan di pc atau laptop', 
      'en': 'This Netflix link is for PC, please click it on your PC or Laptop'
    }
  };

  static String tr(String key) {
    final lang = isIndonesian.value ? 'id' : 'en';
    return _dict[key]?[lang] ?? key;
  }
}
