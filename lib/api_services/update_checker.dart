// import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:dio/dio.dart';
// import 'package:install_plugin/install_plugin.dart';
// import 'package:path_provider/path_provider.dart';

// Future<void> checkAppUpdate(BuildContext context) async {
//   try {
//     final info = await PackageInfo.fromPlatform();
//     final currentVersion = info.version;

//     final doc =
//         await FirebaseFirestore.instance
//             .collection('app_config')
//             .doc('version_info')
//             .get();

//     if (!doc.exists) return;

//     final data = doc.data();
//     final latestVersion = data?['latest_version'];
//     final updateUrl = data?['update_url'];
//     final isMandatory = data?['mandatory'] ?? false;

//     if (currentVersion != latestVersion && updateUrl != null) {
//       showDialog(
//         context: context,
//         barrierDismissible: !isMandatory,
//         builder:
//             (_) => AlertDialog(
//               title: const Text("Update Available"),
//               content: Text("A new version ($latestVersion) is available."),
//               actions: [
//                 if (!isMandatory)
//                   TextButton(
//                     child: const Text("Later"),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     downloadAndInstallApk(updateUrl);
//                   },
//                   child: const Text("Update Now"),
//                 ),
//               ],
//             ),
//       );
//     }
//   } catch (e) {
//     print("Update check error: $e");
//   }
// }

// Future<void> downloadAndInstallApk(String apkUrl) async {
//   var status = await Permission.storage.request();
//   if (!status.isGranted) return;

//   final dir = await getExternalStorageDirectory();
//   final filePath = '${dir!.path}/update.apk';

//   final dio = Dio();
//   await dio.download(apkUrl, filePath);

//   await InstallPlugin.installApk(filePath); // ✅ Correct
// }
