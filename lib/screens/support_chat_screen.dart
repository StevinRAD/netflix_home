import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_chat_service.dart';

class SupportChatScreen extends StatefulWidget {
  final String? initialMessage;
  const SupportChatScreen({super.key, this.initialMessage});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _userId;
  String? _userName;
  bool _isLoading = true;

  Timer? _inactivityTimer;
  bool _showEndSession = false;
  bool _isTyping = false;
  bool _isWaitingForAdmin = false;

  late AnimationController _dotAnimController;

  // === AI MODE ===
  bool _isAiMode = true; // Default: AI menjawab
  bool _aiAvailable = false;
  bool _isAiThinking = false;
  final List<Map<String, dynamic>> _localMessages = [];
  final List<Map<String, String>> _conversationHistory = [];

  // Fitur Chat Cepat
  final List<String> _quickReplies = [
    "Akun saya tidak bisa login",
    "Bagaimana cara perpanjang?",
    "Password salah",
    "Minta reset perangkat",
    "Screen limit penuh",
  ];

  @override
  void initState() {
    super.initState();
    _initUser();

    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _messageController.addListener(() {
      final isTypingNow = _messageController.text.isNotEmpty;
      if (_isTyping != isTypingNow) {
        setState(() => _isTyping = isTypingNow);
      }
      _resetInactivityTimer();
    });

    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _dotAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_showEndSession) {
      setState(() => _showEndSession = false);
    }

    _inactivityTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_isTyping && !_isWaitingForAdmin && !_isAiThinking) {
        setState(() => _showEndSession = true);
      }
    });
  }

  Future<void> _endSession() async {
    if (_userId == null) return;
    // Removed Supabase delete() to preserve history
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('session_user_id');
    _userName = prefs.getString('session_username') ?? 'Pengguna';

    if (_userId == null || _userId!.isEmpty) {
      _userId = prefs.getString('session_device_id') ??
          'anon_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Cek AI availability
    _aiAvailable = await AiChatService.isAvailable();

    setState(() {
      _isLoading = false;
    });

    // Kirim pesan sambutan otomatis
    _addWelcomeMessage();

    // Jika ada initial message (misal dari pencarian FAQ), masukkan ke teks input tanpa langsung terkirim
    if (widget.initialMessage != null &&
        widget.initialMessage!.isNotEmpty) {
      _messageController.text = widget.initialMessage!;
    }
  }

  void _addWelcomeMessage() {
    final welcomeText = AiChatService.getWelcomeMessage(_userName ?? 'Pengguna');
    setState(() {
      _localMessages.add({
        'message': welcomeText,
        'is_from_admin': true,
        'is_ai': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _userId == null || _isAiThinking) return;

    final message = text.trim();
    _messageController.clear();

    if (_isAiMode) {
      await _sendAiMessage(message);
    } else {
      await _sendAdminMessage(message);
    }
  }

  /// Kirim pesan dalam mode AI
  Future<void> _sendAiMessage(String message) async {
    // Tambahkan pesan user ke local
    setState(() {
      _localMessages.add({
        'message': message,
        'is_from_admin': false,
        'is_ai': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isAiThinking = true;
    });
    _conversationHistory.add({'role': 'user', 'content': message});
    _scrollToBottom();

    String? aiResponse;

    if (_aiAvailable) {
      // Coba kirim ke AI
      aiResponse = await AiChatService.sendMessage(
        userMessage: message,
        conversationHistory: _conversationHistory,
      );
    }

    // Jika AI gagal, coba fallback
    if (aiResponse == null) {
      // Re-check availability
      _aiAvailable = await AiChatService.isAvailable();

      if (!_aiAvailable) {
        // Server down → fallback pertanyaan umum
        aiResponse = AiChatService.getFallbackAnswer(message);
        aiResponse ??= AiChatService.getDefaultFallback();
      } else {
        // Server up tapi gagal → default fallback
        aiResponse = AiChatService.getDefaultFallback();
      }
    }

    // Tambahkan response AI
    _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

    if (mounted) {
      setState(() {
        _localMessages.add({
          'message': aiResponse,
          'is_from_admin': true,
          'is_ai': true,
          'created_at': DateTime.now().toIso8601String(),
        });
        _isAiThinking = false;
      });
      _resetInactivityTimer();
      _scrollToBottom();
    }
  }

  /// Kirim pesan dalam mode Admin (via Supabase)
  Future<void> _sendAdminMessage(String message) async {
    try {
      await Supabase.instance.client.from('support_chats').insert({
        'user_id': _userId,
        'user_name': _userName,
        'message': message,
        'is_from_admin': false,
        'is_read': false,
      });
      setState(() => _isWaitingForAdmin = true);
      _resetInactivityTimer();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _messageController.text = message; // Restore draft
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  /// Alihkan ke mode Admin
  void _switchToAdminMode() {
    setState(() {
      _isAiMode = false;
    });

    // Kirim pesan notifikasi ke admin via Supabase
    _sendAdminMessage(
        '[Dialihkan dari AI Bot] — Pengguna meminta bantuan admin langsung.');

    // Tambahkan pesan lokal info
    setState(() {
      _localMessages.add({
        'message':
            '🔄 Anda telah dialihkan ke admin CS manusia.\n\nPesan Anda selanjutnya akan diterima langsung oleh admin. Mohon tunggu balasan dari tim kami.',
        'is_from_admin': true,
        'is_ai': true,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  /// Kembali ke mode AI
  void _switchToAiMode() async {
    _aiAvailable = await AiChatService.isAvailable();
    setState(() {
      _isAiMode = true;
    });

    setState(() {
      _localMessages.add({
        'message':
            '🤖 Anda kembali ke mode AI Assistant.\nSilakan tanyakan apa saja!',
        'is_from_admin': true,
        'is_ai': true,
        'is_system': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  String _formatDateSeparator(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dt.year, dt.month, dt.day);

      if (messageDate == today) return 'Hari ini';
      if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Kemarin';
      }

      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDateSeparator(
      List<Map<String, dynamic>> messages, int index) {
    if (index == 0) return true;
    try {
      final current = DateTime.parse(messages[index]['created_at']).toLocal();
      final previous =
          DateTime.parse(messages[index - 1]['created_at']).toLocal();
      return current.day != previous.day ||
          current.month != previous.month ||
          current.year != previous.year;
    } catch (_) {
      return false;
    }
  }

  Widget _buildAdminAvatar({bool isAi = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAi
              ? [const Color(0xFF6C5CE7), const Color(0xFF5241B5)]
              : [const Color(0xFFE50914), const Color(0xFFB20710)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isAi
                    ? const Color(0xFF6C5CE7)
                    : const Color(0xFFE50914))
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isAi ? Icons.smart_toy_rounded : Icons.headset_mic_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _dotAnimController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress =
                ((_dotAnimController.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity =
                (1.0 - (progress - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity * 0.54),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDateSeparator(String dateText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  /// Rich text parser: mendukung **bold**, numbered list, bullet list, emoji headers
  Widget _buildRichText(String text, {bool isAdmin = false}) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip baris kosong — tambahkan spacing
      if (line.isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      // Deteksi numbered list: "1. ", "2. ", dst
      final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
      if (numberedMatch != null) {
        final number = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 3, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8, top: 1),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: isAdmin
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildInlineRichText(
                  content,
                  baseStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Deteksi bullet list: "• ", "- " di awal baris
      final bulletMatch = RegExp(r'^[•\-]\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 10, top: 7),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFF6C5CE7).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: _buildInlineRichText(
                  content,
                  baseStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Deteksi heading/emoji header: baris yang dimulai dengan emoji dan mengandung **bold**
      final firstChar = line.isNotEmpty ? line.codeUnitAt(0) : 0;
      final isEmojiHeader = (firstChar > 127 || line.startsWith('✅') || line.startsWith('⚠')) &&
          line.contains('**');
      if (isEmojiHeader) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: _buildInlineRichText(
            line,
            baseStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ));
        continue;
      }

      // Teks biasa (mungkin mengandung **bold**)
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 1, bottom: 1),
        child: _buildInlineRichText(
          line,
          baseStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.93),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ));
    }

    if (widgets.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 14.5,
          height: 1.4,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Parse inline **bold** markup menjadi RichText
  Widget _buildInlineRichText(String text, {required TextStyle baseStyle}) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Teks sebelum bold
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      // Teks bold
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ));
      lastEnd = match.end;
    }

    // Sisa teks setelah bold terakhir
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // Jika tidak ada bold, kembalikan teks biasa
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isAdmin,
      {bool showTail = true, bool isAi = false, bool isSystem = false}) {
    final time = _formatTime(msg['created_at']?.toString());

    final bubbleContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: isAdmin
            ? (isSystem
                ? const Color(0xFF1A1D2E)
                : const Color(0xFF1E2028))
            : null,
        gradient: isAdmin
            ? null
            : const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFCC0812)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isAdmin ? (showTail ? 4 : 18) : 18),
          bottomRight: Radius.circular(isAdmin ? 18 : (showTail ? 4 : 18)),
        ),
        border: isAdmin
            ? Border.all(
                color: isSystem
                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isAdmin
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0xFFE50914).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Label AI/Admin
          if (isAdmin && showTail) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAi ? 'AI Assistant' : 'Admin CS',
                  style: TextStyle(
                    color: isAi
                        ? const Color(0xFF6C5CE7).withValues(alpha: 0.8)
                        : const Color(0xFFE50914).withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAi) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color:
                        const Color(0xFF6C5CE7).withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
          _buildRichText(
            msg['message']?.toString() ?? '',
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAdmin) ...[
                Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: (msg['is_read'] == true)
                      ? const Color(0xFF4FC3F7)
                      : Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isAdmin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showTail) ...[
              _buildAdminAvatar(isAi: isAi),
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 40),
            ],
            bubbleContent,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubbleContent,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                color: Color(0xFF6C5CE7),
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'AI Assistant Siap',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanyakan apa saja seputar Netflix Home.\nAI kami siap membantu 24/7!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (_isAiMode) ...[
            // Tombol alihkan ke admin
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _switchToAdminMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE50914).withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded,
                            color: Color(0xFFE50914), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Tidak Puas? Alihkan ke Admin',
                          style: TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Tombol kembali ke AI
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _switchToAiMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_rounded,
                            color: Color(0xFF6C5CE7), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Kembali ke AI Assistant',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiChatBody() {
    final messages = _localMessages;

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (_isAiThinking ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == messages.length && _isAiThinking) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAdminAvatar(isAi: true),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2028),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypingIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        'AI sedang mengetik...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final msg = messages[index];
        final isAdmin = msg['is_from_admin'] == true;
        final isAi = msg['is_ai'] == true;
        final isSystem = msg['is_system'] == true;

        final isLastFromSender = index == messages.length - 1 ||
            messages[index + 1]['is_from_admin'] != msg['is_from_admin'];

        final List<Widget> items = [];

        if (_shouldShowDateSeparator(messages, index)) {
          items.add(_buildDateSeparator(
            _formatDateSeparator(msg['created_at']?.toString()),
          ));
        }

        items.add(_buildMessageBubble(msg, isAdmin,
            showTail: isLastFromSender, isAi: isAi, isSystem: isSystem));

        if (isLastFromSender) {
          items.add(const SizedBox(height: 8));
        }

        return Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: items,
        );
      },
    );
  }

  Widget _buildAdminChatBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('support_chats')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('created_at', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 40),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat pesan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFFE50914),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Menghubungkan ke admin...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final supabaseMessages = snapshot.data ?? [];

        // Cek jika admin membalas
        if (supabaseMessages.isNotEmpty) {
          final lastMessage = supabaseMessages.last;
          final isAdmin = lastMessage['is_from_admin'] == true;

          if (isAdmin && _isWaitingForAdmin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isWaitingForAdmin = false);
                _resetInactivityTimer();
              }
            });
          } else if (!isAdmin && !_isWaitingForAdmin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isWaitingForAdmin = true);
                _resetInactivityTimer();
              }
            });
          }
        }

        // Gabungkan pesan lokal (AI) + pesan Supabase (Admin)
        final allMessages = <Map<String, dynamic>>[
          ..._localMessages,
          ...supabaseMessages.map((m) => {
                ...m,
                'is_ai': false,
                'is_system': false,
              }),
        ];

        // Sort by created_at
        allMessages.sort((a, b) {
          try {
            final aTime = DateTime.parse(a['created_at'] ?? '');
            final bTime = DateTime.parse(b['created_at'] ?? '');
            return aTime.compareTo(bTime);
          } catch (_) {
            return 0;
          }
        });

        if (allMessages.isEmpty) {
          return Center(
            child: Text(
              'Menunggu balasan admin...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          );
        }

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount:
              allMessages.length + (_isWaitingForAdmin ? 1 : 0),
          itemBuilder: (context, index) {
            // Typing indicator untuk admin
            if (index == allMessages.length && _isWaitingForAdmin) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAdminAvatar(isAi: false),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2028),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: _buildTypingIndicator(),
                    ),
                  ],
                ),
              );
            }

            final msg = allMessages[index];
            final isAdmin = msg['is_from_admin'] == true;
            final isAi = msg['is_ai'] == true;
            final isSystem = msg['is_system'] == true;

            final isLastFromSender =
                index == allMessages.length - 1 ||
                    allMessages[index + 1]['is_from_admin'] !=
                        msg['is_from_admin'];

            final List<Widget> items = [];

            if (_shouldShowDateSeparator(allMessages, index)) {
              items.add(_buildDateSeparator(
                _formatDateSeparator(msg['created_at']?.toString()),
              ));
            }

            items.add(_buildMessageBubble(msg, isAdmin,
                showTail: isLastFromSender,
                isAi: isAi,
                isSystem: isSystem));

            if (isLastFromSender) {
              items.add(const SizedBox(height: 8));
            }

            return Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: items,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C10),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE50914),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12141A),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  // Avatar di AppBar (berubah sesuai mode)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isAiMode
                            ? [
                                const Color(0xFF6C5CE7),
                                const Color(0xFF5241B5)
                              ]
                            : [
                                const Color(0xFFE50914),
                                const Color(0xFFB20710)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _isAiMode
                            ? Icons.smart_toy_rounded
                            : Icons.headset_mic_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAiMode ? 'AI Assistant' : 'Live CS Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isAiMode
                                    ? (_aiAvailable
                                        ? Colors.greenAccent.shade400
                                        : Colors.orangeAccent)
                                    : Colors.greenAccent.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isAiMode && _aiAvailable
                                            ? Colors.greenAccent
                                            : _isAiMode
                                                ? Colors.orangeAccent
                                                : Colors.greenAccent)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isAiMode
                                  ? (_aiAvailable
                                      ? 'Online · AI Siap membantu'
                                      : 'Mode Fallback · FAQ')
                                  : 'Online · Admin CS',
                              style: TextStyle(
                                color: _isAiMode
                                    ? (_aiAvailable
                                        ? Colors.greenAccent.shade200
                                        : Colors.orangeAccent.shade100)
                                    : Colors.greenAccent.shade200,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_showEndSession)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _endSession,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE50914)
                                    .withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.power_settings_new_rounded,
                                    color: Color(0xFFE50914), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Akhiri',
                                  style: TextStyle(
                                    color: Color(0xFFE50914),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          // Mode toggle (Alihkan ke Admin / Kembali ke AI)
          _buildModeToggle(),

          // Chat body
          Expanded(
            child: _isAiMode ? _buildAiChatBody() : _buildAdminChatBody(),
          ),

          // Quick Replies (hanya di mode AI)
          if (_isAiMode)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickReplies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendMessage(_quickReplies[index]),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16181E),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _quickReplies[index],
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Input Pesan
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12141A),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0C10),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isTyping
                              ? (_isAiMode
                                  ? const Color(0xFF6C5CE7)
                                      .withValues(alpha: 0.3)
                                  : const Color(0xFFE50914)
                                      .withValues(alpha: 0.3))
                              : Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: _isAiMode
                              ? 'Tanya AI...'
                              : 'Pesan ke admin...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? LinearGradient(
                              colors: _isAiMode
                                  ? [
                                      const Color(0xFF6C5CE7),
                                      const Color(0xFF5241B5)
                                    ]
                                  : [
                                      const Color(0xFFE50914),
                                      const Color(0xFFCC0812)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _isTyping ? null : const Color(0xFF1E2028),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isTyping
                          ? [
                              BoxShadow(
                                color: (_isAiMode
                                        ? const Color(0xFF6C5CE7)
                                        : const Color(0xFFE50914))
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _sendMessage(_messageController.text),
                        borderRadius: BorderRadius.circular(14),
                        child: Icon(
                          Icons.send_rounded,
                          color: _isTyping
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          size: 18,
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
}
