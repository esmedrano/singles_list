import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? selectedReceiverId;
  List<Map<String, dynamic>> likes = [];
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _setupFcm();
    updateFcmToken();
    _fetchData();
  }

  Future<void> _setupFcm() async {
    // Request permission for notifications
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      // Optionally show a local notification or update UI
      _fetchData(); // Refresh data on new message/like
    });

    // Handle notification when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background message opened: ${message.data}');
      // Navigate or refresh based on data
      _fetchData();
    });

    // Handle notification when app is terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('Terminated app opened: ${initialMessage.data}');
      // Navigate or refresh based on data
      _fetchData();
    }

    // Subscribe to a topic if needed (e.g., for user-specific notifications)
    // await FirebaseMessaging.instance.subscribeToTopic('user_${FirebaseAuth.instance.currentUser?.uid}');
  }

  void updateFcmToken() {
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    });
  }

  Future<void> _fetchData() async {
    final newLikes = await fetchReceivedLikes();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && selectedReceiverId != null) {
      final newMessages = await fetchMessages(selectedReceiverId!);
      setState(() {
        likes = newLikes;
        messages = newMessages;
      });
      // Mark fetched items as read
      for (var like in newLikes) {
        await markAsRead(like['id'], 'likes');
      }
      for (var message in newMessages) {
        final chatId = [user.uid, selectedReceiverId!]..sort();
        final chatRoomId = '${chatId[0]}_${chatId[1]}';
        await markAsRead(message['id'], 'messages/$chatRoomId/messages');
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchReceivedLikes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('toUserId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String receiverId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final chatId = [user.uid, receiverId]..sort();
      final chatRoomId = '${chatId[0]}_${chatId[1]}';
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    }
    return [];
  }

  Future<void> markAsRead(String docId, String collectionPath) async {
    await FirebaseFirestore.instance
        .doc('$collectionPath/$docId')
        .update({'read': true});
  }

  Future<void> sendLike(String toUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('likes').add({
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      // Cloud Function will handle notification
    }
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final chatId = [user.uid, receiverId]..sort();
      final chatRoomId = '${chatId[0]}_${chatId[1]}';
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      // Cloud Function will handle notification
      _controller.clear();
      _fetchData(); // Refresh after sending
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && selectedReceiverId != null) {
      sendMessage(selectedReceiverId!, _controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Likes Received Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Likes Received', style: widget.theme.textTheme.titleMedium),
                  Row(
                    children: List.generate(
                        likes.length.clamp(0, 3),
                        (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(Icons.sentiment_satisfied, color: Colors.yellow[700]),
                            ))..add(Icon(Icons.arrow_forward_ios, size: 16)),
                  ),
                ],
              ),
            ),
            // Messages Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Messages', style: widget.theme.textTheme.titleMedium),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView.builder(
                  itemCount: 4, // Example: Adjust based on actual conversations
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Radio<String>(
                        value: 'user$index',
                        groupValue: selectedReceiverId,
                        onChanged: (String? value) {
                          setState(() {
                            selectedReceiverId = value;
                            _fetchData(); // Fetch messages for selected user
                          });
                        },
                      ),
                      title: Text('Name Last'),
                      subtitle: messages.isNotEmpty && index < messages.length
                          ? Text(messages[index]['text'] ?? 'No message')
                          : Text('hello'),
                      onTap: () {
                        setState(() {
                          selectedReceiverId = 'user$index';
                          _fetchData();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        fillColor: Color(0x50FFFFFF),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        suffixIcon: IconButton(
                          onPressed: _sendMessage,
                          icon: Icon(Icons.send, color: Colors.black),
                          highlightColor: Color(0x20FFFFFF),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                      onTap: () => _focusNode.requestFocus(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* 
Note: This file handles app-side logic for notifications across states.
For server-side notification sending, deploy the following Cloud Functions (in JavaScript, via Firebase CLI):

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    const likeData = snap.data();
    const toUserId = likeData.toUserId;
    const fromUserId = likeData.fromUserId;

    const userDoc = await admin.firestore().collection('users').doc(toUserId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      return admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'New Like',
          body: 'You received a like from another user!',
        },
        data: {
          type: 'like',
          fromUserId: fromUserId,
        },
      });
    }
    return null;
  });

exports.sendMessageNotification = functions.firestore
  .document('messages/{chatRoomId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const toUserId = messageData.receiverId;
    const fromUserId = messageData.senderId;
    const text = messageData.text;

    const userDoc = await admin.firestore().collection('users').doc(toUserId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
      return admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'New Message',
          body: `New message: ${text.substring(0, 20)}...`,
        },
        data: {
          type: 'message',
          fromUserId: fromUserId,
          chatRoomId: context.params.chatRoomId,
        },
      });
    }
    return null;
  });

Deploy with: firebase deploy --only functions
*/

/* import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> sendLike(String toUserId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Store like in Firestore
    final likeRef = await FirebaseFirestore.instance.collection('likes').add({
      'fromUserId': user.uid,
      'toUserId': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false, // Track if the recipient has seen it
    });

    // Send FCM notification
    await _sendNotification(toUserId, 'New Like', 'You received a like!');
  }
}

Future<void> sendMessage(String receiverId, String text) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final chatId = [user.uid, receiverId]..sort();
    final chatRoomId = '${chatId[0]}_${chatId[1]}';
    final messageRef = await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Send FCM notification
    await _sendNotification(receiverId, 'New Message', 'You have a new message!');
  }
}

// Helper function to send FCM notification
Future<void> _sendNotification(String toUserId, String title, String body) async {
  // Assume you have a way to map userId to FCM token (e.g., stored in Firestore)
  final tokenSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(toUserId)
      .get();
  final fcmToken = tokenSnapshot.data()?['fcmToken'];

  if (fcmToken != null) {
    await FirebaseMessaging.instance.sendMessage(
      to: fcmToken,
      notification: Notification(
        title: title,
        body: body,
      ),
    );
  }
}






Future<List<Map<String, dynamic>>> fetchReceivedLikes() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final snapshot = await FirebaseFirestore.instance
        .collection('likes')
        .where('toUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }
  return [];
}

Future<List<Map<String, dynamic>>> fetchMessages(String receiverId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final chatId = [user.uid, receiverId]..sort();
    final chatRoomId = '${chatId[0]}_${chatId[1]}';
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }
  return [];
}

// Mark as read after fetching
Future<void> markAsRead(String docId, String collectionPath) async {
  await FirebaseFirestore.instance
      .doc('$collectionPath/$docId')
      .update({'read': true});
} */