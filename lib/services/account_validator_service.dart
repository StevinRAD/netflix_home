import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nftoken_service.dart';

/// Status pembayaran akun Netflix
enum PaymentStatus {
  paid,
  pending,
  onHold,
  noPayment,
  canceled,
  freeTrial,
  neverMember,
  unknown,
}

/// Hasil validasi akun Netflix
class AccountValidationResult {
  final PaymentStatus status;
  final String statusCode;
  final String label;
  final bool isUsable;
  final Map<String, dynamic> membershipData;

  AccountValidationResult({
    required this.status,
    required this.statusCode,
    required this.label,
    required this.isUsable,
    this.membershipData = const {},
  });

  factory AccountValidationResult.paid({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.paid,
      statusCode: 'PAID',
      label: 'Aktif & Terbayar',
      isUsable: true,
      membershipData: data,
    );
  }

  factory AccountValidationResult.onHold(String detail, {Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.onHold,
      statusCode: 'ON_HOLD',
      label: 'Akun Ditahan (Pembayaran Gagal${detail.isNotEmpty ? " - $detail" : ""})',
      isUsable: false,
      membershipData: data,
    );
  }

  factory AccountValidationResult.pending({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.pending,
      statusCode: 'PENDING',
      label: 'Pembayaran Tertunda',
      isUsable: false,
      membershipData: data,
    );
  }

  factory AccountValidationResult.canceled({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.canceled,
      statusCode: 'CANCELED',
      label: 'Canceled / Expired',
      isUsable: false,
      membershipData: data,
    );
  }

  factory AccountValidationResult.noPayment({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.noPayment,
      statusCode: 'NO_PAYMENT',
      label: 'Never Member (Belum Pernah Berlangganan)',
      isUsable: false,
      membershipData: data,
    );
  }

  factory AccountValidationResult.freeTrial({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.freeTrial,
      statusCode: 'FREE_TRIAL',
      label: 'Free Trial Aktif',
      isUsable: true,
      membershipData: data,
    );
  }

  factory AccountValidationResult.unknown({Map<String, dynamic> data = const {}}) {
    return AccountValidationResult(
      status: PaymentStatus.unknown,
      statusCode: 'UNKNOWN',
      label: 'Tidak Diketahui',
      isUsable: true, // Anggap usable jika unknown agar NFToken masih bisa dicoba
      membershipData: data,
    );
  }
}

/// Service untuk validasi status akun Netflix sebelum generate NFToken.
/// Port dari logic `detect_payment_status` di ntfvalid.py.
class AccountValidatorService {
  static const Map<String, String> _browseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
    'Connection': 'keep-alive',
    'DNT': '1',
    'Sec-Ch-Ua': '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"Windows"',
  };

  /// Validasi status pembayaran akun Netflix menggunakan cookie.
  /// Mengembalikan [AccountValidationResult] dengan status pembayaran.
  ///
  /// Flow:
  /// 1. Extract NetflixId dari cookie
  /// 2. Akses Netflix /browse untuk mendapatkan build_id
  /// 3. Panggil pathEvaluator API untuk ambil data membership (isOnHold, paymentFailed, dll)
  /// 4. Akses /account untuk HTML-based detection
  /// 5. Analisis JSON data dan HTML untuk menentukan payment status
  static Future<AccountValidationResult> validateAccount(String cookieStr) async {
    final netflixId = NFTokenService.extractNetflixId(cookieStr);
    if (netflixId == null || netflixId.isEmpty) {
      return AccountValidationResult.unknown();
    }

    final cookieDict = NFTokenService.parseCookies(cookieStr);
    final cookieHeader = _buildCookieHeader(cookieDict);

    Map<String, dynamic> membershipData = {};
    String htmlText = '';

    try {
      // Step 1: Browse Netflix untuk dapatkan build_id
      final browseHeaders = Map<String, String>.from(_browseHeaders);
      browseHeaders['Cookie'] = cookieHeader;

      final browseResp = await http.get(
        Uri.parse('https://www.netflix.com/browse'),
        headers: browseHeaders,
      ).timeout(const Duration(seconds: 15));

      if (browseResp.statusCode != 200) {
        return AccountValidationResult.unknown();
      }

      final browseHtml = browseResp.body;

      // Cek apakah cookie sudah mati (ter-redirect ke login/clearcookies)
      final currentPath = browseResp.request?.url.path.toLowerCase() ?? '';
      if (currentPath.contains('/login') || 
          currentPath.contains('/clearcookies') || 
          browseHtml.contains('name="authURL"') || 
          browseHtml.contains('page-login')) {
        return AccountValidationResult.canceled(data: {'reason': 'cookie_expired'});
      }

      // Extract build_id dari response
      final buildId = _extractBuildId(browseHtml);

      // Step 2: Panggil pathEvaluator API jika build_id ditemukan
      if (buildId != null && buildId.isNotEmpty) {
        membershipData = await _fetchMembershipData(buildId, browseHeaders);
      }

      // Step 3: Akses /account untuk HTML-based detection
      try {
        final accountResp = await http.get(
          Uri.parse('https://www.netflix.com/account'),
          headers: browseHeaders,
        ).timeout(const Duration(seconds: 15));

        if (accountResp.statusCode == 200) {
          htmlText = accountResp.body;

          // Extract data dari reactContext di halaman /account
          _extractReactContextData(htmlText, membershipData);
        }
      } catch (_) {}

      // Step 4: Deteksi payment status dari data yang dikumpulkan
      return _detectPaymentStatus(htmlText, membershipData);
    } catch (e) {
      // Jika gagal koneksi, return unknown agar NFToken masih bisa dicoba
      return AccountValidationResult.unknown(data: membershipData);
    }
  }

  /// Build cookie header string dari cookie dictionary
  static String _buildCookieHeader(Map<String, String> cookieDict) {
    return cookieDict.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Extract build_id dari HTML Netflix /browse
  static String? _extractBuildId(String html) {
    // Pattern 1: apiUrl
    final apiUrlMatch = RegExp(r'"apiUrl":"https://www\.netflix\.com/api/shakti/([^/]+)/"').firstMatch(html);
    if (apiUrlMatch != null) return apiUrlMatch.group(1);

    // Pattern 2: BUILD_IDENTIFIER
    final buildMatch = RegExp(r'BUILD_IDENTIFIER\s*=\s*"([^"]+)"').firstMatch(html);
    if (buildMatch != null) return buildMatch.group(1);

    // Pattern 3: shakti path
    final shaktiMatch = RegExp(r'/api/shakti/([A-Za-z0-9_\-]+)/').firstMatch(html);
    if (shaktiMatch != null) return shaktiMatch.group(1);

    return null;
  }

  /// Fetch membership data via pathEvaluator API
  static Future<Map<String, dynamic>> _fetchMembershipData(
    String buildId,
    Map<String, String> headers,
  ) async {
    Map<String, dynamic> data = {};

    try {
      // pathEvaluator untuk ambil userInfo termasuk payment/hold status
      final peHeaders = Map<String, String>.from(headers);
      peHeaders['Content-Type'] = 'application/x-www-form-urlencoded';

      final peResp = await http.post(
        Uri.parse('https://www.netflix.com/api/shakti/$buildId/pathEvaluator'),
        headers: peHeaders,
        body: {
          'path':
              '["memberContext","userInfo",["userGuid","email","phoneNumber","countryOfSignup","membershipStatus","planTier","planName","localizedPlanName","planBundle","nextBillingDate","memberSince","isOnHold","onHold","hasPaymentOnFile","membershipState","isUserOnHold","isInDunning","hasFailedPayment","paymentFailed","paymentDeclined","isPaymentDeclined","paymentMethodRequired","pastDue","hasService","serviceEndReason","retryEligibility"]]',
        },
      ).timeout(const Duration(seconds: 12));

      if (peResp.statusCode == 200) {
        final peData = jsonDecode(peResp.body);
        final userInfo = peData?['value']?['memberContext']?['userInfo'];
        if (userInfo is Map<String, dynamic>) {
          final keysToExtract = [
            'planTier', 'planName', 'localizedPlanName', 'membershipStatus',
            'membershipState', 'email', 'phoneNumber', 'countryOfSignup',
            'nextBillingDate', 'memberSince', 'isOnHold', 'onHold',
            'hasPaymentOnFile', 'isUserOnHold', 'hasFailedPayment',
            'paymentFailed', 'paymentDeclined', 'isPaymentDeclined',
            'paymentMethodRequired', 'pastDue', 'isInDunning', 'hasService',
            'serviceEndReason', 'retryEligibility', 'dunning',
          ];
          for (final key in keysToExtract) {
            if (userInfo.containsKey(key)) {
              data[key] = userInfo[key];
            }
          }
        }
      }
    } catch (_) {}

    // Coba juga membership/status endpoint
    try {
      final statusResp = await http.get(
        Uri.parse('https://www.netflix.com/api/shakti/$buildId/membership/status'),
        headers: headers,
      ).timeout(const Duration(seconds: 12));

      if (statusResp.statusCode == 200) {
        final statusData = jsonDecode(statusResp.body);
        if (statusData is Map<String, dynamic>) {
          for (final entry in statusData.entries) {
            if (!data.containsKey(entry.key)) {
              data[entry.key] = entry.value;
            }
          }
        }
      }
    } catch (_) {}

    return data;
  }

  /// Extract data dari netflix.reactContext di halaman /account
  static void _extractReactContextData(String html, Map<String, dynamic> membershipData) {
    try {
      final rcMatch = RegExp(
        r'netflix\.reactContext\s*=\s*(\{.+?\});\s*</script>',
        dotAll: true,
      ).firstMatch(html);

      if (rcMatch == null) return;

      final rcRaw = rcMatch.group(1)!;
      // Decode unicode escapes
      final decoded = _decodeUnicodeEscapes(rcRaw);
      final rcJson = jsonDecode(decoded) as Map<String, dynamic>?;
      if (rcJson == null) return;

      // userInfo dari models
      final userInfo = rcJson['models']?['userInfo']?['data'];
      if (userInfo is Map<String, dynamic>) {
        for (final key in ['membershipStatus', 'email', 'countryOfSignup', 'currentCountry', 'memberSince']) {
          if (userInfo.containsKey(key) && userInfo[key] != null && !membershipData.containsKey(key)) {
            membershipData[key] = userInfo[key];
          }
        }
        if (!membershipData.containsKey('countryOfSignup') && userInfo['currentCountry'] != null) {
          membershipData['countryOfSignup'] = userInfo['currentCountry'];
        }
      }

      // signupContext -> flow -> fields
      final signupCtx = rcJson['models']?['signupContext']?['data'];
      if (signupCtx is Map<String, dynamic>) {
        final flowFields = signupCtx['flow']?['fields'];
        if (flowFields is Map<String, dynamic>) {
          for (final k in ['hasService', 'isPaused', 'nextBillingDate', 'memberSince']) {
            if (flowFields.containsKey(k) && !membershipData.containsKey(k)) {
              membershipData[k] = flowFields[k];
            }
          }
          // Payment methods check
          final payMethods = flowFields['paymentMethods'];
          if (payMethods is List && payMethods.isNotEmpty) {
            membershipData['hasPaymentOnFile'] = true;
          } else if (!membershipData.containsKey('hasPaymentOnFile')) {
            membershipData['hasPaymentOnFile'] = false;
          }
        }
      }

      // GraphQL models -> growthHoldMetadata
      final graphqlModels = rcJson['models']?['graphql']?['data'];
      if (graphqlModels is Map<String, dynamic>) {
        for (final gqlVal in graphqlModels.values) {
          if (gqlVal is! Map<String, dynamic>) continue;
          final gqlData = gqlVal['data'] ?? gqlVal;
          if (gqlData is! Map<String, dynamic>) continue;

          final ghm = gqlData['growthHoldMetadata'];
          if (ghm is Map<String, dynamic>) {
            if (ghm['isUserOnHold'] == true) {
              membershipData['isUserOnHold'] = true;
            } else if (!membershipData.containsKey('isUserOnHold')) {
              membershipData['isUserOnHold'] = ghm['isUserOnHold'] ?? false;
            }
            // retryEligibility
            if (ghm.containsKey('retryEligibility') && !membershipData.containsKey('retryEligibility')) {
              membershipData['retryEligibility'] = ghm['retryEligibility'];
            }
            // serviceEndReason
            if (ghm.containsKey('serviceEndReason') && !membershipData.containsKey('serviceEndReason')) {
              membershipData['serviceEndReason'] = ghm['serviceEndReason'];
            }
          }

          final gqlMs = gqlData['membershipStatus'];
          if (gqlMs != null && !membershipData.containsKey('membershipStatus')) {
            membershipData['membershipStatus'] = gqlMs;
          }
        }
      }
    } catch (_) {}
  }

  /// Decode unicode escape sequences in a string
  static String _decodeUnicodeEscapes(String input) {
    return input.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
  }

  /// Ekstrak teks yang terlihat dari HTML, strip <script>, <style>, <noscript>, <template>.
  /// Port dari extract_visible_detection_text() di ntfvalid.py.
  /// Ini penting agar keyword di dalam script/style/navigation JSON tidak memicu false positive.
  static String _extractVisibleText(String html) {
    if (!html.contains('<') || !html.contains('>')) return html;

    String cleaned = html;
    // Hapus tag script, style, noscript, template beserta isinya
    for (final tag in ['script', 'style', 'noscript', 'template']) {
      cleaned = cleaned.replaceAll(
        RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
        ' ',
      );
    }
    // Hapus semua HTML tags yang tersisa
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Decode HTML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  // ==================== PAYMENT STATUS DETECTION ====================
  // Port dari detect_payment_status() di ntfvalid.py

  /// Deteksi payment status berdasarkan JSON data dan HTML text.
  /// Mengembalikan [AccountValidationResult].
  static AccountValidationResult _detectPaymentStatus(
    String htmlText,
    Map<String, dynamic> jsonData,
  ) {
    // ---- JSON-based detection (paling akurat) ----
    if (jsonData.isNotEmpty) {
      // Cek membershipStatus / membershipState
      final mhs = (jsonData['membershipStatus'] ?? jsonData['membershipState'] ?? '').toString().toLowerCase();

      if (mhs.isNotEmpty) {
        // NEVER_MEMBER
        if (mhs.contains('never_member') || mhs.contains('never member') || mhs.contains('anonymous')) {
          return AccountValidationResult.noPayment(data: jsonData);
        }
        // FORMER_MEMBER / CANCELED / EXPIRED
        if (mhs.contains('former') || mhs.contains('cancel') || mhs.contains('offboard') ||
            mhs.contains('inactive') || mhs.contains('expired')) {
          return AccountValidationResult.canceled(data: jsonData);
        }
        // ON_HOLD
        if (mhs.contains('hold') || mhs.contains('on_hold')) {
          return AccountValidationResult.onHold('', data: jsonData);
        }
        // PENDING
        if (mhs.contains('pending')) {
          return AccountValidationResult.pending(data: jsonData);
        }
        // FREE TRIAL
        if (mhs.contains('trial') || mhs.contains('freeloader')) {
          return AccountValidationResult.freeTrial(data: jsonData);
        }
        // CURRENT_MEMBER / ACTIVE / PAID
        if (mhs.contains('current') || mhs.contains('active') || mhs.contains('paid')) {
          // Cek apakah isUserOnHold = true (meskipun CURRENT_MEMBER)
          if (jsonData['isUserOnHold'] == true) {
            return AccountValidationResult.onHold('', data: jsonData);
          }
          if (jsonData['hasService'] == false) {
            return AccountValidationResult.onHold('Layanan Tidak Aktif', data: jsonData);
          }
          return AccountValidationResult.paid(data: jsonData);
        }
      }

      // Cek isUserOnHold dari GraphQL growthHoldMetadata
      if (jsonData['isUserOnHold'] == true) {
        return AccountValidationResult.onHold('', data: jsonData);
      }
      if (jsonData['isOnHold'] == true) {
        return AccountValidationResult.onHold('', data: jsonData);
      }
      if (jsonData['hasFailedPayment'] == true) {
        return AccountValidationResult.onHold('', data: jsonData);
      }

      // Cek berbagai flag payment failed
      for (final holdKey in [
        'paymentFailed', 'paymentDeclined', 'isPaymentDeclined',
        'paymentMethodRequired', 'dunning', 'isInDunning', 'pastDue',
      ]) {
        if (jsonData[holdKey] == true) {
          return AccountValidationResult.onHold('', data: jsonData);
        }
      }

      // serviceEndReason - jika bukan UNSET, ada masalah
      final ser = (jsonData['serviceEndReason'] ?? '').toString();
      if (ser.isNotEmpty && !ser.toLowerCase().contains('unset') && ser.trim().isNotEmpty) {
        return AccountValidationResult.onHold('Service End: $ser', data: jsonData);
      }

      // retryEligibility - jika ada dan bukan NOT_ELIGIBLE
      final retryElig = (jsonData['retryEligibility'] ?? '').toString();
      if (retryElig.isNotEmpty && retryElig != 'NOT_ELIGIBLE' &&
          retryElig.toLowerCase().contains('eligible')) {
        return AccountValidationResult.onHold('Retry Payment Required', data: jsonData);
      }

      // Jika JSON data ada tapi tidak ada indikasi masalah, dan ada hasService/hasPaymentOnFile
      // maka bisa dianggap PAID
      if (jsonData['hasService'] == true || jsonData['hasPaymentOnFile'] == true) {
        return AccountValidationResult.paid(data: jsonData);
      }
    }

    // ---- HTML-based detection ----
    // PENTING: Gunakan _extractVisibleText() untuk strip script/style/noscript/template
    // agar keyword di dalam JavaScript/CSS/JSON translation catalogs tidak memicu false positive.
    // Ini port dari extract_visible_detection_text() di ntfvalid.py.
    if (htmlText.isEmpty) {
      return AccountValidationResult.unknown(data: jsonData);
    }

    final visibleText = _extractVisibleText(htmlText);
    final low = visibleText.toLowerCase();

    // Never Member detection
    final neverMemberKw = [
      'finish signing up to watch',
      'start membership',
      '"memberstatus":"never_member"',
      '"membershipstatus":"never_member"',
      'never_member',
      'account-never-member-page',
      'selesaikan pendaftaran',
      'mulai keanggotaan',
    ];
    int neverMemberHits = 0;
    for (final k in neverMemberKw) {
      if (low.contains(k)) neverMemberHits++;
    }
    if (neverMemberHits >= 2) {
      return AccountValidationResult.noPayment(data: jsonData);
    }

    // Multilingual payment issue text detection (hanya strongClues, tanpa combined check)
    if (_hasMultilingualPaymentIssueText(low)) {
      return AccountValidationResult.onHold('', data: jsonData);
    }

    // ON HOLD keywords (multi-bahasa) - frasa spesifik yang jelas menunjukkan masalah
    final onHoldKw = [
      'your membership is on hold',
      'membership is on hold',
      "we couldn't process",
      'we were unable to process',
      'we could not process',
      "couldn't validate your payment",
      'we cannot process your payment',
      "we can't process your payment",
      'cannot process your payment',
      "can't process your payment",
      'unable to process your payment',
      'failed to process your payment',
      'payment could not be processed',
      "payment couldn't be processed",
      'payment processing failed',
      'payment was declined',
      'payment declined',
      'card was declined',
      'card declined',
      'transaction failed',
      'transaction was declined',
      'payment_method_required',
      'billing issue',
      'billing problem',
      'payment issue',
      'payment problem',
      'your account is on hold',
      'account is on hold',
      "there's a problem with your payment",
      'there is a problem with your payment',
      'problem with your payment method',
      'issue with your payment method',
      'payment method failed',
      'payment method error',
      'payment unsuccessful',
      'unsuccessful payment',
      // Indonesia
      'akun anda ditahan',
      'kami tidak dapat memproses pembayaran',
      'keanggotaan anda ditangguhkan',
      'pembayaran gagal',
      'pembayaran tidak berhasil',
      'pembayaran tidak valid',
      // Vietnam
      'đang bị tạm ngưng',
      'chúng tôi không thể xử lý khoản thanh toán',
      'không thể xử lý khoản thanh toán',
      // Portugis
      'sua assinatura está suspensa',
      'não foi possível processar',
      'não conseguimos processar',
      'problema com o pagamento',
      // Spanyol
      'tu membresía está suspendida',
      'no pudimos procesar',
      'no hemos podido procesar',
      'problema con el pago',
      'no podemos procesar tu pago',
      // Prancis
      'votre abonnement est suspendu',
      "nous n'avons pas pu traiter",
      'impossible de traiter votre paiement',
      'problème de paiement',
      // Jerman
      'ihre mitgliedschaft ist gesperrt',
      'wir konnten ihre zahlung nicht verarbeiten',
      'zahlungsproblem',
      // Italia
      'il tuo abbonamento è sospeso',
      'non siamo riusciti a elaborare',
      'problema con il pagamento',
      'non possiamo elaborare il pagamento',
      // Turki
      'üyeliğiniz askıya alındı',
      'ödemenizi işleyemedik',
      'ödeme sorunu',
      // Belanda
      'je lidmaatschap is opgeschort',
      'we konden je betaling niet verwerken',
      // Polandia
      'twoje członkostwo jest zawieszone',
      'nie udało się przetworzyć',
    ];

    for (final k in onHoldKw) {
      if (low.contains(k)) {
        return AccountValidationResult.onHold('', data: jsonData);
      }
    }

    // Pending payment keywords
    final pendingKw = [
      'payment is pending',
      'payment pending',
      'pending payment',
      'payment_failed',
      'retrypaymentmethod',
      'pembayaran tertunda',
      'pembayaran sedang diproses',
      'pagamento pendente',
      'pago pendiente',
      'paiement en attente',
      'zahlung ausstehend',
      'pagamento in sospeso',
      'ödeme beklemede',
    ];
    for (final k in pendingKw) {
      if (low.contains(k)) {
        return AccountValidationResult.pending(data: jsonData);
      }
    }

    // No payment method keywords
    final noPayKw = [
      'add a payment method',
      'no payment method',
      'select a plan to start',
      'tambahkan metode pembayaran',
      'adicione uma forma de pagamento',
      'nenhuma forma de pagamento',
      'agrega un método de pago',
      'no hay método de pago',
      'ajoutez un mode de paiement',
      'aucun mode de paiement',
      'zahlungsmethode hinzufügen',
      'keine zahlungsmethode',
      'aggiungi un metodo di pagamento',
      'nessun metodo di pagamento',
      'ödeme yöntemi ekleyin',
    ];
    for (final k in noPayKw) {
      if (low.contains(k)) {
        return AccountValidationResult.noPayment(data: jsonData);
      }
    }

    // Canceled keywords
    final canceledKw = [
      'your membership has been canceled',
      'membership canceled',
      'membership has ended',
      'membership_canceled',
      'restart your membership',
      'restartmembership',
      'akun anda telah dibatalkan',
      'keanggotaan dibatalkan',
      'keanggotaanmu telah dibatalkan',
      'keanggotaanmu telah berakhir',
      'mulai ulang keanggotaan',
      'sua assinatura foi cancelada',
      'assinatura cancelada',
      'tu membresía ha sido cancelada',
      'membresía cancelada',
      'votre abonnement a été annulé',
      'abonnement annulé',
      'ihre mitgliedschaft wurde gekündigt',
      'mitgliedschaft gekündigt',
      'il tuo abbonamento è stato cancellato',
      'abbonamento cancellato',
      'üyeliğiniz iptal edildi',
      'üyelik iptal edildi',
    ];
    for (final k in canceledKw) {
      if (low.contains(k)) {
        return AccountValidationResult.canceled(data: jsonData);
      }
    }

    // Free trial keywords
    final freeTrialKw = [
      'free trial',
      'uji coba gratis',
      'período de teste grátis',
      'teste grátis',
      'prueba gratuita',
      'periodo de prueba',
      'essai gratuit',
      "période d'essai",
      'kostenlose testphase',
      'gratis testen',
      'prova gratuita',
      'periodo di prova',
      'ücretsiz deneme',
    ];
    if (freeTrialKw.any((k) => low.contains(k))) {
      return AccountValidationResult.freeTrial(data: jsonData);
    }

    // Positive paid indicators
    final paidKw = [
      'next billing',
      'your next payment',
      'payment due',
      'tagihan berikutnya',
      'próxima cobrança',
      'próximo pagamento',
      'próxima facturación',
      'próximo pago',
      'prochaine facturation',
      'prochain paiement',
      'nächste abrechnung',
      'nächste zahlung',
      'prossima fatturazione',
      'prossimo pagamento',
      'sonraki fatura',
      'sonraki ödeme',
    ];
    if (paidKw.any((k) => low.contains(k))) {
      return AccountValidationResult.paid(data: jsonData);
    }

    return AccountValidationResult.unknown(data: jsonData);
  }

  /// Deteksi payment issue dari teks multilingual (HANYA strong clues).
  /// Port dari has_multilingual_payment_issue_text() di ntfvalid.py.
  ///
  /// PERBAIKAN: Hapus combined paymentTerms+issueTerms check yang menyebabkan
  /// false positive. Kata generik seperti "payment", "billing", "hold", "cancel"
  /// muncul di halaman Netflix normal (navigasi, menu, label).
  /// Hanya gunakan strongClues - frasa spesifik multi-kata yang jelas menunjukkan masalah.
  static bool _hasMultilingualPaymentIssueText(String lowText) {
    final strongClues = [
      // API/Netflix-style identifiers
      'on_hold', 'onhold', 'payment_failed', 'paymentfailed', 'failedpayment',
      'payment_declined', 'paymentdeclined', 'payment_method_required',
      'paymentmethodrequired', 'retry_payment', 'retrypayment', 'retrypaymentmethod',
      'growthholdmetadata', 'dunning', 'past_due', 'pastdue',
      // English explicit failure/hold
      'membership is on hold', 'account is on hold', 'your account is on hold',
      "couldn't process your payment", 'could not process your payment',
      'cannot process your payment', "can't process your payment",
      'unable to process your payment', 'payment was declined', 'card declined',
      'payment processing failed', 'problem with your payment method',
      'there is a problem with your payment', "there's a problem with your payment",
      // Indonesia / Melayu
      'akun anda ditahan', 'akun anda ditangguhkan', 'keanggotaan ditahan',
      'keanggotaan ditangguhkan', 'kami tidak dapat memproses pembayaran',
      'pembayaran gagal', 'pembayaran ditolak', 'masalah pembayaran', 'coba pembayaran lagi',
      // Vietnam (accent-stripped)
      'tai khoan cua ban dang bi tam ngung', 'dang bi tam ngung',
      'chung toi khong the xu ly khoan thanh toan',
      'khong the xu ly khoan thanh toan', 'thu thanh toan lai',
      // Spanish / Portuguese / French / Italian / German
      'membresia esta suspendida', 'no pudimos procesar', 'no podemos procesar tu pago',
      'problema con el pago',
      'assinatura esta suspensa', 'nao foi possivel processar', 'nao conseguimos processar',
      'problema com o pagamento',
      'abonnement est suspendu', 'impossible de traiter votre paiement',
      'nous ne pouvons pas traiter votre paiement', 'ne pouvons pas traiter votre paiement',
      "nous n'avons pas pu traiter votre paiement", 'probleme de paiement',
      'abbonamento e sospeso', 'non siamo riusciti a elaborare',
      'problema con il pagamento',
      'mitgliedschaft ist gesperrt', 'zahlung nicht verarbeiten', 'zahlungsproblem',
      // Turkish / Dutch / Polish / Romanian / Czech / Nordic
      'uyeliginiz askiya alindi', 'odemenizi isleyemedik', 'odeme sorunu',
      'lidmaatschap is opgeschort', 'betaling niet verwerken',
      'czlonkostwo jest zawieszone', 'nie udalo sie przetworzyc',
      'abonamentul este suspendat', 'nu am putut procesa plata',
      'clenstvi je pozastaveno', 'platbu se nepodarilo zpracovat',
      'medlemskapet er satt pa pause', 'betalingen kunne ikke behandles',
      'medlemskapet ar pausat', 'betalningen kunde inte behandlas',
      'jasenyys on keskeytetty', 'maksua ei voitu kasitella',
      // CJK + Thai + Arabic + Hebrew + Russian + Greek + Hindi
      '会员资格已暂停', '无法处理付款',
      '會員資格已暫停', '無法處理付款',
      'お支払いを処理できません',
      '결제를 처리할 수 없',
      'ไม่สามารถดำเนินการชำระเงิน',
      'عضويتك معلقة', 'لم نتمكن من معالجة',
      'החברות מושעית', 'לא הצלחנו לעבד את התשלום',
      'Подписка приостановлена', 'не удалось обработать платеж',
      'η συνδρομή σας έχει ανασταλεί',
      'भुगतान प्रोसेस नहीं कर सके',
    ];

    // HANYA gunakan strongClues - frasa spesifik yang jelas menunjukkan payment issue.
    // TIDAK menggunakan combined paymentTerms+issueTerms karena terlalu broad
    // dan menyebabkan false positive pada halaman Netflix normal.
    return strongClues.any((clue) => lowText.contains(clue));
  }
}
