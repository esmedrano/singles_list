// So the animations are broken. It may be a confilct with the nav bars built in gesture detectors, 
// becauase the animations only trigger on semi long press. Grok 3 recomends another way. but im moving on for now. 

import 'package:flutter/material.dart';
import 'package:integra_date/firebase/load_data.dart' as firebase;
import 'package:integra_date/pages/database_page.dart' as database_page;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/pages/messages_page.dart' as messages_page;
import 'package:integra_date/pages/profile_page.dart' as profile_page;

class PageSelectBar extends StatefulWidget {
  const PageSelectBar({super.key});

  @override
  State<PageSelectBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<PageSelectBar> {
  int currentPageIndex = 0;  // Starting page on opening the app
  Future<List<Map<dynamic, dynamic>>> profileData = firebase.fetchInitialEntries();  // Centralized cache of profiles
  int? selectedDatabaseIndex; // Store selected index if swipe page is accessed from a profile banner/grid item
  List <bool> isPressed = [false, false, false, false];  // all button press states

  void switchPage(int pageIndex, [int? databaseIndex]) {
    setState(() {
      currentPageIndex = pageIndex;
      selectedDatabaseIndex = databaseIndex;  // Update selected profile index
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Color(0x00FFFFFF),
      
      body: IndexedStack(  // This is used to change to the profile page after clicking a profile in the database view
        index: currentPageIndex,
        children: [
          database_page.DatabasePage(  // Build database page
            theme: theme,
            profileData: profileData,
            onBannerTap: switchPage,
          ),
    
          swipe_page.SwipePage(
            profiles: profileData,
            databaseIndex: selectedDatabaseIndex, // Pass selected index
          ),
    
          messages_page.MessagePage(theme: theme),

          profile_page.ProfilePage(),
        ],
      ),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        height: 60,
        backgroundColor: Color.fromARGB(255,134,142,199),  // This is what the color would be if transparent (it's not now)
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),

        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
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
      ),
    );
  }
}