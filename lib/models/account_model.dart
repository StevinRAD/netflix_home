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

  factory CookieAccount.fromRawText(String rawText, {String id = '1', String filename = 'Akun Valid Elloe'}) {
    String email = 'Unknown';
    String phone = 'Unknown';
    String country = 'Indonesia 🇮🇩';
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
              if (val.toUpperCase() == 'ID') {
                country = 'Indonesia 🇮🇩';
              } else {
                country = val;
              }
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
      country: _cleanUtf8(json['country'] ?? 'Indonesia 🇮🇩'),
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
