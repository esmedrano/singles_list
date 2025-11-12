import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class NotificationService {
  static Function()? onNewLikeReceived; // Callback for foreground updates

  static Future<void> init() async {  // Right now this updates every time the app is restarted. (1 write a restart)
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    String? token = await FirebaseMessaging.instance.getToken();
    String userDoc = await sqlite.DatabaseHelper.instance.getUserDocTitle();
    if (token != null && FirebaseAuth.instance.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('user_ids')
          .doc(userDoc)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'allowNotifications': true,
      }, SetOptions(merge: true));
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {  // Is this a listener that costs money?? 
      final prefs = await SharedPreferences.getInstance();
      if (message.data['type'] == 'like') {
        int currentCount = prefs.getInt('unreadLikes') ?? 0;
        int newCount = int.parse(message.data['count'] ?? '0');
        await prefs.setInt('unreadLikes', currentCount + newCount);
        onNewLikeReceived?.call(); // Trigger checkNewData
      }
    });
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'like') {
      onNewLikeReceived?.call(); // Trigger checkNewData on notification tap
    }
  }
}