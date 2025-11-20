import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class NotificationService {
  // Callback to notify UI when new likes arrive (foreground or tap)
  static Function()? onNewLikeReceived;

  /// Initialize FCM + token management + message handlers
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _registerFcmToken();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle notification tap from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Handle notification tap from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  /// Register current token and listen for future refreshes
  static Future<void> _registerFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM tolen: $token");
    if (token != null) {
      await _updateTokenIfNeeded(token);
    }

    // Listen for rare future token changes (100% local & free)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _updateTokenIfNeeded(newToken);
    });
  }

  /// Only update Firestore if token actually changed
  /// Also removes the previous token first → array stays clean forever
  static Future<void> _updateTokenIfNeeded(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    final String? previousToken = prefs.getString('lastFcmToken');

    // No change → skip entirely (saves 99% of writes)
    if (previousToken == newToken) return;

    final String userDoc = await sqlite.DatabaseHelper.instance.getUserDocTitle();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (userDoc.isEmpty || currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('user_ids')
        .doc(userDoc);

    // Use a transaction to ensure atomic remove + add (prevents duplicates even in rare race conditions)
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if (previousToken != null && previousToken.isNotEmpty) {
        transaction.update(docRef, {
          'fcmTokens': FieldValue.arrayRemove([previousToken]),
        });
      }

      transaction.set(docRef, {
        'fcmTokens': FieldValue.arrayUnion([newToken]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Remember the new token locally
    await prefs.setString('lastFcmToken', newToken);
  }

  /// Handle messages received while app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data['type'] != 'like') return;

    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('unreadLikes') ?? 0;
    final int increment = int.tryParse(message.data['count']?.toString() ?? '0') ?? 0;

    await prefs.setInt('unreadLikes', currentCount + increment);
    onNewLikeReceived?.call();
  }

  /// Handle when user taps a notification (background or terminated)
  static void _handleMessageTap(RemoteMessage message) {
    if (message.data['type'] == 'like') {
      onNewLikeReceived?.call();
    }
  }

  /// Optional: Clear badge when user opens Likes screen
  static Future<void> clearUnreadLikesBadge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unreadLikes'); // or set to 0
    onNewLikeReceived?.call();
  }
}