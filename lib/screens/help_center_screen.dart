import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/language_notifier.dart';
import '../utils/user_notifier.dart';
import '../widgets/video_tutorial_modal.dart';

class HelpCenterScreen extends StatefulWidget {
  final String? username;
  const HelpCenterScreen({super.key, this.username});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = [
    'Semua',
    'Panduan Pakai',
    'Login HP/PC/TV',
    'Kendala Akun',
    'Paket & Voucher',
  ];

  late final List<Map<String, dynamic>> _faqItems = [
    {
      'category': 'Panduan Pakai',
      'icon': Icons.play_circle_outline_rounded,
      'q_id': 'Bagaimana cara menggunakan aplikasi Netflix Home ini?',
      'q_en': 'How do I use this Netflix Home app?',
      'a_id':
          '1. Masuk ke tab "Daftar Akun" di bagian bawah layar.\n'
          '2. Pilih salah satu akun Netflix yang berstatus "Ready / Aktif".\n'
          '3. Klik tombol merah "Gunakan Akun Ini".\n'
          '4. Pilih metode login sesuai perangkat Anda:\n'
          '   • HP: Klik "Buka Netflix Sekarang" untuk auto-login otomatis.\n'
          '   • Laptop/PC: Klik "Kirim via WA" untuk membuka link web di browser komputer.\n'
          '   • Smart TV: Klik "Smart TV" lalu masukkan 8 digit kode dari layar TV Anda.\n'
          '5. Selesai! Nikmati tayangan Netflix favorit Anda.',
      'a_en':
          '1. Go to the "Account List" tab at the bottom.\n'
          '2. Choose an active Netflix account.\n'
          '3. Click "Use This Account".\n'
          '4. Select your device (Phone, PC, or Smart TV).\n'
          '5. Enjoy your favorite Netflix shows!',
    },
    {
      'category': 'Login HP/PC/TV',
      'icon': Icons.smartphone_rounded,
      'q_id': 'Bagaimana cara login otomatis di HP Android atau iPhone?',
      'q_en': 'How to auto-login on Android or iPhone?',
      'a_id':
          'Pastikan aplikasi Netflix resmi sudah terinstall di HP Anda. '
          'Di dalam aplikasi Netflix Home, klik akun yang dipilih lalu tekan "Gunakan Akun Ini". '
          'Pilih tombol putih "Buka Netflix Sekarang". Sistem akan membuat sesi login instan dan langsung membuka aplikasi Netflix tanpa perlu mengetik email & password.',
      'a_en':
          'Make sure the official Netflix app is installed on your phone. '
          'Click "Use This Account" and select "Open Netflix Now". The system will auto-login without typing email & password.',
    },
    {
      'category': 'Login HP/PC/TV',
      'icon': Icons.laptop_mac_rounded,
      'q_id': 'Bagaimana cara login di Laptop atau Komputer (PC)?',
      'q_en': 'How to login on a Laptop or PC?',
      'a_id':
          'Pilih akun yang Anda inginkan, lalu klik opsi "Laptop / PC (Kirim via WA)". '
          'Link login khusus akan dikirimkan ke WhatsApp Anda. Buka link tersebut di browser Google Chrome atau Microsoft Edge pada PC/Laptop Anda untuk langsung masuk ke Netflix.',
      'a_en':
          'Select the account and click "Laptop / PC (Send via WA)". '
          'Open the link sent to your WhatsApp on Google Chrome or Edge on your PC.',
    },
    {
      'category': 'Login HP/PC/TV',
      'icon': Icons.tv_rounded,
      'q_id': 'Bagaimana cara menghubungkan akun ke Smart TV / Android TV?',
      'q_en': 'How to connect the account to Smart TV?',
      'a_id':
          '1. Buka aplikasi Netflix di Smart TV Anda hingga muncul pilihan login dengan kode (8 digit angka/huruf).\n'
          '2. Di aplikasi Netflix Home, klik "Gunakan Akun Ini" lalu pilih opsi "Smart TV".\n'
          '3. Halaman aktivasi TV akan terbuka otomatis. Masukkan 8 digit kode yang muncul di layar Smart TV Anda, lalu tekan Lanjutkan/Aktifkan.\n'
          '4. Layar TV Anda akan langsung masuk ke beranda Netflix secara otomatis.',
      'a_en':
          '1. Open Netflix on your TV until the 8-digit activation code appears.\n'
          '2. In Netflix Home, select "Smart TV".\n'
          '3. Enter the 8-digit code and activate. Your TV will automatically log in.',
    },
    {
      'category': 'Kendala Akun',
      'icon': Icons.error_outline_rounded,
      'q_id': 'Apa yang harus dilakukan jika muncul pesan "Password Salah" atau akun tidak bisa dibuka?',
      'q_en': 'What should I do if "Incorrect Password" appears or the account cannot be opened?',
      'a_id':
          'Sistem Netflix Home memiliki fitur auto-clean. Saat akun dicoba dan terdeteksi kedaluwarsa oleh sistem, akun tersebut akan otomatis dihapus dan digantikan dengan akun baru yang segar. '
          'Silakan tutup pop-up dan coba pilih akun Netflix lainnya di daftar akun.',
      'a_en':
          'Netflix Home features auto-clean. If an account is expired, it is automatically removed. Please choose another active account from the list.',
    },
    {
      'category': 'Kendala Akun',
      'icon': Icons.person_add_alt_1_rounded,
      'q_id': 'Bolehkah saya menambahkan profil baru di akun Netflix?',
      'q_en': 'Can I add a new profile to the Netflix account?',
      'a_id':
          'Boleh! Anda diperbolehkan menambahkan profil baru jika masih ada slot profil yang kosong (maksimal 5 profil per akun). '
          'Hal yang SANGAT DILARANG adalah MENGHAPUS profil milik pengguna lain yang sudah ada. '
          'Selain itu, dilarang keras mengubah email atau password akun Netflix demi kenyamanan bersama.',
      'a_en':
          'Yes! You may create a new profile if an empty slot exists (max 5 profiles). However, deleting other users\' profiles is STRICTLY PROHIBITED. Do not change email or password.',
    },
    {
      'category': 'Kendala Akun',
      'icon': Icons.translate_rounded,
      'q_id': 'Bagaimana jika bahasa tampilan atau audio di Netflix bukan Bahasa Indonesia?',
      'q_en': 'What if the Netflix language is not in Indonesian?',
      'a_id':
          'Tidak masalah sama sekali! Akun berasal dari berbagai region global resmi. '
          'Anda bebas dan diperbolehkan mengubah bahasa tampilan ataupun subtitle ke Bahasa Indonesia melalui menu Kelola Profil (Manage Profiles) -> Bahasa (Language) di aplikasi Netflix.',
      'a_en':
          'No problem at all! You are free to change the display and subtitle language back to Bahasa Indonesia via Manage Profiles -> Language in the Netflix app.',
    },
    {
      'category': 'Kendala Akun',
      'icon': Icons.tv_off_rounded,
      'q_id': 'Bagaimana jika muncul pesan "Terlalu banyak orang yang menonton saat ini" (Limit Layar)?',
      'q_en': 'What if "Too many people watching right now" appears (Screen Limit)?',
      'a_id':
          'Jangan khawatir! Jika akun yang Anda pakai sedang penuh atau terkena limit menonton, cukup keluar (logout) dari akun Netflix tersebut. '
          'Kemudian buka kembali aplikasi Netflix Home dan pilih akun lain di daftar akun. Stok akun kami sangat banyak dan selalu siap digunakan kapan saja.',
      'a_en':
          'Don\'t worry! If an account reaches screen capacity, simply log out and pick another account in Netflix Home (many accounts available).',
    },
    {
      'category': 'Paket & Voucher',
      'icon': Icons.card_membership_rounded,
      'q_id': 'Masa aktif langganan saya habis, bagaimana cara memperpanjangnya?',
      'q_en': 'My subscription expired, how do I renew it?',
      'a_id':
          'Anda dapat menukar kode voucher di menu Profil -> "Tukar Voucher", atau langsung hubungi Customer Service kami melalui tombol WhatsApp di bawah untuk pembelian paket perpanjangan masa aktif.',
      'a_en':
          'You can redeem a voucher in Profile -> "Redeem Voucher", or contact our Customer Service via WhatsApp below to purchase an extension.',
    },
    {
      'category': 'Paket & Voucher',
      'icon': Icons.devices_other_rounded,
      'q_id': 'Berapa jumlah maksimal perangkat yang bisa menonton bersamaan?',
      'q_en': 'How many screens can watch simultaneously?',
      'a_id':
          'Jumlah layar streaming tergantung paket akun yang Anda gunakan (tertera pada kartu akun: 1 Layar, 2 Layar, hingga 4 Layar Ultra HD 4K). '
          'Gunakan sesuai kapasitas layar agar tidak mengganggu pengguna lainnya.',
      'a_en':
          'The maximum screens depend on the plan (shown on the account card: 1 Screen up to 4 Screens Ultra HD 4K).',
    },
  ];

  Future<void> _contactAdminWhatsApp() async {
    final currentUsername = widget.username ??
        (UserNotifier.username.value.isNotEmpty
            ? UserNotifier.username.value
            : 'Pengguna');
    final queryText = _searchController.text.trim();
    final customContext = queryText.isNotEmpty
        ? 'terkait: "$queryText"'
        : 'terkait kendala akun/aplikasi';

    final text =
        'Halo CS Netflix Home, saya ($currentUsername). Saya sudah membaca Pusat Bantuan di aplikasi, namun masih butuh bantuan $customContext. Mohon dibantu ya Admin, terima kasih.';

    final waAppUrl = Uri.parse(
        'whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
    final waWebUrl = Uri.parse(
        'https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(waAppUrl)) {
        await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendQuestionToWhatsApp(String questionText) async {
    final currentUsername = widget.username ??
        (UserNotifier.username.value.isNotEmpty
            ? UserNotifier.username.value
            : 'Pengguna');

    final text =
        'Halo CS Netflix Home, saya ($currentUsername).\n'
        'Saya mau bertanya mengenai:\n\n'
        '❓ "$questionText"\n\n'
        'Mohon dibantu ya Admin CS, terima kasih!';

    final waAppUrl = Uri.parse(
        'whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
    final waWebUrl = Uri.parse(
        'https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(waAppUrl)) {
        await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildWaQuestionChip({
    required IconData icon,
    required String label,
    required String question,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendQuestionToWhatsApp(question),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2922) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF25D366)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : Colors.grey[850],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF25D366)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIndo = LanguageNotifier.isIndonesian.value;

    final filteredFaqs = _faqItems.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          faq['category'] == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final qId = faq['q_id'].toString().toLowerCase();
      final qEn = faq['q_en'].toString().toLowerCase();
      final aId = faq['a_id'].toString().toLowerCase();
      final aEn = faq['a_en'].toString().toLowerCase();

      return qId.contains(query) ||
          qEn.contains(query) ||
          aId.contains(query) ||
          aEn.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isIndo ? 'Pusat Bantuan & CS' : 'Help Center & CS',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'WhatsApp CS',
            icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            onPressed: _contactAdminWhatsApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Header & Search Bar ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFF990000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.support_agent_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIndo
                                  ? 'Halo, ada yang bisa kami bantu?'
                                  : 'Hello, how can we help you?',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isIndo
                                  ? 'Cari solusi atau panduan pemakaian aplikasi'
                                  : 'Find solutions or app usage guides',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: isIndo
                            ? 'Ketik kata kunci kendala / pertanyaan...'
                            : 'Type keywords or questions...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFFE50914), size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ─── Quick WhatsApp Question Cards ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF25D366).withValues(alpha: isDark ? 0.15 : 0.1),
                      const Color(0xFF128C7E).withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndo
                                    ? 'Pertanyaan Cepat ke Admin CS'
                                    : 'Quick Questions to Admin CS',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                isIndo
                                    ? 'Klik topik di bawah untuk bertanya langsung via WhatsApp'
                                    : 'Click a topic below to ask directly on WhatsApp',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWaQuestionChip(
                          icon: Icons.autorenew_rounded,
                          label: isIndo ? 'Perpanjang Langganan' : 'Renew Subscription',
                          question: isIndo
                              ? 'Bagaimana cara memperpanjang masa aktif langganan akun Netflix saya?'
                              : 'How do I renew my Netflix subscription?',
                          isDark: isDark,
                        ),
                        _buildWaQuestionChip(
                          icon: Icons.confirmation_number_rounded,
                          label: isIndo ? 'Klaim / Beli Voucher' : 'Claim Voucher',
                          question: isIndo
                              ? 'Bagaimana cara membeli & mengklaim kode voucher perpanjangan?'
                              : 'How do I buy & redeem a renewal voucher code?',
                          isDark: isDark,
                        ),
                        _buildWaQuestionChip(
                          icon: Icons.devices_rounded,
                          label: isIndo ? 'Cara Login Perangkat Saya' : 'How to Login My Device',
                          question: isIndo
                              ? 'Bagaimana cara login Netflix sesuai dengan perangkat yang ingin saya gunakan (HP, Laptop/PC, atau Smart TV)?'
                              : 'How do I log in to Netflix on the device I want to use (Phone, Laptop/PC, or Smart TV)?',
                          isDark: isDark,
                        ),
                        _buildWaQuestionChip(
                          icon: Icons.play_circle_outline_rounded,
                          label: isIndo ? 'Cara Memakai Aplikasi' : 'How to Use App',
                          question: isIndo
                              ? 'Bagaimana cara lengkap menggunakan dan memakai aplikasi Netflix Home ini?'
                              : 'How do I use and navigate this Netflix Home app?',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ─── Category Filter Chips ───
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: const Color(0xFFE50914),
                    backgroundColor: isDark
                        ? const Color(0xFF242424)
                        : Colors.grey.withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[300] : Colors.black87),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // ─── Quick Step Guide Card ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tips_and_updates_rounded,
                              color: Colors.blueAccent, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isIndo
                              ? 'Panduan Singkat Pemakaian'
                              : 'Quick Usage Guide',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      number: '1',
                      title: isIndo ? 'Pilih Akun Ready' : 'Select Ready Account',
                      desc: isIndo
                          ? 'Buka tab Daftar Akun dan pilih akun yang aktif.'
                          : 'Go to Accounts tab and select an active account.',
                      isDark: isDark,
                    ),
                    _buildStepRow(
                      number: '2',
                      title: isIndo ? 'Klik Gunakan Akun' : 'Click Use Account',
                      desc: isIndo
                          ? 'Sistem akan mengecek ketersediaan token secara otomatis.'
                          : 'The system will generate an instant token.',
                      isDark: isDark,
                    ),
                    _buildStepRow(
                      number: '3',
                      title: isIndo
                          ? 'Pilih Perangkat Anda'
                          : 'Select Your Device',
                      desc: isIndo
                          ? 'HP (Buka Langsung), PC (Kirim ke WA), atau TV (Kode 8 digit).'
                          : 'Phone (Direct), PC (Send to WA), or TV (8-digit code).',
                      isDark: isDark,
                    ),
                    _buildStepRow(
                      number: '4',
                      title: isIndo
                          ? 'Wajib Patuhi Aturan'
                          : 'Follow Rules',
                      desc: isIndo
                          ? 'Boleh buat profil jika kosong (dilarang hapus profil lain), bebas ubah bahasa, & ganti akun jika layar penuh.'
                          : 'May add profile if empty (do not delete others), free to set language, & switch account if full.',
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Video Tutorial Shorts Showcase Card ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF251012), const Color(0xFF190B0D)]
                        : [const Color(0xFFFFF0F0), const Color(0xFFFFE5E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE50914).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.smart_display_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndo
                                    ? 'Video Tutorial Shorts'
                                    : 'Shorts Video Tutorials',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                isIndo
                                    ? 'Tonton cara cepat login di HP, PC, atau Smart TV'
                                    : 'Watch quick login guides for Phone, PC, or Smart TV',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              VideoTutorialModal.show(
                                context,
                                videoUrl: 'https://youtube.com/shorts/NUKerEzq7pA',
                                title: isIndo ? 'Tutorial Login HP' : 'Phone Login Tutorial',
                              );
                            },
                            icon: const Icon(Icons.smartphone_rounded, size: 14),
                            label: const Text('HP Shorts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE50914),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              VideoTutorialModal.show(
                                context,
                                videoUrl: 'https://youtube.com/shorts/LeNsXxqqrps',
                                title: isIndo ? 'Tutorial Login PC' : 'PC Login Tutorial',
                              );
                            },
                            icon: const Icon(Icons.laptop_mac_rounded, size: 14),
                            label: const Text('PC Shorts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2A2A3A) : Colors.white,
                              foregroundColor: isDark ? Colors.white : const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                                ),
                              ),
                              textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              VideoTutorialModal.show(
                                context,
                                videoUrl: 'https://youtube.com/shorts/xq4TDRb0hR0',
                                title: isIndo ? 'Tutorial Login TV' : 'TV Login Tutorial',
                              );
                            },
                            icon: const Icon(Icons.tv_rounded, size: 14),
                            label: const Text('TV Shorts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2A2A3A) : Colors.white,
                              foregroundColor: isDark ? Colors.white : const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                ),
                              ),
                              textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── FAQ Header ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.help_center_rounded,
                      color: Color(0xFFE50914), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isIndo ? 'Pertanyaan Umum (FAQ)' : 'Frequently Asked Questions',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredFaqs.length} ${isIndo ? 'topik' : 'items'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── FAQ Accordion List ───
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        isIndo
                            ? 'Tidak ada pertanyaan yang sesuai dengan kata kunci "$_searchQuery"'
                            : 'No questions found matching "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(faq['icon'] as IconData,
                                color: const Color(0xFFE50914), size: 20),
                          ),
                          title: Text(
                            isIndo ? faq['q_id'] : faq['q_en'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          iconColor: const Color(0xFFE50914),
                          collapsedIconColor: Colors.grey,
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF262626)
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isIndo ? faq['a_id'] : faq['a_en'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _sendQuestionToWhatsApp(
                                          isIndo ? faq['q_id'] : faq['q_en']),
                                      icon: const Icon(Icons.chat_rounded,
                                          size: 14, color: Color(0xFF25D366)),
                                      label: Text(
                                        isIndo
                                            ? 'Tanyakan Topik Ini ke Admin CS (WA)'
                                            : 'Ask Admin CS About This (WA)',
                                        style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF25D366)),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        side: BorderSide(
                                            color: const Color(0xFF25D366)
                                                .withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // ─── Contact WhatsApp Fallback Banner ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF25D366).withValues(alpha: 0.18),
                      const Color(0xFF128C7E).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIndo
                          ? 'Belum Menemukan Jawaban?'
                          : 'Still haven\'t found the answer?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIndo
                          ? 'Jangan khawatir! Customer Service kami siap melayani dan menyelesaikan kendala akun Anda secara langsung melalui WhatsApp.'
                          : 'Don\'t worry! Our Customer Service is ready to solve your issues directly on WhatsApp.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _contactAdminWhatsApp,
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: Text(
                          isIndo
                              ? 'Hubungi Customer Service via WhatsApp'
                              : 'Contact Customer Service via WhatsApp',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String desc,
    required bool isDark,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFE50914),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
