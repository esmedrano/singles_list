import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart'
import 'package:flutter/cupertino.dart'; 
import 'package:integra_date/widgets/navigation_bar.dart' as navigation_bar;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated file after Firebase setup
import 'package:firebase_messaging/firebase_messaging.dart' as fire_mess; 
//import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:shared_preferences/shared_preferences.dart' as preference; // Used to store like and message flags 

import 'package:flutter/services.dart'; // Required for SystemChrome that locks app in portrait mode

// Emulators
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

// Background message handler
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(fire_mess.RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await preference.SharedPreferences.getInstance();
  if (message.data['type'] == 'like') {
    int currentCount = prefs.getInt('unreadLikes') ?? 0;
    int newCount = int.parse(message.data['count'] ?? '0');
    await prefs.setInt('unreadLikes', currentCount + newCount);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.useFirestoreEmulator('172.20.10.2', 8080);  // home: '192.168.12.222' phone: '172.20.10.2'
  await FirebaseStorage.instance.useStorageEmulator('172.20.10.2', 9199);
  await FirebaseAuth.instance.useAuthEmulator('172.20.10.2', 9099);
  FirebaseFunctions.instance.useFunctionsEmulator('172.20.10.2', 5001);

  // print(FirebaseFunctions.instance.);

  await sqlite.DatabaseHelper.instance.clearCachedImages(); //////////////////////////////////////////////////////////////////////////////////////////
  await sqlite.DatabaseHelper.instance.clearAllSettings(); // Clears profiles too
  await sqlite.DatabaseHelper.instance.deleteDatabaseFile();

  await sqlite.DatabaseHelper.instance.setUserDocTitle('CqN9BUUjYFA');  //123 123 1231  // This is to reset the user doc title in sqlite when it is cleared
  
  // Handle background messages 
  fire_mess.FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);  // Sets the function for handling background messages 

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const double fontSize = 15;
  static const String fontFamily = 'Nunito';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
    theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          displayMedium: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          displaySmall: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          titleLarge: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          titleMedium: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          titleSmall: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,

          bodySmall: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
 
          labelLarge: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
 
          labelMedium: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
 
          labelSmall: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
        ),

        // Apply font to buttons (e.g., TextButton in FiltersMenu)
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
            ),
          ),
        ),

        // Apply font to ChoiceChip labels
        chipTheme: const ChipThemeData(
          labelStyle: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
        ),
        
        // Apply font to Cupertino widgets (e.g., CupertinoPicker in FiltersMenu)
        cupertinoOverrideTheme: const CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, ),  // letterSpacing: 1.2,
            pickerTextStyle: TextStyle( fontFamily: fontFamily, fontSize: fontSize, fontWeight: FontWeight.bold, color: Color(0xFF000000)),  // letterSpacing: 1.2,
          ),
        ),
      ),

      home: Scaffold(  // Scaffold is necessary to keep the SafeArea from eliminating the system UI at the top of the screen ?!
        //resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(

              // const Color.fromARGB(255, 107, 130, 255)
              // [Color.fromARGB(255, 88, 149, 240), Colors.indigo]
              // [Colors.indigo.shade300, Colors.indigo.shade400]

              // colors: [Colors.indigo.shade50, Colors.indigo.shade900],
              // begin: Alignment.topCenter,
              // end: Alignment.bottomCenter,
              colors: [
                Colors.indigo.shade200, // Start color
                Colors.indigo.shade300, // Intermediate color
                Colors.indigo.shade500, // Intermediate color
                Colors.indigo.shade700, // End color
              ],
              stops: [0.0, 0.33, 0.66, 1.0], // Smooth progression
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),


          child: navigation_bar.PageSelectBar() 

        ),
      ),
    );
  }
}