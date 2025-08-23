import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:integra_date/pages/database_page.dart' as database_page;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/pages/messages_page.dart' as messages_page;
import 'package:integra_date/pages/profile_page.dart' as profile_page;
import 'package:integra_date/pages/settings_page.dart' as settings_page;
import 'package:integra_date/pages/log_in_page.dart' as log_in_page;
import 'package:integra_date/scripts/profile_location.dart';
import 'package:integra_date/databases/get_firestore_profiles.dart' as get_firestore_profiles;
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/databases/get_demo_profiles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:geolocator/geolocator.dart';

class PageSelectBar extends StatefulWidget {
  const PageSelectBar({super.key});

  @override
  State<PageSelectBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<PageSelectBar> {
  bool loggedIn = false;
  bool isInDemo = false;
  int currentPageIndex = 5;
  int navBarIndex = 0;
  Future<List<Map<dynamic, dynamic>>> profileData = Future.value([]);
  int? selectedDatabaseIndex;
  List<bool> isPressed = [false, false, false, false];
  double _dragX = 16.0;
  double _dragY = 80.0;
  bool hasLocationForNewAccount = false;
  bool hasLocationForLoggedInAccount = true;
  String? nextDocId;
  double radius = 5;
  int currentPage = 1;
  final int pageSize = 105;
  bool hasNextPage = true;
  bool hasPreviousPage = false;
  List<Map<dynamic, dynamic>> allCachedProfiles = [];

  late final userLat;
  late final userLon;
  late final userGeohash;

  late List<Map<dynamic, dynamic>> profiles;

  @override
  void initState() {
    super.initState();
    //loadFilterValues();

    ProfileLocation.getLocation(context);  // For debug purposes. The data needs to be accessed from the local cache by the loadCachedOrFirebaseProfiles function. This may be better here anyway.
    initialSendLocationToFB();  // For debug purposes. The data needs to be accessed from the local cache by the loadCachedOrFirebaseProfiles function. This may be better here anyway.
    
    checkAndSetLogInState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ProfileLocation.getLocation(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sqlite.DatabaseHelper.instance.close();
  }

  Future<void> loadFilterValues() async {
    final distance = await sqlite.DatabaseHelper.instance.getFilterValue('distance');
    if (mounted) {
      setState(() {
        radius = double.parse(distance?.replaceAll(' mi', '') ?? '5');
      });
      print('PageSelectBar: Loaded radius: $radius mi');
    }
  }

  void checkAndSetLogInState() {
    print('Checking Log In State!');
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      loggedIn = user != null;
      if (loggedIn) {
        currentPageIndex = 0;
        navBarIndex = 0;
        loadCachedOrFirebaseProfiles();
        isInDemo = false;
      } else {
        currentPageIndex = 5;
        navBarIndex = 0;
        isInDemo = false;
      }
      print('Login state: loggedIn=$loggedIn, isInDemo=$isInDemo, user=${user?.uid ?? 'null'}, currentPageIndex=$currentPageIndex');
    });
  }

  Future<void> loadCachedOrFirebaseProfiles({bool append = false, bool previous = false}) async {
    final geohasher = GeoHasher();    
    final Completer<List<Map<dynamic, dynamic>>> completer = Completer<List<Map<dynamic, dynamic>>>();

    await sqlite.DatabaseHelper.instance.clearCachedImages(); //////////////////////////////////////////////////////////////////////////////////////////
    await sqlite.DatabaseHelper.instance.clearAllSettings(); // Clears profiles too

    int targetPage = previous ? currentPage - 1 : currentPage;

    var cachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: targetPage, pageSize: pageSize);

    if (cachedProfiles.length >= pageSize || (cachedProfiles.isNotEmpty && !hasNextPage)) {  // Check for cached profiles
      print('Loaded ${cachedProfiles.length} profiles from SQLite cache for page $targetPage');
      setState(() {
        allCachedProfiles = append ? [...allCachedProfiles, ...cachedProfiles] : cachedProfiles;
        currentPage = targetPage;
        hasPreviousPage = currentPage > 1;
        profileData = Future.value(cachedProfiles);
      });
      completer.complete(cachedProfiles);
    } else {  // No cached profiles so get some from firestore
      print('Cache insufficient, fetching profiles from Firebase for page $targetPage');
      
      // Get the user location from sqlite to pass to the firestore query function
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      userLat = position.latitude;
      userLon = position.longitude;
      userGeohash = geohasher.encode(userLon, userLat, precision: 6);
      
      String optimalHash = await get_firestore_profiles.getOptimalGeohashPrefix(userGeohash);  // Find a geohash containing up to ~105 profiles to load all at once
      profiles = await get_firestore_profiles.fetchInitialEntries(nextDocId, optimalHash, userLat, userLon);  // These are the profiles, but they are also cached in the sqlite database
      
      nextDocId = profiles.isNotEmpty ? profiles.last['name'] : null;  // Handle pagination 
      hasNextPage = profiles.length >= pageSize;

      cachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: targetPage, pageSize: pageSize);  // The profiles are cached during the query function, so go ahead and grab the cached version of the profiles for debugging purposes
      
      setState(() {
        allCachedProfiles = append ? [...allCachedProfiles, ...cachedProfiles] : cachedProfiles;  // This 
        currentPage = targetPage;
        hasPreviousPage = currentPage > 1;
        profileData = Future.value(cachedProfiles);
      });
      completer.complete(cachedProfiles);  // The completer is needed to place the profiles back into a future for the grid builder. This may be uneccessary ??
    }

    profileData.then((profiles) => print('PageSelectBar: ProfileData: Loaded ${profiles.length} profiles'));
    setState(() {
      profileData = completer.future;
      //print('ProfileData: $profileData');
    });
  }

  Future<void> startRingAlgo() async{  // If i filter or rebuild while this is running I need to pause it and pick back up after
    final Completer<List<Map<dynamic, dynamic>>> completer = Completer<List<Map<dynamic, dynamic>>>();
    final additionalProfiles = await get_firestore_profiles.fetchProfilesInRings(nextDocId, radius, profiles, userGeohash);
    completer.complete(additionalProfiles);
    setState(() {  // Rebuild the widget tree- including all views -with fresh profiles
      profileData = completer.future;
    });
  }

  void addNewFilteredProfiles() {
    setState(() {
      //oldProfileData.length;
      profileData = sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: 1, pageSize: 105);  
      // if profileData < 105, load more    
    });
    print('added?');
  }

  void onNextPage() {
    setState(() {
      currentPage++;
      hasPreviousPage = true;
      loadCachedOrFirebaseProfiles(append: true);
    });
  }

  void onPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        hasNextPage = true;
        loadCachedOrFirebaseProfiles(append: false, previous: true);
      });
    }
  }

  void switchPage(int pageIndex, [int? databaseIndex]) {
    setState(() {
      currentPageIndex = pageIndex;
      selectedDatabaseIndex = databaseIndex;
      if (pageIndex == 0) {
        checkAndSetLogInState();
      }
      if (pageIndex >= 0 && pageIndex <= 3) {
        navBarIndex = pageIndex;
      }
      if (pageIndex == 5) {
        loggedIn = false;
      }
    });
  }

  void loadNewUserLocationBool() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasLocationValue = await sqlite.DatabaseHelper.instance.getHasLocation();
      if (mounted) {
        setState(() {
          hasLocationForNewAccount = hasLocationValue;
        });
      }
      print('Loaded hasLocation from SQLite: $hasLocationForNewAccount');
    });
  }

  void initialSendLocationToFB() {
    print('Triggering location prompt: loggedIn=$loggedIn, hasLocation=$hasLocationForNewAccount, currentPageIndex=$currentPageIndex');
    Future.microtask(() async {
      try {
        if (mounted) {
          List<double>? newLoc = await ProfileLocation.getLocation(context);
          if (mounted && newLoc != null) {
            await ProfileLocation.storeLocation(context, newLoc[0], newLoc[1]);
          }
        }
        if (mounted) {
          setState(() {
            hasLocationForNewAccount = true;
          });
        }
        print('Location saved and hasLocation set to true in SQLite');
      } catch (e) {
        print('Error running getAndStoreLocation: $e');
      }
    });
  }

  void createdAccount() {
    hasLocationForNewAccount = false;
  }

  void loggedInAccount() {
    hasLocationForLoggedInAccount = false;
  }

  void enterDemo() {
    setState(() {
      isInDemo = true;
      currentPageIndex = 0;
      navBarIndex = 0;
      profileData = getDemoProfiles();
    });
  }

  Widget createAccountButton() {
    return Draggable(
      feedback: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Create Account'),
        backgroundColor: Colors.grey,
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragEnd: (DraggableDetails details) {
        setState(() {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          const buttonWidth = 150.0;
          const buttonHeight = 56.0;
          const navBarHeight = 60.0;
          _dragX = (screenWidth - details.offset.dx - buttonWidth).clamp(0.0, screenWidth - buttonWidth);
          _dragY = (screenHeight - details.offset.dy - buttonHeight - navBarHeight).clamp(0.0, screenHeight - buttonHeight - navBarHeight);
        });
      },
      child: FloatingActionButton.extended(
        onPressed: () {
          switchPage(5);
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
    if (loggedIn && !hasLocationForNewAccount && currentPageIndex == 0) {
      initialSendLocationToFB();
    }

    if (!hasLocationForLoggedInAccount) {
      ProfileLocation.getLocation(context);
      hasLocationForLoggedInAccount = true;
    }

    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0x00FFFFFF),
      body: Stack(
        children: [
          IndexedStack(
            index: currentPageIndex,
            children: [
              database_page.DatabasePage(
                theme: theme,
                profileData: profileData,
                switchPage: switchPage,
                currentPage: currentPage,
                hasPreviousPage: hasPreviousPage,
                hasNextPage: hasNextPage,
                onPreviousPage: onPreviousPage,
                onNextPage: onNextPage,
                addNewFilteredProfiles: addNewFilteredProfiles,
                startRingAlgo: startRingAlgo
              ),
              swipe_page.SwipePage(
                profiles: profileData,
                databaseIndex: selectedDatabaseIndex,
                addNewFilteredProfiles: addNewFilteredProfiles
              ),
              messages_page.MessagePage(theme: theme),
              profile_page.ProfilePage(
                switchPage: switchPage,
              ),
              settings_page.SettingsPage(switchPage: switchPage),
              log_in_page.LogIn(
                switchPage: switchPage,
                enterDemo: enterDemo,
                createdAccount: createdAccount,
                loggedInAccount: loggedInAccount,
              ),
            ],
          ),
          if (isInDemo && currentPageIndex != 5)
            Positioned(
              right: _dragX,
              bottom: _dragY,
              child: createAccountButton(),
            ),
        ],
      ),
      bottomNavigationBar: currentPageIndex != 5
          ? NavigationBar(
              selectedIndex: navBarIndex,
              height: 60,
              backgroundColor: Color.fromARGB(255, 134, 142, 199),
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
                  child: NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/house.png'), size: 30),
                    selectedIcon: ImageIcon(AssetImage('assets/icons/house_filled.png'), size: 35),
                    label: '',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, left: 5, right: 5),
                  child: NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/stack.png'), size: 35),
                    selectedIcon: ImageIcon(AssetImage('assets/icons/stack_filled.png'), size: 38),
                    label: '',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, left: 5, right: 5),
                  child: NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/messages.png'), size: 40),
                    selectedIcon: ImageIcon(AssetImage('assets/icons/messages_filled.png'), size: 45),
                    label: '',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, left: 5, right: 25),
                  child: NavigationDestination(
                    icon: ImageIcon(AssetImage('assets/icons/profile.png'), size: 35),
                    selectedIcon: ImageIcon(AssetImage('assets/icons/profile_filled.png'), size: 40),
                    label: '',
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

/* import 'package:flutter/material.dart';
import 'dart:async'; // Added to ensure StreamSubscription is available
import 'package:firebase_auth/firebase_auth.dart';
import 'package:integra_date/pages/database_page.dart' as database_page;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/pages/messages_page.dart' as messages_page;
import 'package:integra_date/pages/profile_page.dart' as profile_page;
import 'package:integra_date/pages/settings_page.dart' as settings_page;
import 'package:integra_date/pages/log_in_page.dart' as log_in_page;
import 'package:integra_date/scripts/profile_location.dart';
import 'package:integra_date/databases/get_firestore_profiles.dart' as get_firestore_profiles; 
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;  // Import SQLite helper
import 'package:integra_date/databases/get_demo_profiles.dart';  // Get demo profiles

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
  double _dragX = 16.0; // Initial x position
  double _dragY = 80.0; // Initial y position (above bottom nav)

  bool hasLocationForNewAccount = false;
  bool hasLocatoinForLoggedInAccount = true;
  Future<List<double>?>? newLoc; 

  @override
  void initState() {
    super.initState();

    checkAndSetLogInState();  // Check log in state when app is built to bypass log in page if already logged in

    loadNewUserLocationBool();  // Load location bool whenever app is closed and reopened in case a new user didnt allow location permissions and set initial location
    
    // Defer context-dependent operations to after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still mounted
        ProfileLocation.getLocation(context);  // STORE
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    sqlite.DatabaseHelper.instance.close();
  }

  void checkAndSetLogInState() {  // Checks log in state on app start to direct users to the log in page if not logged in
    print('Checking Log In State!');
    // Listen for Firebase Auth state changes this apparently runs all the time
    // FirebaseAuth.instance.authStateChanges().listen((User? user) {  DONT USE THIS ITS EXPENSIVE 
    final user = FirebaseAuth.instance.currentUser;
      setState(() {
        // Set loggedIn to true if there's a Firebase user 
        loggedIn = user != null;

        if (loggedIn) { 
          currentPageIndex = 0; // Go to main page (e.g., dashboard)

          loadCachedOrFirebaseProfiles();  // Once logged in load the cahed profiles or get profiles from firebase if the cache is deleted

          isInDemo = false;
        } else {
          currentPageIndex = 5; // Go to login page
          isInDemo = false;
        }
        print('Login state: loggedIn=$loggedIn, isInDemo=$isInDemo, user=${user?.uid ?? 'null'}, currentPageIndex=$currentPageIndex');
      });
  }

  // Sorting by distnace may be useful if the cloud function doesnt sort
  // Future<void> loadCachedOrFirebaseProfiles({
  //   List<String> sortAttributes = const ['distance'], // Default sort by distance
  // }) async {
    
  //   // ... old code was here ...
    
  //   // Apply sorting
  //   // profileData = ProfileManager.sortProfiles(profileData, sortAttributes);  LETS SEE WHAT IT'S LIKE WITHOUT SORTING FIRST
  //   // print('Loaded ${profileData.length} profiles after sorting by distance');
  // }

  Future<void> loadCachedOrFirebaseProfiles() async {
    final Completer<List<Map<dynamic, dynamic>>> completer = Completer<List<Map<dynamic, dynamic>>>();

    final cachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles();
    
    if (cachedProfiles.isNotEmpty) {
      print('Loaded ${cachedProfiles.length} profiles from SQLite cache');
      completer.complete(cachedProfiles);
    } else {
      print('SQLite cache empty, fetching first 100 profiles from Firebase');
      final profiles = await get_firestore_profiles.fetchInitialEntries(); // First 100 profiles
      await sqlite.DatabaseHelper.instance.cacheAllOtherUserProfiles(profiles);
      completer.complete(profiles);
    }

    profileData = completer.future;
    
    // Apply sorting
    // profileData = ProfileManager.sortProfiles(profileData, sortAttributes);  LETS SEE WHAT IT'S LIKE WITHOUT SORTING FIRST
    // print('Loaded ${profileData.length} profiles after sorting by distance');
  }

  void getFirestoreProfiles() {
    profileData = (loggedIn || isInDemo)
        ? get_firestore_profiles.fetchInitialEntries() // Use original Firebase fetch for both logged in and demo
        : Future.value([]); // Empty if on login page        
  }

  void switchPage(int pageIndex, [int? databaseIndex]) {
    setState(() {
      currentPageIndex = pageIndex;
      selectedDatabaseIndex = databaseIndex; // Update selected profile index

      if (pageIndex == 0) {  // leave this here to recheck for log in status once page is switched by log in 
        checkAndSetLogInState();  // only problem is redundancy every time page is switched to 0
      }

      if (pageIndex >= 0 && pageIndex <= 3) {  // Only use nav bar if page in nav bar page range
        navBarIndex = pageIndex;
      }

      if (pageIndex == 5) {  // If page is log in page set logged in to false
        loggedIn = false;
      }
    });
  }

  void loadNewUserLocationBool () {
    // Load hasLocation from SQLite
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasLocationValue = await sqlite.DatabaseHelper.instance.getHasLocation();
      setState(() {
        hasLocationForNewAccount = hasLocationValue;
      });
      print('Loaded hasLocation from SQLite: $hasLocationForNewAccount');
    });
  }

  void initialSendLocationToFB() {  // This is only called one time for new accounts. After this location is updated every time the user opens the app. When the user has moved >20 miles from the initial location (set when creating the account), a new location is auto sent to firebase in profile_location.dart.
    print('Triggering location prompt: loggedIn=$loggedIn, hasLocation=$hasLocationForNewAccount, currentPageIndex=$currentPageIndex');
    Future.microtask(() async {
      try {
        if (mounted) {
          List<double>? newLoc = await ProfileLocation.getLocation(context); 
          if (mounted) {
            await ProfileLocation.storeLocation(context, newLoc![0], newLoc[1]);
          }
        }
        // await DatabaseHelper.instance.setHasLocation(true);  dont do this here to avoid setting to true when the firebase data does not import. See profile_location for settings update
        setState(() {
          hasLocationForNewAccount = true;
        });
        print('Location saved and hasLocation set to true in SQLite');
      } catch (e) {
        print('Error running getAndStoreLocation: $e');
      }
    });
  }

  void createdAccount() {  // This is for when users create a new account without loggingg out. The location is requested until comlete every time the app is restarted, but if the user recreates account without restarting then this callback is called to request the location again. 
    hasLocationForNewAccount = false; // Reset hasLocation when creating new account without logging out
  }

  void loggedInAccount() {  // Location is recollected every time the user logs out and logs back in i guess
    hasLocatoinForLoggedInAccount = false;
  }

  void enterDemo() {
    setState(() {
      isInDemo = true;
      currentPageIndex = 0; // Switch to database page for demo
      profileData = getDemoProfiles();  // Load fake profile data
    });
  }

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
  Widget build(BuildContext context) {  // This is rebuilt every time it is pressed
    if (loggedIn && !hasLocationForNewAccount && currentPageIndex == 0) {
      initialSendLocationToFB();  // STORE
    }

    if (!hasLocatoinForLoggedInAccount) {
      ProfileLocation.getLocation(context);  // This gets location and sends to fire base if >20 miles from the last stored location
      hasLocatoinForLoggedInAccount = true;
    }

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
                createdAccount: createdAccount,
                loggedInAccount: loggedInAccount
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
} */