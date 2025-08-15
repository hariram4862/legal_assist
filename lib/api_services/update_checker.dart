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
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

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

        // Extract build number from update.json version if format is x.y.z+n
        String latestVersionOnly = latestVersion;
        int latestBuildNumber = 0;

        if (latestVersion.contains('+')) {
          final parts = latestVersion.split('+');
          latestVersionOnly = parts[0];
          latestBuildNumber = int.tryParse(parts[1]) ?? 0;
        }

        // Compare: show update if version changes OR build number increases
        if (latestVersionOnly != currentVersion ||
            latestBuildNumber > currentBuildNumber) {
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
