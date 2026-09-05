import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/account_model.dart';
import '../services/nftoken_service.dart';
import '../services/supabase_service.dart';
import '../utils/language_notifier.dart';
import 'login_help_modal.dart';
import '../widgets/video_tutorial_modal.dart';

class AccountsScreen extends StatefulWidget {
  final String username;
  final VoidCallback? onBack;
  const AccountsScreen({
    super.key,
    required this.username,
    this.onBack,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with TickerProviderStateMixin {
  List<CookieAccount> _accounts = [];
  int _totalAccountsCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _selectedPlan = 'Semua';

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Per-plan offsets for "Semua" balanced mode (~25% each)
  int _basicOffset = 0;
  int _standardOffset = 0;
  int _premiumOffset = 0;
  int _mobileOffset = 0;
  static const int _semuaCountPerPlan = 3;

  // Offset for single-plan mode (5 accounts per batch) or search mode
  int _currentPlanOffset = 0;
  static const int _planPageSize = 5;

  Map<String, int> _planTotals = {
    'Semua': 0,
    'Premium': 0,
    'Standard': 0,
    'Basic': 0,
    'Mobile': 0,
  };

  final ScrollController _listScrollController = ScrollController();

  // Cached tokens and in-progress checking state
  final Map<String, NFTokenResult> _accountTokens = {};
  final Set<String> _checkingAccountIds = {};

  DateTime? _accessExpiryDate;
  bool _isLoadingExpiry = true;

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  bool get _isAccessExpired {
    if (_accessExpiryDate == null) return true;
    return DateTime.now().isAfter(_accessExpiryDate!);
  }

  int get _remainingDays {
    if (_accessExpiryDate == null) return 0;
    final diff = _accessExpiryDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _loadAccounts();
    _loadExpiryDate();
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _listScrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = query.trim();
      if (_searchQuery != trimmed) {
        setState(() {
          _searchQuery = trimmed;
          _currentPlanOffset = 0;
          _basicOffset = 0;
          _standardOffset = 0;
          _premiumOffset = 0;
          _mobileOffset = 0;
        });
        _loadAccounts();
      }
    });
  }

  Future<void> _loadExpiryDate() async {
    final expiry = await SupabaseService.fetchExpiryDate();
    if (mounted) {
      setState(() {
        _accessExpiryDate = expiry;
        _isLoadingExpiry = false;
      });
    }
  }

  Future<void> _loadAccounts({bool isSwap = false}) async {
    if (!isSwap) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final isAll = _selectedPlan == 'Semua' || _selectedPlan == 'All';
      final hasSearch = _searchQuery.trim().isNotEmpty;

      if (isAll) {
        if (!hasSearch) {
          // Normal balanced mode (3 per plan = ~12 accounts)
          final result = await SupabaseService.fetchBalancedAccounts(
            basicOffset: _basicOffset,
            standardOffset: _standardOffset,
            premiumOffset: _premiumOffset,
            mobileOffset: _mobileOffset,
            countPerPlan: _semuaCountPerPlan,
            searchQuery: null,
          );

          if (mounted) {
            setState(() {
              _accounts = result.accounts;
              _totalAccountsCount = result.totalCount;
              _planTotals = {
                'Semua': result.totalCount,
                ...result.planTotals,
              };
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
        } else {
          // Search mode on Semua: query paged accounts matching search + synchronize all chip counts
          final futures = await Future.wait([
            SupabaseService.fetchCookieAccountsPaged(
              limit: 10,
              offset: _currentPlanOffset,
              searchQuery: _searchQuery,
            ),
            SupabaseService.fetchAllPlanCounts(searchQuery: _searchQuery),
          ]);

          final pagedResult = futures[0] as PagedAccountsResult;
          final counts = futures[1] as Map<String, int>;

          if (mounted) {
            setState(() {
              _accounts = pagedResult.accounts;
              _totalAccountsCount = counts['Semua'] ?? pagedResult.totalCount;
              _planTotals = counts;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
        }
      } else {
        // Specific plan: fetch 5 accounts of this plan + synchronize all chip counts with search query
        final futures = await Future.wait([
          SupabaseService.fetchAccountsByPlan(
            _selectedPlan,
            limit: _planPageSize,
            offset: _currentPlanOffset,
            searchQuery: _searchQuery,
          ),
          SupabaseService.fetchAllPlanCounts(searchQuery: _searchQuery),
        ]);

        final planResult = futures[0] as PagedAccountsResult;
        final counts = futures[1] as Map<String, int>;

        if (mounted) {
          setState(() {
            _accounts = planResult.accounts;
            _totalAccountsCount = counts['Semua'] ?? 0;
            _planTotals = counts;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      }

      await _loadExpiryDate();

      if (isSwap && mounted) {
        if (_listScrollController.hasClients) {
          _listScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageNotifier.isIndonesian.value
                  ? 'Berhasil menampilkan pilihan akun lainnya!'
                  : 'Successfully swapped with other accounts!',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _swapAccounts() {
    final isAll = _selectedPlan == 'Semua' || _selectedPlan == 'All';
    final hasSearch = _searchQuery.trim().isNotEmpty;

    if (isAll && !hasSearch) {
      final premTotal = math.max(1, _planTotals['Premium'] ?? 1);
      final stdTotal = math.max(1, _planTotals['Standard'] ?? 1);
      final bscTotal = math.max(1, _planTotals['Basic'] ?? 1);
      final mobTotal = math.max(1, _planTotals['Mobile'] ?? 1);

      // Loop back to 0 (very first accounts) when all accounts have been cycled through
      _premiumOffset = (_premiumOffset + _semuaCountPerPlan >= premTotal)
          ? 0
          : (_premiumOffset + _semuaCountPerPlan);
      _standardOffset = (_standardOffset + _semuaCountPerPlan >= stdTotal)
          ? 0
          : (_standardOffset + _semuaCountPerPlan);
      _basicOffset = (_basicOffset + _semuaCountPerPlan >= bscTotal)
          ? 0
          : (_basicOffset + _semuaCountPerPlan);
      _mobileOffset = (_mobileOffset + _semuaCountPerPlan >= mobTotal)
          ? 0
          : (_mobileOffset + _semuaCountPerPlan);
    } else {
      final totalForPlan = isAll
          ? math.max(1, _planTotals['Semua'] ?? 1)
          : math.max(1, _planTotals[_selectedPlan] ?? 1);

      final pageSize = isAll ? 10 : _planPageSize;

      // Loop back to 0 (very first accounts) when all accounts have been cycled through
      if (_currentPlanOffset + pageSize >= totalForPlan) {
        _currentPlanOffset = 0;
      } else {
        _currentPlanOffset += pageSize;
      }
    }
    _loadAccounts(isSwap: true);
  }

  void _onSelectPlan(String plan) {
    if (_selectedPlan == plan) return;
    setState(() {
      _selectedPlan = plan;
      _currentPlanOffset = 0;
      _basicOffset = 0;
      _standardOffset = 0;
      _premiumOffset = 0;
      _mobileOffset = 0;
    });
    _loadAccounts();
  }

  Future<void> _contactAdminWhatsApp({String? customMessage}) async {
    final text = customMessage ??
        'Halo Admin Netflix Home, saya (${widget.username}) butuh bantuan perpanjangan paket / informasi akun.';
    final waUrl = Uri.parse('https://wa.me/6282268426070?text=${Uri.encodeComponent(text)}');
    final waAppUrl = Uri.parse('whatsapp://send?phone=6282268426070&text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(waAppUrl)) {
        await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showExpiredSubscriptionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock, size: 42, color: Colors.redAccent),
              ),
              const SizedBox(height: 18),
              Text(
                LanguageNotifier.isIndonesian.value ? 'Masa Aktif Paket Berakhir' : 'Package Expired',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '0 ${LanguageNotifier.isIndonesian.value ? 'Hari Tersisa' : 'Days Left'}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Masa aktif langganan Anda telah habis. Fitur cek akun dan link login terkunci. Silakan hubungi admin via WhatsApp untuk membeli atau memperpanjang paket Anda.'
                    : 'Your subscription has expired. Account checks and login links are locked. Please contact admin via WhatsApp to buy or extend your package.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _contactAdminWhatsApp();
                  },
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(
                    LanguageNotifier.isIndonesian.value ? 'Beli / Perpanjang via WhatsApp' : 'Buy / Extend via WhatsApp',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  LanguageNotifier.tr('close'),
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndOpenLinks(CookieAccount acc) async {
    if (_isAccessExpired) {
      _showExpiredSubscriptionModal();
      return;
    }

    // If token already generated and successful, show links directly
    if (_accountTokens.containsKey(acc.id) && _accountTokens[acc.id]!.success) {
      _showAccountLinksModal(acc, _accountTokens[acc.id]!);
      return;
    }

    setState(() => _checkingAccountIds.add(acc.id));

    try {
      final result = await NFTokenService.generateNFToken(acc.cookieContent);
      if (mounted) {
        setState(() {
          _checkingAccountIds.remove(acc.id);
          _accountTokens[acc.id] = result;
        });

        if (result.success) {
          _showAccountLinksModal(acc, result);
        } else {
          // Unusable account: delete from DB and immediately add 1 replacement account!
          await _handleAccountErrorAndReplace(acc);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingAccountIds.remove(acc.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            content: Text(
              LanguageNotifier.isIndonesian.value ? 'Terjadi kesalahan: $e' : 'An error occurred: $e',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        );
      }
    }
  }

  String _normalizePlanName(String raw) {
    final p = raw.toLowerCase();
    if (p.contains('premium')) return 'Premium';
    if (p.contains('standard')) return 'Standard';
    if (p.contains('basic')) return 'Basic';
    if (p.contains('mobile')) return 'Mobile';
    return 'Premium';
  }

  Future<void> _handleAccountErrorAndReplace(CookieAccount failedAccount) async {
    final targetIndex = _accounts.indexWhere((a) => a.id == failedAccount.id);
    final normalizedPlan = _normalizePlanName(failedAccount.planName);

    // 1. Instantly remove from local list and state so UI updates in 0ms
    setState(() {
      _accounts.removeWhere((a) => a.id == failedAccount.id);
      _accountTokens.remove(failedAccount.id);
      _checkingAccountIds.remove(failedAccount.id);

      if (_totalAccountsCount > 0) _totalAccountsCount--;
      if ((_planTotals[normalizedPlan] ?? 0) > 0) {
        _planTotals[normalizedPlan] = _planTotals[normalizedPlan]! - 1;
      }
      if ((_planTotals['Semua'] ?? 0) > 0) {
        _planTotals['Semua'] = _planTotals['Semua']! - 1;
      }
    });

    // 2. Delete from Supabase Database in background
    SupabaseService.deleteCookieAccount(failedAccount.id).ignore();

    // 3. Fetch 1 fresh replacement account from DB
    try {
      final isAll = _selectedPlan == 'Semua' || _selectedPlan == 'All';

      int offset = 0;
      if (isAll) {
        if (normalizedPlan == 'Premium') {
          _premiumOffset++;
          offset = _premiumOffset + _semuaCountPerPlan;
        } else if (normalizedPlan == 'Standard') {
          _standardOffset++;
          offset = _standardOffset + _semuaCountPerPlan;
        } else if (normalizedPlan == 'Basic') {
          _basicOffset++;
          offset = _basicOffset + _semuaCountPerPlan;
        } else {
          _mobileOffset++;
          offset = _mobileOffset + _semuaCountPerPlan;
        }
      } else {
        _currentPlanOffset++;
        offset = _currentPlanOffset + _accounts.length;
      }

      final totalForPlan = _planTotals[normalizedPlan] ?? 50;
      offset = offset % math.max(1, totalForPlan);

      // Fetch up to 3 candidates to avoid picking any account already on screen
      final result = await SupabaseService.fetchAccountsByPlan(
        normalizedPlan,
        limit: 3,
        offset: offset,
        searchQuery: _searchQuery,
      );

      CookieAccount? replacement;
      final existingIds = _accounts.map((a) => a.id).toSet();
      existingIds.add(failedAccount.id);

      for (final candidate in result.accounts) {
        if (!existingIds.contains(candidate.id)) {
          replacement = candidate;
          break;
        }
      }

      // Fallback: If not found for specific plan, fetch from all accounts
      if (replacement == null && isAll) {
        final fallbackResult = await SupabaseService.fetchCookieAccountsPaged(
          limit: 3,
          offset: offset,
          searchQuery: _searchQuery,
        );
        for (final candidate in fallbackResult.accounts) {
          if (!existingIds.contains(candidate.id)) {
            replacement = candidate;
            break;
          }
        }
      }

      if (replacement != null && mounted) {
        setState(() {
          if (targetIndex >= 0 && targetIndex <= _accounts.length) {
            _accounts.insert(targetIndex, replacement!);
          } else {
            _accounts.add(replacement!);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.auto_mode_rounded, color: Color(0xFF46D369), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageNotifier.isIndonesian.value
                        ? 'Akun otomatis diperbarui! Kami telah menyiapkan 1 akun ${replacement.planName} baru yang segar untuk Anda. Silakan gunakan akun ini ✓'
                        : 'Account automatically refreshed! We prepared a fresh 1 ${replacement.planName} account for you ✓',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white, height: 1.3),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageNotifier.isIndonesian.value
                        ? 'Akun telah otomatis diperbarui! Silakan pilih akun lain di daftar.'
                        : 'Account automatically refreshed! Please choose another account from the list.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
  }



  // ignore: unused_field - reserved for future native Netflix launcher integration
  static const _platformLauncher = MethodChannel('com.example.netflix_tools/netflix_launcher');

  Future<void> _launchDirectNetflixApp(String nftoken) async {
    final netflixWeb = Uri.parse('https://www.netflix.com/unsupported?nftoken=$nftoken');

    try {
      await launchUrl(netflixWeb, mode: LaunchMode.inAppBrowserView);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE50914),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageNotifier.isIndonesian.value
                        ? 'Tekan tombol "Buka Aplikasi" berwarna merah untuk masuk ke Netflix.'
                        : 'Press the red "Open App" button to enter Netflix.',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(LanguageNotifier.isIndonesian.value ? 'Gagal membuka halaman: $e' : 'Failed to open page: $e'),
          ),
        );
      }
    }
  }

  Future<void> _openInAppBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(LanguageNotifier.isIndonesian.value ? 'Gagal membuka browser: $e' : 'Failed to open browser: $e'),
          ),
        );
      }
    }
  }

  void _showQrCodeModal(String qrUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2, color: Color(0xFFE50914), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        LanguageNotifier.isIndonesian.value ? 'QR Code Login Netflix' : 'Netflix Login QR Code',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: SizedBox(
                    width: 210,
                    height: 210,
                    child: QrImageView(
                      data: qrUrl,
                      version: QrVersions.auto,
                      size: 210.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[400], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageNotifier.isIndonesian.value
                              ? 'Arahkan kamera HP / Tablet lain ke QR Code di atas untuk langsung masuk tanpa email & password.'
                              : 'Point another phone/tablet camera to the QR Code above to log in instantly without email & password.',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.blue[600], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(LanguageNotifier.tr('close'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountInfoModal(CookieAccount acc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planColor = _getPlanColor(acc.planName);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        planColor.withValues(alpha: 0.15),
                        planColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: planColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_outline, color: planColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageNotifier.isIndonesian.value ? 'Informasi Akun Netflix' : 'Netflix Account Info',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  acc.email != 'Unknown' ? acc.email : acc.filename,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: planColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              acc.planName,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: planColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Info rows
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        Icons.workspace_premium,
                        LanguageNotifier.isIndonesian.value ? 'Paket Layanan' : 'Service Plan',
                        '${acc.planName} (${acc.videoQuality})',
                        planColor,
                      ),
                      _buildInfoTile(
                        Icons.tv,
                        LanguageNotifier.isIndonesian.value ? 'Maksimal Layar' : 'Max Screens',
                        LanguageNotifier.isIndonesian.value ? '${acc.maxStreams} Layar Streaming' : '${acc.maxStreams} Screens',
                        Colors.blue,
                      ),
                      _buildInfoTile(
                        Icons.public,
                        LanguageNotifier.isIndonesian.value ? 'Wilayah / Negara' : 'Region / Country',
                        acc.country,
                        Colors.teal,
                      ),
                      _buildInfoTile(
                        Icons.credit_card,
                        LanguageNotifier.isIndonesian.value ? 'Status Pembayaran' : 'Payment Status',
                        acc.paymentStatus,
                        Colors.green,
                      ),
                      _buildInfoTile(
                        Icons.calendar_today,
                        LanguageNotifier.isIndonesian.value ? 'Terdaftar Sejak' : 'Member Since',
                        acc.memberSince,
                        Colors.purple,
                      ),
                      _buildInfoTile(
                        Icons.update,
                        LanguageNotifier.isIndonesian.value ? 'Tagihan Berikutnya' : 'Next Billing',
                        acc.nextBilling,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Aturan Menonton Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.12),
                          Colors.orange.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.rule_folder_outlined, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              LanguageNotifier.isIndonesian.value
                                  ? 'Aturan Menonton Netflix Home:'
                                  : 'Netflix Home Watching Rules:',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.amber[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRuleBullet(
                          Icons.person_add_alt_1_outlined,
                          LanguageNotifier.isIndonesian.value
                              ? 'Boleh tambah profil baru jika ada slot kosong, asalkan TIDAK MENGHAPUS profil yang sudah ada.'
                              : 'You may add a new profile if an empty slot exists, but DO NOT DELETE existing profiles.',
                        ),
                        const SizedBox(height: 6),
                        _buildRuleBullet(
                          Icons.translate_rounded,
                          LanguageNotifier.isIndonesian.value
                              ? 'Bebas ubah bahasa tampilan ke Bahasa Indonesia jika akun berbahasa asing.'
                              : 'Feel free to change profile language back to Bahasa Indonesia.',
                        ),
                        const SizedBox(height: 6),
                        _buildRuleBullet(
                          Icons.tv_off_outlined,
                          LanguageNotifier.isIndonesian.value
                              ? 'Jika terkena limit layar, cukup keluar (logout) & ambil akun baru di Netflix Home (stok akun melimpah).'
                              : 'If screen limit is reached, simply logout and pick another account in Netflix Home.',
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _contactAdminWhatsApp(
                              customMessage:
                                  'Halo Admin Netflix Home, akun Netflix (${acc.email}) mengalami kendala saat digunakan. Mohon bantuan pengecekan.',
                            );
                          },
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: Text(
                            LanguageNotifier.isIndonesian.value ? 'Lapor Kendala Akun Ini' : 'Report Account Issue',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            LanguageNotifier.tr('close'),
                            style: GoogleFonts.inter(color: Colors.grey),
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
      ),
    );
  }

  Future<void> _shareToWhatsAppForPc(String url) async {
    final text = '$url\n\nLink netflix ini pakai untuk pc dan tekan di pc atau laptop';
    final waUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final waAppUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(waAppUrl)) {
        await launchUrl(waAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showAccountLinksModal(CookieAccount acc, NFTokenResult nf) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF46D369).withValues(alpha: 0.15),
                        const Color(0xFF46D369).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF46D369).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF46D369), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LanguageNotifier.isIndonesian.value ? 'Akun Siap Digunakan ✓' : 'Account Ready ✓',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LanguageNotifier.isIndonesian.value ? 'Pilih cara masuk ke Netflix' : 'Choose how to enter Netflix',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account info mini
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252540) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 18, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                acc.email != 'Unknown' ? acc.email : acc.filename,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getPlanColor(acc.planName).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                acc.planName,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _getPlanColor(acc.planName)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Aturan Menonton Penting Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF202038) : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                LanguageNotifier.isIndonesian.value
                                    ? 'Aturan Menonton:\n• Boleh tambah profil jika kosong (jangan hapus profil lain)\n• Bebas ubah bahasa Netflix ke Bahasa Indonesia\n• Jika layar penuh, keluar & ambil akun baru di Netflix Home'
                                    : 'Watching Rules:\n• May add profile if empty (do not delete other profiles)\n• Free to change Netflix language to Indonesian\n• If screen full, logout & pick another account in Netflix Home',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.amber[200] : Colors.amber[900],
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1. Direct Netflix Mobile App Auto-Login (Featured)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFE50914).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
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
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.smartphone, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LanguageNotifier.isIndonesian.value ? 'HP Android & iPhone' : 'Android & iPhone',
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'Buka langsung di aplikasi Netflix'
                                            : 'Open directly in Netflix app',
                                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Auto Login',
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _launchDirectNetflixApp(nf.nftoken!);
                                },
                                icon: const Icon(Icons.rocket_launch, size: 16),
                                label: Text(
                                  LanguageNotifier.isIndonesian.value ? 'Buka Netflix Sekarang' : 'Open Netflix Now',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFE50914),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          LanguageNotifier.isIndonesian.value ? 'Perangkat Lain' : 'Other Devices',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                        ),
                      ),

                      // 2. PC (Laptop / PC)
                      _buildLoginMethodTile(
                        icon: Icons.laptop_mac,
                        iconColor: Colors.blue,
                        title: LanguageNotifier.isIndonesian.value ? 'Laptop / PC' : 'Laptop / PC',
                        subtitle: LanguageNotifier.isIndonesian.value ? 'Kirim link khusus PC ke WhatsApp' : 'Send special PC link to WhatsApp',
                        buttonText: LanguageNotifier.isIndonesian.value ? 'Kirim via WA' : 'Send via WA',
                        buttonIcon: Icons.send_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          _shareToWhatsAppForPc(nf.urlPc2);
                        },
                      ),
                      const SizedBox(height: 8),

                      // 3. Smart TV
                      _buildLoginMethodTile(
                        icon: Icons.tv,
                        iconColor: Colors.purple,
                        title: LanguageNotifier.isIndonesian.value ? 'Smart TV' : 'Smart TV',
                        subtitle: LanguageNotifier.isIndonesian.value ? 'Masukkan kode 8 digit dari layar TV' : 'Enter 8-digit code from TV screen',
                        buttonText: LanguageNotifier.isIndonesian.value ? 'Buka Link' : 'Open Link',
                        buttonIcon: Icons.open_in_new,
                        onTap: () {
                          Navigator.pop(ctx);
                          _openInAppBrowser(nf.urlTv);
                        },
                      ),
                      const SizedBox(height: 8),

                      // 4. QR Code
                      _buildLoginMethodTile(
                        icon: Icons.qr_code_scanner,
                        iconColor: Colors.teal,
                        title: LanguageNotifier.isIndonesian.value ? 'QR Code Login' : 'QR Code Login',
                        subtitle: LanguageNotifier.isIndonesian.value ? 'Scan dengan kamera HP lain' : 'Scan with another phone camera',
                        buttonText: LanguageNotifier.isIndonesian.value ? 'Tampilkan' : 'Show QR',
                        buttonIcon: Icons.qr_code_2,
                        onTap: () {
                          Navigator.pop(ctx);
                          _showQrCodeModal(nf.urlQr);
                        },
                      ),

                      const SizedBox(height: 14),

                      // ─── UNIFIED VIDEO TUTORIAL SHORTS CARD ───
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F1F32) : const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE50914).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.smart_display_rounded, size: 18, color: Color(0xFFE50914)),
                                const SizedBox(width: 8),
                                Text(
                                  LanguageNotifier.isIndonesian.value
                                      ? 'Video Tutorial Shorts'
                                      : 'Shorts Video Tutorials',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    LoginHelpModal.show(context);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    LanguageNotifier.isIndonesian.value ? 'Panduan FAQ' : 'FAQ Guide',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE50914),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildTutorialChip(
                                  icon: Icons.smartphone_rounded,
                                  label: 'Shorts HP',
                                  color: const Color(0xFF4CAF50),
                                  onTap: () {
                                    VideoTutorialModal.show(
                                      context,
                                      videoUrl: 'https://youtube.com/shorts/NUKerEzq7pA',
                                      title: LanguageNotifier.isIndonesian.value
                                          ? 'Tutorial Login HP'
                                          : 'Phone Login Tutorial',
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildTutorialChip(
                                  icon: Icons.laptop_mac_rounded,
                                  label: 'Shorts PC',
                                  color: const Color(0xFF2196F3),
                                  onTap: () {
                                    VideoTutorialModal.show(
                                      context,
                                      videoUrl: 'https://youtube.com/shorts/LeNsXxqqrps',
                                      title: LanguageNotifier.isIndonesian.value
                                          ? 'Tutorial Login PC'
                                          : 'PC Login Tutorial',
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildTutorialChip(
                                  icon: Icons.tv_rounded,
                                  label: 'Shorts TV',
                                  color: const Color(0xFFFF9800),
                                  onTap: () {
                                    VideoTutorialModal.show(
                                      context,
                                      videoUrl: 'https://youtube.com/shorts/xq4TDRb0hR0',
                                      title: LanguageNotifier.isIndonesian.value
                                          ? 'Tutorial Login TV'
                                          : 'TV Login Tutorial',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            LanguageNotifier.tr('close'),
                            style: GoogleFonts.inter(color: Colors.grey),
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
      ),
    );
  }

  Widget _buildRuleBullet(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.amber[800]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: Colors.amber[900],
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethodTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(buttonIcon, size: 14),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF2D2D4A) : Colors.white,
              foregroundColor: iconColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
              elevation: 0,
              side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPlanColor(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('premium')) return const Color(0xFFFFB800);
    if (p.contains('standard')) return const Color(0xFF46D369);
    if (p.contains('basic')) return Colors.blueAccent;
    if (p.contains('mobile')) return Colors.purpleAccent;
    return Colors.grey;
  }

  IconData _getPlanIcon(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('premium')) return Icons.workspace_premium;
    if (p.contains('standard')) return Icons.hd;
    if (p.contains('basic')) return Icons.sd;
    if (p.contains('mobile')) return Icons.smartphone;
    return Icons.movie;
  }

  List<CookieAccount> get _filteredAccounts => _accounts;

  int _getCountForPlan(String plan) {
    if (plan == 'Semua' || plan == 'All') {
      return _planTotals['Semua'] ?? _totalAccountsCount;
    }
    return _planTotals[plan] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plans = LanguageNotifier.isIndonesian.value
        ? ['Semua', 'Basic', 'Standard', 'Premium', 'Mobile']
        : ['All', 'Basic', 'Standard', 'Premium', 'Mobile'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom SliverAppBar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF141428) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else if (widget.onBack != null) {
                    widget.onBack!();
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _headerFadeAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1A1A35), const Color(0xFF0D0D1A)]
                            : [const Color(0xFFE50914).withValues(alpha: 0.08), const Color(0xFFF5F6FA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title + badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE50914).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.movie_filter, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LanguageNotifier.isIndonesian.value ? 'Daftar Akun Netflix' : 'Netflix Account List',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        LanguageNotifier.isIndonesian.value
                                            ? 'Pilih akun dan mulai nonton sekarang'
                                            : 'Choose an account and start watching',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Stats row
                            Row(
                              children: [
                                _buildStatChip(
                                  icon: Icons.library_books,
                                  label: LanguageNotifier.isIndonesian.value ? 'Total' : 'Total',
                                  value: _totalAccountsCount > 0 ? '$_totalAccountsCount' : '${_accounts.length}',
                                  color: Colors.blue,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 10),
                                _buildStatChip(
                                  icon: Icons.check_circle,
                                  label: 'Live',
                                  value: _totalAccountsCount > 0 ? '$_totalAccountsCount' : '${_accounts.where((a) => a.status == 'LIVE').length}',
                                  color: const Color(0xFF46D369),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 10),
                                _buildStatChip(
                                  icon: _isAccessExpired ? Icons.lock : Icons.verified_user,
                                  label: LanguageNotifier.isIndonesian.value ? 'Akses' : 'Access',
                                  value: _isLoadingExpiry
                                      ? '...'
                                      : _isAccessExpired
                                          ? (LanguageNotifier.isIndonesian.value ? 'Habis' : 'Expired')
                                          : '$_remainingDays ${LanguageNotifier.isIndonesian.value ? 'Hari' : 'Days'}',
                                  color: _isAccessExpired ? Colors.red : Colors.orange,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoadingExpiry
            ? const Center(child: CircularProgressIndicator())
            : _isAccessExpired 
                ? _buildLockedState(isDark)
                : Column(
          children: [
            // Search + Filter section
            Container(
              color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F6FA),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A30) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: LanguageNotifier.isIndonesian.value
                              ? 'Cari akun (email, nama, negara)...'
                              : 'Search accounts (email, name, country)...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey[400]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // Plan Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: plans.map((plan) {
                        final isSelected = _selectedPlan == plan;
                        final isAll = plan == 'Semua' || plan == 'All';
                        final planColor = isAll ? const Color(0xFFE50914) : _getPlanColor(plan);
                        final count = _getCountForPlan(plan);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _onSelectPlan(plan),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? planColor
                                        : (isDark ? const Color(0xFF1A1A30) : Colors.white),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? planColor
                                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: planColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      if (!isAll) ...[
                                        Icon(
                                          _getPlanIcon(plan),
                                          size: 14,
                                          color: isSelected ? Colors.white : planColor,
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        plan,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.grey[300] : Colors.black87),
                                        ),
                                      ),
                                      if (count > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.25)
                                                : planColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$count',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : planColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // Accounts List
            Expanded(
              child: _isLoading
                  ? _buildLoadingShimmer(isDark)
                  : _filteredAccounts.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          color: const Color(0xFFE50914),
                          backgroundColor: isDark ? const Color(0xFF1A1A30) : Colors.white,
                          onRefresh: () => _loadAccounts(),
                          child: ListView.builder(
                            controller: _listScrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _filteredAccounts.length + 1,
                            itemBuilder: (context, index) {
                              if (index < _filteredAccounts.length) {
                                final acc = _filteredAccounts[index];
                                return _buildAccountCard(acc, index, isDark);
                              }
                              return _buildLoadMoreFooter(isDark);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(bool isDark) {
    final isAll = _selectedPlan == 'Semua' || _selectedPlan == 'All';
    final totalCount = isAll
        ? (_totalAccountsCount > 0 ? _totalAccountsCount : 1093)
        : (_planTotals[_selectedPlan] ?? 0);

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAll
                      ? (LanguageNotifier.isIndonesian.value
                          ? 'Menampilkan ${_filteredAccounts.length} Pilihan Akun'
                          : 'Showing ${_filteredAccounts.length} Accounts')
                      : (LanguageNotifier.isIndonesian.value
                          ? 'Menampilkan ${_filteredAccounts.length} dari $totalCount Akun $_selectedPlan'
                          : 'Showing ${_filteredAccounts.length} of $totalCount $_selectedPlan Accounts'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE50914),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Button: Tukar dengan Akun Baru
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingMore ? null : _swapAccounts,
              icon: _isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.swap_horiz_rounded, size: 20),
              label: Text(
                _isLoadingMore
                    ? (LanguageNotifier.isIndonesian.value ? 'Sedang Menyiapkan Akun Lain...' : 'Loading Other Accounts...')
                    : (LanguageNotifier.isIndonesian.value ? 'Tukar Pilihan Akun Lain' : 'Show Other Accounts'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            LanguageNotifier.isIndonesian.value
                ? '💡 Tekan tombol di atas jika ingin melihat pilihan akun Netflix lainnya.'
                : '💡 Tap the button above to explore other Netflix accounts.',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: Colors.grey[500],
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.redAccent.withValues(alpha: 0.1) : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: isDark ? Colors.redAccent : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LanguageNotifier.isIndonesian.value
                  ? 'Akses Terkunci'
                  : 'Access Locked',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              LanguageNotifier.isIndonesian.value
                  ? 'Status akun Anda saat ini adalah Free atau masa aktif telah habis. Anda tidak dapat mengakses daftar akun.\n\nSilakan beli atau perpanjang paket untuk menikmati layanan ini.'
                  : 'Your account status is Free or your subscription has expired. You cannot access the account list.\n\nPlease buy or extend your package to enjoy this service.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _contactAdminWhatsApp,
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: Text(
                LanguageNotifier.isIndonesian.value
                    ? 'Hubungi Admin'
                    : 'Contact Admin',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(CookieAccount acc, int index, bool isDark) {
    final planColor = _getPlanColor(acc.planName);
    final isChecking = _checkingAccountIds.contains(acc.id);
    final hasToken = _accountTokens.containsKey(acc.id) && _accountTokens[acc.id]!.success;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasToken
                ? const Color(0xFF46D369).withValues(alpha: 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAccountInfoModal(acc),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Plan Avatar with gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [planColor.withValues(alpha: 0.2), planColor.withValues(alpha: 0.08)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(
                            _getPlanIcon(acc.planName),
                            color: planColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Account Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    acc.email != 'Unknown' ? acc.email : acc.filename,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasToken) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF46D369),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Plan badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: planColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    acc.planName,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: planColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quality
                                Icon(Icons.hd, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 3),
                                Text(
                                  acc.videoQuality,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                ),
                                const SizedBox(width: 8),
                                // Screens
                                Icon(Icons.screen_share_outlined, size: 13, color: Colors.grey[400]),
                                const SizedBox(width: 3),
                                Text(
                                  '${acc.maxStreams}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.public, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  acc.country,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.credit_card, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    acc.paymentStatus,
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons row
                  Row(
                    children: [
                      // Info button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAccountInfoModal(acc),
                          icon: Icon(Icons.info_outline, size: 15, color: Colors.grey[500]),
                          label: Text(
                            LanguageNotifier.isIndonesian.value ? 'Detail' : 'Details',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Main CTA button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isChecking ? null : () => _checkAndOpenLinks(acc),
                          icon: isChecking
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(
                                  hasToken ? Icons.play_circle_filled : Icons.bolt,
                                  size: 18,
                                ),
                          label: Text(
                            isChecking
                                ? (LanguageNotifier.isIndonesian.value ? 'Memproses...' : 'Processing...')
                                : hasToken
                                    ? (LanguageNotifier.isIndonesian.value ? 'Buka Link' : 'Open Links')
                                    : (LanguageNotifier.isIndonesian.value ? 'Gunakan Akun Ini' : 'Use This Account'),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasToken ? const Color(0xFF46D369) : const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE50914).withValues(alpha: 0.5),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A30) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.movie_filter_outlined,
                size: 42,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? (LanguageNotifier.isIndonesian.value ? 'Tidak Ditemukan' : 'Not Found')
                  : (LanguageNotifier.isIndonesian.value ? 'Belum Ada Akun' : 'No Accounts Yet'),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? (LanguageNotifier.isIndonesian.value
                      ? 'Tidak ada akun yang cocok dengan pencarian "$_searchQuery"'
                      : 'No accounts match your search "$_searchQuery"')
                  : (LanguageNotifier.isIndonesian.value
                      ? 'Akun Netflix belum tersedia saat ini. Silakan coba lagi nanti.'
                      : 'Netflix accounts are not available yet. Please try again later.'),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (_searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.clear, size: 16),
                label: Text(
                  LanguageNotifier.isIndonesian.value ? 'Hapus Pencarian' : 'Clear Search',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _loadAccounts,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  LanguageNotifier.isIndonesian.value ? 'Muat Ulang' : 'Reload',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 800 + (index * 100)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value * 0.5 + 0.2,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A30) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 180,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 10,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 140,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
