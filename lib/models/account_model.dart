class CookieAccount {
  final String id;
  final String filename;
  final String cookieContent;
  final String email;
  final String phone;
  final String country;
  final String planName;
  final String videoQuality;
  final int maxStreams;
  final String paymentStatus;
  final String paymentMethod;
  final String memberSince;
  final String nextBilling;
  final String status; // 'LIVE', 'EXPIRED', 'UNCHECKED'
  final DateTime createdAt;
  String? lastNftoken;

  CookieAccount({
    required this.id,
    required this.filename,
    required this.cookieContent,
    this.email = 'Unknown',
    this.phone = 'Unknown',
    this.country = 'Indonesia 🇮🇩',
    this.planName = 'Premium',
    this.videoQuality = '4K + HDR',
    this.maxStreams = 4,
    this.paymentStatus = '✅ Aktif & Terbayar',
    this.paymentMethod = 'Credit Card ****1234',
    this.memberSince = 'Jan 2023',
    this.nextBilling = '15 Oct 2026',
    this.status = 'LIVE',
    DateTime? createdAt,
    this.lastNftoken,
  }) : createdAt = createdAt ?? DateTime.now();

  static String _cleanUtf8(String str) {
    if (str.isEmpty) return str;
    return str
        .replaceAll('âœ…', '✅')
        .replaceAll('â Œ', '❌')
        .replaceAll('â', '')
        .replaceAll('Ã', '')
        .trim();
  }

  static final Map<String, String> countryNames = {
    'ID': 'Indonesia 🇮🇩',
    'SG': 'Singapura 🇸🇬',
    'MY': 'Malaysia 🇲🇾',
    'PH': 'Filipina 🇵🇭',
    'TH': 'Thailand 🇹🇭',
    'IN': 'India 🇮🇳',
    'US': 'United States 🇺🇸',
    'GB': 'Inggris 🇬🇧',
    'AU': 'Australia 🇦🇺',
    'JP': 'Jepang 🇯🇵',
    'KR': 'Korea 🇰🇷',
    'BR': 'Brasil 🇧🇷',
    'AR': 'Argentina 🇦🇷',
    'TR': 'Turki 🇹🇷',
    'DE': 'Jerman 🇩🇪',
    'FR': 'Prancis 🇫🇷',
    'IT': 'Italia 🇮🇹',
    'ES': 'Spanyol 🇪🇸',
    'CA': 'Kanada 🇨🇦',
    'VN': 'Vietnam 🇻🇳',
  };

  static final Map<String, String> countryKeywords = {
    'ID': 'ID',
    'INDONESIA': 'ID',
    'INDO': 'ID',
    'IDN': 'ID',
    'SG': 'SG',
    'SINGAPORE': 'SG',
    'SINGAPURA': 'SG',
    'SGP': 'SG',
    'MY': 'MY',
    'MALAYSIA': 'MY',
    'MYS': 'MY',
    'IN': 'IN',
    'INDIA': 'IN',
    'IND': 'IN',
    'HINDI': 'IN',
    'US': 'US',
    'USA': 'US',
    'AMERIKA': 'US',
    'UNITED STATES': 'US',
    'PH': 'PH',
    'PHILIPPINES': 'PH',
    'FILIPINA': 'PH',
    'PHL': 'PH',
    'TH': 'TH',
    'THAILAND': 'TH',
    'AU': 'AU',
    'AUSTRALIA': 'AU',
    'AUS': 'AU',
    'GB': 'GB',
    'UK': 'GB',
    'INGGRIS': 'GB',
    'ENGLAND': 'GB',
    'BR': 'BR',
    'BRAZIL': 'BR',
    'BRASIL': 'BR',
    'AR': 'AR',
    'ARGENTINA': 'AR',
    'TR': 'TR',
    'TURKI': 'TR',
    'TURKEY': 'TR',
    'TURKIYE': 'TR',
    'JP': 'JP',
    'JAPAN': 'JP',
    'JEPANG': 'JP',
    'KR': 'KR',
    'KOREA': 'KR',
    'DE': 'DE',
    'GERMANY': 'DE',
    'JERMAN': 'DE',
    'FR': 'FR',
    'FRANCE': 'FR',
    'PRANCIS': 'FR',
    'IT': 'IT',
    'ITALY': 'IT',
    'ITALIA': 'IT',
    'ES': 'ES',
    'SPAIN': 'ES',
    'SPANYOL': 'ES',
    'CA': 'CA',
    'CANADA': 'CA',
    'KANADA': 'CA',
    'VN': 'VN',
    'VIETNAM': 'VN',
    'RU': 'RU',
    'RUSSIA': 'RU',
    'RUSIA': 'RU',
    'MX': 'MX',
    'MEXICO': 'MX',
    'MEKSIKO': 'MX',
  };

  static String? detectCountryCode(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;
    // If input contains @ or . or is a URL, it's an email or link, not a country search
    if (clean.contains('@') || clean.contains('.') || clean.toLowerCase().startsWith('http')) {
      return null;
    }
    final upper = clean.toUpperCase();
    if (countryKeywords.containsKey(upper)) {
      return countryKeywords[upper];
    }
    return null;
  }

  static String formatCountry(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'Indonesia 🇮🇩';
    final upper = clean.toUpperCase();
    if (countryNames.containsKey(upper)) {
      return countryNames[upper]!;
    }
    return clean;
  }

  String get formattedCountry => formatCountry(country);

  String get countryCode {
    final clean = country.trim().toUpperCase();
    if (clean.length == 2 && countryNames.containsKey(clean)) return clean;
    for (final entry in countryKeywords.entries) {
      if (clean == entry.key || clean.contains(entry.key)) {
        return entry.value;
      }
    }
    return clean.length >= 2 ? clean.substring(0, 2) : clean;
  }

  /// Priority score: Lower means higher priority in the account list
  int get regionPriority {
    final code = countryCode;
    switch (code) {
      case 'ID': return 0; // Top 1: Indonesia
      case 'SG': return 1; // Top 2: Singapore
      case 'MY': return 2; // Top 3: Malaysia
      case 'PH': return 3; // Top 4: Philippines
      case 'TH': return 4; // Top 5: Thailand
      case 'IN': return 5; // Top 6: India
      case 'US': return 6; // Top 7: USA
      default: return 99; // Other countries
    }
  }

  factory CookieAccount.fromRawText(String rawText, {String id = '1', String filename = 'Akun Valid Elloe'}) {
    String email = 'Unknown';
    String phone = 'Unknown';
    String country = 'ID';
    String planName = 'Basic';
    String videoQuality = '720p HD';
    int maxStreams = 1;
    String paymentStatus = '✅ Aktif & Terbayar';
    String paymentMethod = 'Unknown';
    String memberSince = '30 Oct 2024';
    String nextBilling = 'Unknown';
    String status = 'LIVE';

    final lines = rawText.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# NTFINFO:')) {
        final content = trimmed.substring('# NTFINFO:'.length).trim();
        final colonIdx = content.indexOf(':');
        if (colonIdx != -1) {
          final key = content.substring(0, colonIdx).trim().toLowerCase();
          final val = _cleanUtf8(content.substring(colonIdx + 1).trim());

          switch (key) {
            case 'email':
              email = val;
              break;
            case 'phone':
              phone = val;
              break;
            case 'country':
              country = val.trim().toUpperCase();
              break;
            case 'plan':
              planName = val;
              break;
            case 'quality':
              videoQuality = val;
              break;
            case 'max streams':
              maxStreams = int.tryParse(val) ?? 1;
              break;
            case 'payment status':
              paymentStatus = val;
              break;
            case 'payment method':
              paymentMethod = val;
              break;
            case 'since':
              memberSince = val;
              break;
            case 'next billing':
              nextBilling = val;
              break;
          }
        }
      }
    }

    return CookieAccount(
      id: id,
      filename: filename,
      cookieContent: rawText,
      email: email,
      phone: phone,
      country: country,
      planName: planName,
      videoQuality: videoQuality,
      maxStreams: maxStreams,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      memberSince: memberSince,
      nextBilling: nextBilling,
      status: status,
    );
  }

  factory CookieAccount.fromJson(Map<String, dynamic> json) {
    return CookieAccount(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] ?? json['name'] ?? 'cookie_account.txt',
      cookieContent: json['cookie_content'] ?? json['content'] ?? '',
      email: _cleanUtf8(json['email'] ?? 'Unknown'),
      phone: _cleanUtf8(json['phone'] ?? 'Unknown'),
      country: _cleanUtf8(json['country'] ?? 'ID'),
      planName: _cleanUtf8(json['plan_name'] ?? 'Premium'),
      videoQuality: _cleanUtf8(json['video_quality'] ?? '4K + HDR'),
      maxStreams: json['max_streams'] != null ? int.tryParse(json['max_streams'].toString()) ?? 4 : 4,
      paymentStatus: _cleanUtf8(json['payment_status'] ?? '✅ Aktif & Terbayar'),
      paymentMethod: _cleanUtf8(json['payment_method'] ?? 'Credit Card ****1234'),
      memberSince: _cleanUtf8(json['member_since'] ?? 'Jan 2023'),
      nextBilling: _cleanUtf8(json['next_billing'] ?? '15 Oct 2026'),
      status: _cleanUtf8(json['status'] ?? 'LIVE'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : DateTime.now(),
      lastNftoken: json['nftoken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'cookie_content': cookieContent,
      'email': email,
      'phone': phone,
      'country': country,
      'plan_name': planName,
      'video_quality': videoQuality,
      'max_streams': maxStreams,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'member_since': memberSince,
      'next_billing': nextBilling,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'nftoken': lastNftoken,
    };
  }
}
