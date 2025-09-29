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
import 'package:geolocator/geolocator.dart' as geolocator;

import 'package:integra_date/widgets/permissions_popup.dart' as permissions_popup;

import 'package:integra_date/scripts/create_profile_url.dart' as create_profile_url;
import 'package:firebase_analytics/firebase_analytics.dart'; // Add this

// This turns keeps the ring algo from restarting if a query is occurring 
bool runningRings = false;
void toggleRings(bool running) {
  runningRings = running;
}

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
  int radius = 10;  // initial radius ('distance') set to 10 miles in squlite_database.dart
  int currentPage = 1;
  final int pageSize = 105;
  bool hasNextPage = true;
  bool hasPreviousPage = false;
  List<Map<dynamic, dynamic>> allCachedProfiles = [];

  late double userLat;  // These are used to cache profiles without having to check the sqlite database for location. If the location updated in the database quickly enough these would not be needed. 
  late double userLon;
  late String userGeohash;

  late int targetPage;

  List radiusArgsCached = [];

  bool cacheSuccessful = false;

  bool showSettingsPopup = false; // New state for popup

  bool permissionGranted = false;

  int pageCount = 0; 
  int filteredPageCount = 0;

  bool noRebuildAfterRadiusIncrease = false;

  Map<dynamic, dynamic>? searchedProfile;

  @override
  void initState() {
    super.initState();    
    setQueryDistance();  // Required to load in initial filter value as query distance
    checkAndSetLogInState();
  }

  @override
  void dispose() {
    super.dispose();
    sqlite.DatabaseHelper.instance.close();
  }

  Future<void> refreshData() async{
    setState(() {

    });
  }

  Future<void> setQueryDistance() async {
    final distance = await sqlite.DatabaseHelper.instance.getFilterValue('distance');
    final lastRadius = radius;

    if (mounted) {
      setState(() {
        radius = int.parse(distance?.replaceAll(' mi', '') ?? '5');
      });
      print('PageSelectBar: Loaded radius: $radius mi');
    }
  }

  Future<void> checkAndSetLogInState() async{
    print('Checking Log In State!');
    final user = FirebaseAuth.instance.currentUser;
    //final user = null;

    // print('Firestore instance: ${FirebaseFirestore.instance.app.name}');

    setState(() {
      loggedIn = user != null;
      if (loggedIn) {
        print('Authenticated user UID: ${user!.uid}');

        // Initialize DeepLinkHandler
        final deepLinkHandler = create_profile_url.DeepLinkHandler(switchPage: switchPage);
        FirebaseAnalytics.instance.logAppOpen(); // Track app open  // This can be waited on (future) but im testing it without
        deepLinkHandler.initDeepLinks();

        //deepLinkHandler.handleDeepLink(('https://integridate.web.app/user_ids/5678902102') as Uri);

        currentPageIndex = 0;
        navBarIndex = 0;
        isInDemo = false;
      } else {
        currentPageIndex = 5;
        navBarIndex = 0;
        isInDemo = false;
      }
      print('Login state: loggedIn=$loggedIn, isInDemo=$isInDemo, user=${user?.uid ?? 'null'}, currentPageIndex=$currentPageIndex');
    });

    if (loggedIn && !hasLocationForNewAccount && currentPageIndex == 0) {
      print('attempting to get initial location');
      permissionGranted = await sendLocation();
    }

    if (loggedIn && permissionGranted) {
      print('Location permissions are allowed and location is confirmed. Loading profiles.');
      await loadCachedOrFirebaseProfiles();  // Location permissions need to be set before this runs or the app will crash.
    }
  }

  Future<void> loadCachedOrFirebaseProfiles({bool append = false, bool previous = false}) async {  
    final geohasher = GeoHasher();    

    // Get the user location from sqlite to pass to the firestore query function
    geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.high);  // This is why location permissions must be set before the function call.
    userLat = position.latitude;
    userLon = position.longitude;
    userGeohash = geohasher.encode(userLon, userLat, precision: 6);  // MAKE SURE ALL GEOHASHES ARE 6 PRECISION
    
    Completer<List<Map<dynamic, dynamic>>> completer = Completer<List<Map<dynamic, dynamic>>>();  // completer for appending future to the profileData type for the future builders in the database page 

    targetPage = currentPage;

    List<Map<dynamic, dynamic>> pageCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: targetPage, pageSize: pageSize);
    int totalCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();

    if (pageCachedProfiles.length < pageSize) {  // Disable next page button if the profiles on the current page are less than the page limit
      hasNextPage = false;
    }
    if (totalCachedProfiles - (currentPage * pageSize) == 0) {  // Disable next page button if the last profile is the last item on the last page
      hasNextPage = false;
    }

    List<int> cachedRadii = await sqlite.DatabaseHelper.instance.getCachedRadii();

    int remainingCachedProfiles = totalCachedProfiles - (pageSize * currentPage);  // Restart ring queries if the user paginates enough
    print('contains current radius: ${!cachedRadii.contains(radius)}');
    if (remainingCachedProfiles < 210 && totalCachedProfiles != 0 && !runningRings && !cachedRadii.contains(radius)) {  // !runningRings prevents this from restarting the ring algo if it is already going. This is for when the next page paginator is clicked
      print('\n\n');
      print('This is the pagination ring loader! Profiles remaining in cache: $remainingCachedProfiles');
      cacheSuccessful = false; 

      if (remainingCachedProfiles > -105) {
        await getTotalPageCount(); // Await getTotalPageCount before setState
        setState(() {
          allCachedProfiles = append ? [...allCachedProfiles, ...pageCachedProfiles] : pageCachedProfiles;
          currentPage = targetPage;
          hasPreviousPage = currentPage > 1;
          profileData = Future.value(pageCachedProfiles);
        });
      }

      await startRingAlgo();  // This continues the ring algo from where it left off. 

      print('Loaded ${pageCachedProfiles.length} profiles from SQLite cache for page $targetPage');
      
      return;  // This avoids rebuilding the database page again in the cache without ring query section below. 
    }

    print('Length of total cachedProfiles database for all pages without filters $totalCachedProfiles');
    print('Length of cachedProfiles for current page after fitlers: ${pageCachedProfiles.length}');

    // There also needs to be a bool that tracks when a distance has been queried from firebase already.
    // If there are only 104 profiles within that distance, the cache should be displayed without trying to load them in for that distance again.
    // Not sure if I should allow people to change the distance to include >105, then go back to the <105 distance and try to reload again after the bool has been reset
    // In other words not sure when I should reset the bool

    // get profiles from cache IF page count is larger than max page count, IF page cache is not empty and this is the last page, IF total cache count is greater than the max page count 
    // AND if the current distance filter has been fully cached
    if (pageCachedProfiles.length >= pageSize || 
    (pageCachedProfiles.isNotEmpty && !hasNextPage) || 
    totalCachedProfiles >= pageSize ||
    radiusArgsCached.contains(radius)    
    ) {  // Check for cached profiles and load the appropriate page
      print('This is the load cached profiles without ring algo section.');
      print('Loaded ${pageCachedProfiles.length} profiles from SQLite cache for page $targetPage');
      
      await getTotalPageCount(); // Await getTotalPageCount before setState
      setState(() {
        allCachedProfiles = append ? [...allCachedProfiles, ...pageCachedProfiles] : pageCachedProfiles;
        currentPage = targetPage;
        hasPreviousPage = currentPage > 1;
        profileData = Future.value(pageCachedProfiles);
      });
      completer.complete(pageCachedProfiles);

      cacheSuccessful = true; 
    } 
    else {  // No cached profiles so get an initial query from firestore
      print('Cache insufficient, fetching profiles from Firebase for page $targetPage');
      
      String optimalHash = await get_firestore_profiles.getOptimalGeohashPrefix(userGeohash);  // Find a geohash containing up to ~105 profiles to load all at once
      await get_firestore_profiles.fetchInitialEntries(nextDocId, optimalHash, userLat, userLon);  // These are the profiles, but they are also cached in the sqlite database

      int totalCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();  // CHECK change to current page length
      hasNextPage = totalCachedProfiles >= pageSize;

      pageCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: targetPage, pageSize: pageSize);  // The profiles are cached during the query function, so go ahead and grab the cached version of the profiles for debugging purposes
      
      await getTotalPageCount(); // Await getTotalPageCount before setState
      setState(() {
        allCachedProfiles = append ? [...allCachedProfiles, ...pageCachedProfiles] : pageCachedProfiles;  // This doesn't seem to be used
        currentPage = targetPage;
        hasPreviousPage = currentPage > 1;
        profileData = Future.value(pageCachedProfiles);
      });
      completer.complete(pageCachedProfiles);  // The completer is needed to place the profiles back into a future for the grid builder. This may be uneccessary ?? 
    }

    // if the distance arg has not been checked and the page is incremented, firestore should be queried. 
    // To do so, load the next cached page first (above), then run the code block in the else above in a function under the else,
    // since the else is not accessible after loading the next cached page.   

    // OH WAIT NO ALL I NEED TO DO IS CONTINUE GETTING RINGS

    //profileData.then((profiles) => print('PageSelectBar: ProfileData: Loaded ${profiles.length} profiles'));
    // if (noRebuildAfterRadiusIncrease) {
    //   setState(() {
    //     profileData = completer.future;
    //   });
    // } else {
    //   profileData = completer.future;
    //   noRebuildAfterRadiusIncrease = false;
    // }

    // setState(() {
    //   profileData = completer.future;
    // });
  }

  Future<void> startRingAlgo() async{  // If i filter or rebuild while this is running I need to pause it and pick back up after
    List<int> cachedRadiiArgs = await sqlite.DatabaseHelper.instance.getCachedRadii();
    print('current radius $radius');
    print('cached radii $cachedRadiiArgs');
    if (cachedRadiiArgs.contains(radius)) {  // Without this check the algo runs after every build of the database page, but it should only run once after getting the firestore proifles the first time.
      return;
    }

    if (cacheSuccessful) {  // Do not start the ring algo after an inital cache is built in the database page. The database page will attempt to get ring queries after building. 
      return;
    }

    if (runningRings) {
      return;
    }
    
    final Completer<List<Map<dynamic, dynamic>>> completer = Completer<List<Map<dynamic, dynamic>>>();
    
    await get_firestore_profiles.fetchProfilesInRings(radius, userGeohash);  // This function also caches the profiles, so go ahead and retrieve the profiles from the cache instead of the immediate result returned

    // sqlite.DatabaseHelper.instance.cacheCollectedRadiusArg(radius); dont do this here bc the ring algo stops queries after 210 profiles, not after the full radius is searched. This should be done in the ring algo only if the final ring is collected // Add the radius just FULLY cached to the radiusArgsCached list so that the grid isnt checked again  

    List<Map<dynamic, dynamic>> cachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: targetPage, pageSize: pageSize);  // The profiles are cached during the query function, so go ahead and grab the cached version of the profiles so that you only get the ones for that populate the appropriate page
    completer.complete(cachedProfiles);

    int totalCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();  // This is needed to check if total cached profiles is greater than the page size, which if true will allow the pagination button to work

    await getTotalPageCount();
    if (pageCount > 105) {
      setState(() {  // Rebuild the widget tree- including all views -with fresh profiles, but only if page one is not full. Otherwise the additional profiles can be found in the cache for later
        hasNextPage = totalCachedProfiles >= pageSize && totalCachedProfiles - currentPage * pageSize != 0;  // Allow pagination button to work, but only if there are more profiles
        profileData = completer.future;  // This should be from the cache, but i need to fix pagination first. 
      });
    }
  }

  Future<void> addNewFilteredProfiles([bool? onlyDistanceChanged]) async{  // This function runs after saving the filters in the filter menu. It updates the profile data list with the filtered profiles, that are then passed to aoll pages below.    
    late int page;
    setQueryDistance();  // This sets the new max query distance if it has changed 
    await getTotalPageCount(); // Await getTotalPageCount before setState

    // Find the largest radius that has been depleted so far 
    List<int> cachedRadii = await sqlite.DatabaseHelper.instance.getCachedRadii();
    late int largestRadius;
    if (cachedRadii.isNotEmpty) {
      largestRadius = cachedRadii.reduce((a, b) => a > b ? a : b);
    } else {
      largestRadius = 0;
    }

    // Set the page to current page if the updated radius arg is larger than the the already cached radii. This is so that the page doesn't go back to 1 when the distance filter is set to a greateer distance 
    print(radius);
    print(largestRadius);
    if (radius > largestRadius && largestRadius != 0) {  // Say the filteres are set to 5 miles. The 5 mile radius includes hashes outside the 5 mile radius. So when the filters are set to 10 miles, the ring algo generates a new list of hashes, and then when the '5 mile radius' list is finally complete, it doesn't know to save it, so the largest radius is still 0 az the 10 mile radius is being cached. This means the page will not reset when filters are set to 5 after the first half of the 10 mile radius is cached. So check of the largest radius is still 0 instead of trying to keep track of the radius hash in the hash lists.  
      page = currentPage;
      noRebuildAfterRadiusIncrease = true;  // After a bit more thinking it seems that the radius will never be cached. I should keep track of the hashes that are at the end of each radius. Or risk always reseting to page one. It should be fine if it always resets becuase the user can use the cupertino picker.
    } else {
      page = 1;
    }

    // print('page $page');

    setState(() {
      currentPage = page;
      hasPreviousPage = false;
      profileData = sqlite.DatabaseHelper.instance.getAllOtherUserProfiles(page: page, pageSize: 105);  // This applies the filters that were saved   
    });
    
    print('r $radius');
    int totalCachedProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();
    int remainingCachedProfiles = totalCachedProfiles - (pageSize * currentPage);  // Restart ring queries if the cache is depleted and the user changed the max distance
    int remainingFilteredProfiles = await sqlite.DatabaseHelper.instance.getFilteredProfilesCount();
    if (remainingCachedProfiles < 210 && totalCachedProfiles != 0 && !cachedRadii.contains(radius) || remainingFilteredProfiles < 210 && !cachedRadii.contains(radius)) {  // CHECK so it would really help if I knew the hash that should trigger the radius cache, because rt now the next radius rings are started without bothering to cache the old radius because it is only cached if the very last one is hit.  
      print('\n\n');
      print('Profiles remaining in cache: $remainingCachedProfiles');
      cacheSuccessful = false; 
      await startRingAlgo();  // This continues the ring algo from where it left off but will not run if the current radius has already been depleted.
      // If it is already running, then when the user filters again the ring algo will know not to restart
    }
  }

  Future<void> getTotalPageCount() async{
    // int totalProfiles = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();
    // pageCount = (totalProfiles / 105).ceil();
    int filteredProfiles = await sqlite.DatabaseHelper.instance.getFilteredProfilesCount(); 
    print(filteredProfiles);
    filteredPageCount = (filteredProfiles / 105).ceil();
    pageCount = filteredPageCount;
    print('filteredPageCount: ${filteredPageCount}');
  }

  Future<void> onNextPage([int? cupertinoDestination]) async{
    print('\n\n');
    print('Next page clicked');
    print('\n\n');
    
    if (cupertinoDestination == null) {
      currentPage++;
      hasPreviousPage = true;
    } else {
      currentPage = cupertinoDestination;
    }

    await loadCachedOrFirebaseProfiles(append: true);  // This loads the next page of cached profiles
  }

  Future<void> onPreviousPage([int? cupertinoDestination]) async{
    print('Previous page clicked');
    
    if (cupertinoDestination == null) {
      if (currentPage > 1) {
        currentPage--;
      }
    } else {
      currentPage = cupertinoDestination;
    }

    if (currentPage == 1){  // when on the first page disable the previous page button to avoid errors
      hasPreviousPage = false;
    }

    hasNextPage = true;  // Enable the next bage button
    await loadCachedOrFirebaseProfiles(append: false, previous: true);
  }

  void switchPage(int pageIndex, [int? databaseIndex, Map<dynamic, dynamic>? profileFromSearch]) {
    if (mounted) {
      setState(() {
        currentPageIndex = pageIndex;
        selectedDatabaseIndex = databaseIndex;
        if (pageIndex == 0) {  // List view page
          checkAndSetLogInState();
        }
        if (pageIndex == 1 && profileFromSearch != null) {
          print('switchPage() setting searchedProfile: $profileFromSearch');
          searchedProfile = profileFromSearch;
        }
        if (pageIndex >= 0 && pageIndex <= 3) {  // Nav bar pages
          navBarIndex = pageIndex;
        }
        if (pageIndex == 5) {  // Log in page
          loggedIn = false;
        }

        // Debugging
        if (pageIndex == 1) {
          print('\n\n');
          print('Swipe page accessed now!');
          print('\n\n');
        } 
      });
    }
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

  Future<bool> sendLocation() async{
    print('Triggering location prompt: loggedIn=$loggedIn, hasLocation=$hasLocationForNewAccount, currentPageIndex=$currentPageIndex');
    try {
      if (mounted) {
        List<double>? location = await ProfileLocation.getLocation(context, settingsButton);  // This checks the current location and if there is no previously saved location in sqlite, store it as the central location. If there is a previously stored location, it compares it to the current location and updates the central location if the user has moved past the threshold (~20 miles) 
        return location != null ? true : false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error running getAndStoreLocation: $e');
      return false;
    }
  }

  Future<void> startNewQuery() async{
    // If the user travels past the distance threshold, the old profiles can stay, but there distance values should be updated to reflect the new distance
    // The distance values should NOT be updated every time the app opens, as this would allow stalking. 

    // In addition to updating the distances, a new query should start from the new location, avoiding redundant profiles. 
    // In fact, it might be easier to clear the cache and just start over. 

    // That's what I'll start with, and later I may start a new query while checking firebase for the cached profiles.  
  }

  void settingsButton() {
    if (mounted) {
      permissions_popup.PermissionPopup.show(
        context,
        () {  // onRetry
          if (mounted) {
            checkAndSetLogInState(); // Re-check permissions
          }
        },
        () {  // onLogout
          if (mounted) {
            setState(() {
              loggedIn = false;
              currentPageIndex = 5;
              navBarIndex = 0;
              isInDemo = false;
            });
          }
        },
      );
    }
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
    if (!hasLocationForLoggedInAccount) {  ////////////////////////////////////////
      ProfileLocation.getLocation(context, settingsButton);
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
                startRingAlgo: startRingAlgo,
                pageCount: pageCount,
                filteredPageCount: filteredPageCount,
              ),
              swipe_page.SwipePage(
                profiles: profileData,
                databaseIndex: selectedDatabaseIndex,
                addNewFilteredProfiles: addNewFilteredProfiles,
                searchedProfile: searchedProfile
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