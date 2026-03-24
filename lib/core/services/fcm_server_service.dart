import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FcmServerService {
  static const _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  /// Sends an FCM v1 message by using the bundled Service Account key
  /// to dynamically generate an OAuth 2.0 Access Token.
  /// 
  /// ⚠️ Security Warning: Bundling a service account JSON into a client app
  /// is highly insecure for production apps with sensitive data, as anyone 
  /// extracting the APK can access the scoped Google Cloud resources.
  /// For a class app on the Spark Plan, this bypasses the need for a Backend.
  static Future<bool> sendNotification({
    required String title,
    required String body,
    required String topic,
    Map<String, String>? data,
  }) async {
    try {
      // 1. Read Service Account JSON from assets
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);

      // 2. Generate a short-lived OAuth token via googleapis_auth
      final authClient = await clientViaServiceAccount(accountCredentials, _scopes);

      // 3. Prepare FCM request
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
      if (projectId.isEmpty) return false;

      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // Ensure data payload values are STRINGS (FCM requirement for data payload)
      final payload = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
               'channel_id': 'classmate_channel',
            },
          },
          if (data != null) 'data': data,
        }
      };

      // 4. Send the POST Request
      final response = await authClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('[FCM] Send Status: ${response.statusCode}');
      debugPrint('[FCM] Send Response: ${response.body}');

      authClient.close();
      return response.statusCode == 200;
      
    } catch (e) {
      debugPrint('[FCM] sendNotification error: $e');
      return false;
    }
  }
}
