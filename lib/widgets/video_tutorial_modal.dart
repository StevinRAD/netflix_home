import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/language_notifier.dart';

class VideoTutorialModal extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoTutorialModal({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  /// Helper untuk mengekstrak Video ID dari berbagai format link YouTube (termasuk Shorts)
  static String extractVideoId(String url) {
    final cleanUrl = url.trim();
    final shortsRegExp = RegExp(
      r'(?:youtube\.com/shorts/|youtu\.be/|youtube\.com/watch\?v=|youtube\.com/embed/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = shortsRegExp.firstMatch(cleanUrl);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    return 'NUKerEzq7pA';
  }

  /// Tampilkan Video Popup langsung di dalam aplikasi
  static void show(
    BuildContext context, {
    required String videoUrl,
    required String title,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => VideoTutorialModal(
        videoUrl: videoUrl,
        title: title,
      ),
    );
  }

  @override
  State<VideoTutorialModal> createState() => _VideoTutorialModalState();
}

class _VideoTutorialModalState extends State<VideoTutorialModal> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = VideoTutorialModal.extractVideoId(widget.videoUrl);

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: true,
      ),
    );
  }

  @override
  void deactivate() {
    _controller.pauseVideo();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.videoUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIndo = LanguageNotifier.isIndonesian.value;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141420) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE50914).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── HEADER POPUP ───
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1B2C) : const Color(0xFFF8F9FA),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.smart_display_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SHORTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFE50914),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isIndo ? 'Video Tutorial Pop-up' : 'In-App Video Tutorial',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),

              // ─── PLAYER SECTION ───
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.65,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        color: Colors.black,
                        child: YoutubePlayer(
                          controller: _controller,
                          aspectRatio: 9 / 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isIndo
                                    ? 'Video berputar di pop-up aplikasi.'
                                    : 'Video playing inside pop-up.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _openExternal,
                              icon: const Icon(Icons.open_in_new_rounded, size: 14),
                              label: Text(
                                isIndo ? 'Buka di YouTube' : 'Open in YouTube',
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE50914),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
