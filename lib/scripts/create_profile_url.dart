import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Move to lib/config.dart for production
  static const String firebaseApiKey = 'AIzaSyAHNWbZrrLelgreM4SQkgw5bymcF9zQigI'; // Replace with your key

  static Future<String> createProfileDynamicLink(String userId) async {
    const String baseUrl = 'https://integridate.web.app/user_ids/+11231231231/uid';
    final String longUrl = '$baseUrl/$userId';
    try {
      final response = await http.post(
        Uri.parse('https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=$firebaseApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'longDynamicLink': 'https://integridate.web.app/?link=$longUrl&apn=com.example.integra_date&ibi=com.example.integra_date',
          'suffix': {'option': 'SHORT'},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await FirebaseAnalytics.instance.logEvent(
          name: 'create_short_link',
          parameters: {'user_id': userId},
        );
        return data['shortLink'];
      }
      print('Failed to shorten link: ${response.statusCode}');
      return longUrl;
    } catch (e) {
      print('Error shortening link: $e');
      return longUrl;
    }
  }

  static Future<void> shareProfileLink(String userId) async {
    final String link = await createProfileDynamicLink(userId);
    await Clipboard.setData(ClipboardData(text: link));
    await FirebaseAnalytics.instance.logShare(
      contentType: 'profile',
      itemId: userId,
      method: 'clipboard',
    );
    print('Profile link copied to clipboard: $link');
  }

  void initDeepLinks() async {
    try {
      // Handle initial link when app starts
      print('getting init link');
      final Uri? initialLink = await _appLinks.getInitialLink(); // Correct method
      print('got init link: $initialLink');
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Handle ongoing links when app is in foreground
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          print('naving to deep link: $uri');
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        print('Error handling deep link: $err');
      },
    );
  }

  Future<void> _handleDeepLink(Uri deepLink) async {
    if (deepLink.path.contains('/user_ids')) {
      String docTitle = await sqlite.DatabaseHelper.instance.getUserDocTitle();
      final docRef = _firestore.collection('user_ids').doc(docTitle);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final userData = docSnap.data() as Map<String, dynamic>;
        await FirebaseAnalytics.instance.logEvent(
          name: 'open_profile',
          parameters: {'docTitle': docTitle},
        );
        print('Navigating to profile: $docTitle, Data: $userData');
        // Navigate: Navigator.pushNamed(context, '/profile', arguments: userData);
      } else {
        print('Profile not found for UID: $docTitle');
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}