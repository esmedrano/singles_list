import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:integra_date/widgets/navigation_bar.dart' as navigation_bar;

void main() {
  // debugPaintSizeEnabled = true;
  debugPaintSizeEnabled = false; // Disable debug borders
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
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

              colors: [Colors.indigo.shade100, Colors.indigo.shade700],
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