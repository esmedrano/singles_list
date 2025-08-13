// // So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// // becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

// import 'package:flutter/material.dart';
// import 'package:integra_date/firebase/load_data.dart' as firebase;
// import 'package:integra_date/pages/database_page.dart' as database_page;
// import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
// import 'package:integra_date/pages/messages_page.dart' as messages_page;
// import 'package:integra_date/pages/profile_page.dart' as profile_page;
// import 'package:integra_date/pages/settings_page.dart' as settings_page;
// import 'package:integra_date/pages/log_in_page.dart' as log_in_page;


// class PageSelectBar extends StatefulWidget {
//   const PageSelectBar({super.key});

//   @override
//   State<PageSelectBar> createState() => _NavigationBarState();
// }

// class _NavigationBarState extends State<PageSelectBar> {
//   bool loggedIn = false;
//   int currentPageIndex = 0;  // Starting page on opening the app
//   int navBarIndex = 0; // For NavigationBar (0–3)
//   Future<List<Map<dynamic, dynamic>>> profileData = firebase.fetchInitialEntries();  // Centralized cache of profiles
//   int? selectedDatabaseIndex; // Store selected index if swipe page is accessed from a profile banner/grid item
//   List <bool> isPressed = [false, false, false, false];  // all button press states
  
//   void initState() {
//     super.initState();
//      if (!loggedIn) {
//       currentPageIndex = 5;
//      }
//   }

//   void switchPage(int pageIndex, [int? databaseIndex]) {
//     setState(() {
//       currentPageIndex = pageIndex;
//       selectedDatabaseIndex = databaseIndex;  // Update selected profile index
//       if (pageIndex >= 0 && pageIndex <= 3) {
//         navBarIndex = pageIndex;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: Color(0x00FFFFFF),
      
//       body: IndexedStack(  // This is used to change to the profile page after clicking a profile in the database view
//         index: currentPageIndex,
//         children: [
//           database_page.DatabasePage(  // Build database page
//             theme: theme,
//             profileData: profileData,
//             switchPage: switchPage,
//           ),
    
//           swipe_page.SwipePage(
//             profiles: profileData,
//             databaseIndex: selectedDatabaseIndex, // Pass selected index
//           ),
    
//           messages_page.MessagePage(theme: theme),

//           profile_page.ProfilePage(
//             switchPage: switchPage,
//           ),

//           settings_page.SettingsPage(switchPage: switchPage),

//           log_in_page.LogIn()
//         ],
//       ),
      
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: navBarIndex,
//         height: 60,
//         backgroundColor: Color.fromARGB(255,134,142,199),  // This is what the color would be if transparent (it's not now)
//         indicatorColor: Colors.transparent,
//         overlayColor: WidgetStatePropertyAll(Colors.transparent),

//         onDestinationSelected: (int index) {
//           setState(() {
//             currentPageIndex = index;
//             navBarIndex = index;
//           });
//         },
        
//         destinations: [
    
//           Padding(
//             padding: EdgeInsets.only(top: 20, left: 25, right: 5),
//             // child: GestureDetector(
//             //   onTapDown: (_) {
//             //     setState(() => isPressed[0] = true);
//             //     print('test');
//             //   },

//               // onTapUp: (_) {
//               //   Future.delayed(Duration(milliseconds: 500), () {
//               //     setState(() => isPressed[0] = false);
//               //   });
//               // },

//               // onTapCancel: () {
//               //   Future.delayed(Duration(milliseconds: 200), () {
//               //     setState(() => isPressed[0] = false);
//               //   });
//               // },

//               // child: AnimatedScale(
//               //   scale: isPressed[0] ? 0.85 : 1.0,  // Shrink to 85% when pressed
//               //   duration: Duration(milliseconds: 200),  // For 100 ms

//                 child: NavigationDestination(
//                   icon: ImageIcon(AssetImage('assets/icons/house.png'), size: 30),
//                   selectedIcon: ImageIcon(AssetImage('assets/icons/house_filled.png'), size: 35),
//                   label: '',
//                 ),
//               //),
//             //),
//           ),
    
//           Padding(
//             padding: EdgeInsets.only(top: 20, left: 5, right: 5),
//             // child: GestureDetector(
//             //   onTapDown: (_) => setState(() => isPressed[1] = true),
//             //   onTapUp: (_) {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[1] = false);
//             //     });
//             //   },
//             //   onTapCancel: () {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[1] = false);
//             //     });
//             //   },
//             //   child: AnimatedScale(
//             //     scale: isPressed[1] ? 0.85 : 1.0,  // Shrink to 85% when pressed
//             //     duration: Duration(milliseconds: 200),  // For 100 ms
//                 child: NavigationDestination(
//                   icon: ImageIcon(AssetImage('assets/icons/stack.png'), size: 35),
//                   selectedIcon: ImageIcon(AssetImage('assets/icons/stack_filled.png'), size: 38),
//                   label: '',
//                 ),
//               //),
//             //),
//           ),
    
//           Padding(
//             padding: EdgeInsets.only(top: 20, left: 5, right: 5),
//             // child: GestureDetector(
//             //   onTapDown: (_) => setState(() => isPressed[2] = true),
//             //   onTapUp: (_) {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[2] = false);
//             //     });
//             //   },
//             //   onTapCancel: () {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[2] = false);
//             //     });
//             //   },
//             //   child: AnimatedScale(
//             //     scale: isPressed[2] ? 0.85 : 1.0,  // Shrink to 85% when pressed
//             //     duration: Duration(milliseconds: 200),  // For 100 ms
//                 child: NavigationDestination(
//                   icon: ImageIcon(AssetImage('assets/icons/messages.png'), size: 40,),
//                   selectedIcon: ImageIcon(AssetImage('assets/icons/messages_filled.png'), size: 45),
//                   label: '',
//                 ),
//               //),
//             //),
//           ),
    
//           Padding(
//             padding: EdgeInsets.only(top: 20, left: 5, right: 25),
//             // child: GestureDetector(
//             //   onTapDown: (_) => setState(() => isPressed[3] = true),
//             //   onTapUp: (_) {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[3] = false);
//             //     });
//             //   },
//             //   onTapCancel: () {
//             //     Future.delayed(Duration(milliseconds: 200), () {
//             //       setState(() => isPressed[3] = false);
//             //     });
//             //   },
//             //   child: AnimatedScale(
//             //     scale: isPressed[3] ? 0.85 : 1.0,  // Shrink to 85% when pressed
//             //     duration: Duration(milliseconds: 200),  // For 100 ms
//                 child: NavigationDestination(
//                   icon: ImageIcon(AssetImage('assets/icons/profile.png'), size: 35),
//                   selectedIcon: ImageIcon(AssetImage('assets/icons/profile_filled.png'), size: 40),
//                   label: ''
//                 ),
//               //),
//            // ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

// So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

// So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

// So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

import 'dart:async'; // Added to ensure StreamSubscription is available
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:integra_date/firebase/load_data.dart' as firebase;
import 'package:integra_date/pages/database_page.dart' as database_page;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/pages/messages_page.dart' as messages_page;
import 'package:integra_date/pages/profile_page.dart' as profile_page;
import 'package:integra_date/pages/settings_page.dart' as settings_page;
import 'package:integra_date/pages/log_in_page.dart' as log_in_page;

class PageSelectBar extends StatefulWidget {
  const PageSelectBar({super.key});

  @override
  State<PageSelectBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<PageSelectBar> {
  bool loggedIn = false;
  bool isInDemo = false; // NEW: Flag for when user opts into demo from login
  int currentPageIndex = 5; // Start on login if not logged in
  int navBarIndex = 0; // For NavigationBar (0–3)
  late Future<List<Map<dynamic, dynamic>>> profileData; // Made late for dynamic init
  int? selectedDatabaseIndex; // Store selected index if swipe page is accessed from a profile banner/grid item
  List<bool> isPressed = [false, false, false, false]; // all button press states
  late StreamSubscription<User?> _authListener; // For auth state changes
  double _dragX = 16.0; // Initial x position
  double _dragY = 80.0; // Initial y position (above bottom nav)

  @override
  void initState() {
    super.initState();

    // Initial check for logged-in user
    final user = FirebaseAuth.instance.currentUser;
    loggedIn = user != null;
    if (loggedIn) {
      currentPageIndex = 0; // Start on database if logged in
      isInDemo = false;
    } else {
      currentPageIndex = 5; // Start on login if not logged in
      isInDemo = false;
    }
    _updateProfileData();
    checkLogInState(); // Move listener setup to separate method
  }

  @override
  void dispose() {
    _authListener.cancel(); // Clean up the listener
    super.dispose();
  }

  void checkLogInState() {
    print('Checking Log In State!');
    (User? user) {
      setState(()  {
        loggedIn = user != null;
        if (loggedIn) {
          currentPageIndex = 0; // Go to database on login
          isInDemo = false;
        } else {
          currentPageIndex = 5; // Go to login on logout
          isInDemo = false;
        }
        _updateProfileData();
      });
    };
  }

  void _updateProfileData() {
    profileData = (loggedIn || isInDemo)
        ? firebase.fetchInitialEntries() // Use original Firebase fetch for both logged in and demo
        : Future.value([]); // Empty if on login
  }

  void switchPage(int pageIndex, [int? databaseIndex]) {
    setState(() {
      currentPageIndex = pageIndex;
      selectedDatabaseIndex = databaseIndex; // Update selected profile index

      if (pageIndex >= 0 && pageIndex <= 3) {  // Only use nav bar if page in nav bar page range
        navBarIndex = pageIndex;
      }

      if (pageIndex == 5) {  // If page is log in page set logged in to false
        loggedIn = false;
      }
    });
  }

  void enterDemo() {
    setState(() {
      isInDemo = true;
      currentPageIndex = 0; // Switch to database page for demo
      _updateProfileData(); // Load data from Firebase
    });
  }

  // Positioned createAccountButton() {
  //   return Positioned(
  //           bottom: 80, // Position above bottom nav bar (assuming nav height ~60)
  //           right: 16,
  //           child: FloatingActionButton.extended(
  //             onPressed: () {
  //               switchPage(5); // Switch to login/create account page
  //             },
  //             label: const Text('Create Account'),
  //             //icon: const Icon(Icons.add),
  //             tooltip: 'Create a real account to access full features',
  //           ),
  //         );
  // }

  Widget createAccountButton() {
    return Draggable(
      feedback: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Create Account'),
        backgroundColor: Colors.grey, // Dimmed feedback during drag
      ),

      childWhenDragging: const SizedBox.shrink(), // Hide original during drag
      onDragEnd: (DraggableDetails details) {
        setState(() {
          // Update position based on drag end, clamping within screen bounds from bottom-right
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          const buttonWidth = 150.0; // Approximate width of FAB
          const buttonHeight = 56.0; // Approximate height of FAB.extended
          const navBarHeight = 60.0; // Approximate nav bar height

          // Clamp right and bottom positions
          _dragX = (screenWidth - details.offset.dx - buttonWidth).clamp(0.0, screenWidth - buttonWidth);
          _dragY = (screenHeight - details.offset.dy - buttonHeight - navBarHeight).clamp(0.0, screenHeight - buttonHeight - navBarHeight);
        });
      },
      child: FloatingActionButton.extended(
        onPressed: () {
          switchPage(5); // Switch to login/create account page
          _dragX = 16;
          _dragY = 80;
        },
        label: const Text('Create Account'),
        tooltip: 'Create a real account to access full features',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0x00FFFFFF),
      body: Stack(  // Changed to Stack to allow overlay button
        children: [
          IndexedStack(  // This is used to change to the profile page after clicking a profile in the database view
            index: currentPageIndex,
            children: [
              database_page.DatabasePage(  // Build database page
                theme: theme,
                profileData: profileData,
                switchPage: switchPage,
              ),
        
              swipe_page.SwipePage(
                profiles: profileData,
                databaseIndex: selectedDatabaseIndex, // Pass selected index
              ),
        
              messages_page.MessagePage(theme: theme),
    
              profile_page.ProfilePage(
                switchPage: switchPage,
              ),
    
              settings_page.SettingsPage(switchPage: switchPage),
    
              log_in_page.LogIn(
                switchPage: switchPage,
                enterDemo: enterDemo, // NEW: Pass enterDemo function
              ),
            ],
          ),
          
          if (isInDemo && currentPageIndex != 5) // Show overlay button in demo mode, except on login page
            Positioned(
              right: _dragX,
              bottom: _dragY,
              child: createAccountButton(),
            ),
        ],
      ),
      
      bottomNavigationBar: currentPageIndex != 5 // Hide nav bar on login page
          ? NavigationBar(
        selectedIndex: navBarIndex,
        height: 60,
        backgroundColor: Color.fromARGB(255,134,142,199),  // This is what the color would be if transparent (it's not now)
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),

        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            navBarIndex = index;
          });
        },
        
        destinations: [
    
          Padding(
            padding: EdgeInsets.only(top: 20, left: 25, right: 5),
            // child: GestureDetector(
            //   onTapDown: (_) {
            //     setState(() => isPressed[0] = true);
            //     print('test');
            //   },

              // onTapUp: (_) {
              //   Future.delayed(Duration(milliseconds: 500), () {
              //     setState(() => isPressed[0] = false);
              //   });
              // },

              // onTapCancel: () {
              //   Future.delayed(Duration(milliseconds: 200), () {
              //     setState(() => isPressed[0] = false);
              //   });
              // },

              // child: AnimatedScale(
              //   scale: isPressed[0] ? 0.85 : 1.0,  // Shrink to 85% when pressed
              //   duration: Duration(milliseconds: 200),  // For 100 ms

                child: NavigationDestination(
                  icon: ImageIcon(AssetImage('assets/icons/house.png'), size: 30),
                  selectedIcon: ImageIcon(AssetImage('assets/icons/house_filled.png'), size: 35),
                  label: '',
                ),
              //),
            //),
          ),
    
          Padding(
            padding: EdgeInsets.only(top: 20, left: 5, right: 5),
            // child: GestureDetector(
            //   onTapDown: (_) => setState(() => isPressed[1] = true),
            //   onTapUp: (_) {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[1] = false);
            //     });
            //   },
            //   onTapCancel: () {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[1] = false);
            //     });
            //   },
            //   child: AnimatedScale(
            //     scale: isPressed[1] ? 0.85 : 1.0,  // Shrink to 85% when pressed
            //     duration: Duration(milliseconds: 200),  // For 100 ms
                child: NavigationDestination(
                  icon: ImageIcon(AssetImage('assets/icons/stack.png'), size: 35),
                  selectedIcon: ImageIcon(AssetImage('assets/icons/stack_filled.png'), size: 38),
                  label: '',
                ),
              //),
            //),
          ),
    
          Padding(
            padding: EdgeInsets.only(top: 20, left: 5, right: 5),
            // child: GestureDetector(
            //   onTapDown: (_) => setState(() => isPressed[2] = true),
            //   onTapUp: (_) {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[2] = false);
            //     });
            //   },
            //   onTapCancel: () {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[2] = false);
            //     });
            //   },
            //   child: AnimatedScale(
            //     scale: isPressed[2] ? 0.85 : 1.0,  // Shrink to 85% when pressed
            //     duration: Duration(milliseconds: 200),  // For 100 ms
                child: NavigationDestination(
                  icon: ImageIcon(AssetImage('assets/icons/messages.png'), size: 40,),
                  selectedIcon: ImageIcon(AssetImage('assets/icons/messages_filled.png'), size: 45),
                  label: '',
                ),
              //),
            //),
          ),
    
          Padding(
            padding: EdgeInsets.only(top: 20, left: 5, right: 25),
            // child: GestureDetector(
            //   onTapDown: (_) => setState(() => isPressed[3] = true),
            //   onTapUp: (_) {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[3] = false);
            //     });
            //   },
            //   onTapCancel: () {
            //     Future.delayed(Duration(milliseconds: 200), () {
            //       setState(() => isPressed[3] = false);
            //     });
            //   },
            //   child: AnimatedScale(
            //     scale: isPressed[3] ? 0.85 : 1.0,  // Shrink to 85% when pressed
            //     duration: Duration(milliseconds: 200),  // For 100 ms
                child: NavigationDestination(
                  icon: ImageIcon(AssetImage('assets/icons/profile.png'), size: 35),
                  selectedIcon: ImageIcon(AssetImage('assets/icons/profile_filled.png'), size: 40),
                  label: ''
                ),
              //),
           // ),
          ),
        ],
      ) : null,
    );
  }
}