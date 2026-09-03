import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String githubOwner = 'StevinRAD';
  static const String githubRepo = 'netflix_home';
  
  static Future<void> checkForUpdate(BuildContext context, {bool showNoUpdateMessage = false}) async {
    if (showNoUpdateMessage && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengecek pembaruan...'), duration: Duration(seconds: 1)),
      );
    }
    try {
      // 1. Ambil versi aplikasi saat ini
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Cek versi terbaru dari GitHub Releases
      var response = await Dio().get(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
      );

      if (response.statusCode == 200) {
        // Tag name biasanya formatnya "v1.0.5", kita hilangkan huruf "v"-nya
        String latestVersion = response.data['tag_name'].toString().replaceAll('v', '');
        
        // Cari URL download APK dari daftar assets
        String? apkDownloadUrl;
        List assets = response.data['assets'];
        for (var asset in assets) {
          if (asset['name'].toString().endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // 3. Bandingkan Versi
        // 3. Bandingkan Versi
        if (_isUpdateAvailable(currentVersion, latestVersion) && apkDownloadUrl != null) {
          // Jika ada update, tampilkan dialog
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, apkDownloadUrl);
          }
        } else {
          if (showNoUpdateMessage && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aplikasi Anda sudah versi terbaru.')),
            );
          }
        }
      }
    } on DioException catch (e) {
      // 404 berarti belum ada Release sama sekali di GitHub
      if (e.response?.statusCode == 404) {
        if (showNoUpdateMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplikasi Anda sudah versi terbaru.')),
          );
        }
      } else {
        debugPrint("Gagal mengecek update: $e");
        if (showNoUpdateMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengecek pembaruan. Periksa koneksi internet.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal mengecek update: $e");
      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat mengecek pembaruan.')),
        );
      }
    }
  }

  // Logika sederhana untuk membandingkan versi (misal 1.0.2 vs 1.0.3)
  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    List<String> current = currentVersion.split('.');
    List<String> latest = latestVersion.split('.');

    for (int i = 0; i < current.length && i < latest.length; i++) {
      int c = int.tryParse(current[i]) ?? 0;
      int l = int.tryParse(latest[i]) ?? 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  // Tampilkan Pop Up Dialog
  static void _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Wajibkan user bereaksi
      builder: (context) => AlertDialog(
        title: const Text('Update Tersedia!'),
        content: Text('Versi terbaru $latestVersion sudah tersedia. Apakah Anda ingin mengupdate sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, downloadUrl);
            },
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  // Proses Download dan Install
  static Future<void> _downloadAndInstall(BuildContext context, String url) async {
    try {
      // Tampilkan indikator loading (bisa diubah pakai progress bar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang mengunduh pembaruan...')),
      );

      // Cari folder penyimpanan sementara
      Directory tempDir = await getTemporaryDirectory();
      String savePath = '${tempDir.path}/app_update.apk';

      // Download file APK
      await Dio().download(url, savePath);

      // Buka file APK untuk memicu proses Instalasi bawaan Android
      await OpenFilex.open(savePath);

    } catch (e) {
      debugPrint("Gagal mendownload update: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh pembaruan.')),
        );
      }
    }
  }
}
