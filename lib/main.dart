import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:integra_date/widgets/navigation_bar.dart' as navigation_bar;
import 'package:flutter/cupertino.dart';

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