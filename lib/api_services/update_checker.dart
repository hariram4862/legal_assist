import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(
          "https://raw.githubusercontent.com/hariram4862/legal_assist/main/update.json",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'];
        final apkUrl = data['apk_url'];
        final releaseNotes = data['release_notes'];

        if (latestVersion != currentVersion) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Update Available"),
                  content: Text(
                    "A new version ($latestVersion) is available.\n\nChanges:\n$releaseNotes",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Later"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.parse(apkUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: const Text("Update Now"),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }
}
