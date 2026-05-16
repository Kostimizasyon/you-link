import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:you_link/user_provider/user_provider.dart';

const String fcmTokenFileId = "1Q0xQAS3Le_KoVzXL12O27wvyI-FCJWCgWUwH9Z--LJ0";

Future<bool> sendFCM([drive.DriveApi? driveApi]) async {
  try {
    // if no driveApi passed (worker case), get one via silent login
    driveApi ??= await UserProvider.getWorkerDriveApi();
    if (driveApi == null) {
      debugPrint('sendFCM: could not get DriveApi');
      return false;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      debugPrint('sendFCM: could not get FCM token');
      return false;
    }

    final content = utf8.encode(fcmToken);
    final media = drive.Media(
      Stream<List<int>>.fromIterable([content]),
      content.length,
    );

    await driveApi.files.update(
      drive.File(),
      fcmTokenFileId,
      uploadMedia: media,
    );

    debugPrint('FCM token updated in Drive');
    return true;
  } catch (e) {
    debugPrint('sendFCM error: $e');
    return false;
  }
}