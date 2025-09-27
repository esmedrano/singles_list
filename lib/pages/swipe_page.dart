import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' show _getImagePath;
import 'dart:io';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/scripts/save_profile_to_list.dart' as save_profile_to_list; 

bool hasDisplayedSearchedProfile = true; // Tracks if searchedProfile was shown
void toggleDisplaySearchFalse() {
  print('toggled false');
  hasDisplayedSearchedProfile = false;
}

void toggleDisplaySearchTrue() {
  print('toggled true');
  hasDisplayedSearchedProfile = true;
}

bool resetIndexAfterFilter = false;
void resetIndexAfterFiltering() {
  resetIndexAfterFilter = true;
}

class SwipePage extends StatefulWidget {
  const SwipePage({
    super.key,
    required this.profiles,
    this.databaseIndex,
    required this.addNewFilteredProfiles,
    required this.searchedProfile
  });

  final Future<List<Map<dynamic, dynamic>>> profiles;
  final int? databaseIndex;

  final Function(bool?) addNewFilteredProfiles;

  final Map<dynamic, dynamic>? searchedProfile;

  @override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  int profileIndex = 0;
  bool profileSaved = false;
  bool profileLiked = false;
  bool profileDisliked = false;
  List<Map<dynamic, dynamic>> profilesInList = []; // State variable for profiles

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(SwipePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.databaseIndex != oldWidget.databaseIndex) {
      print('new profile selected from database page');
      setState(() {
        //hasDisplayedSearchedProfile = true;
        profileIndex = widget.databaseIndex ?? 0;
        print('New index: $profileIndex');
      });
    } 
    _loadProfiles(); // Reload profiles when index changes
  }

  Future<void> _loadProfiles() async {
    print('Loaded lists from swipe page');
    final currentProfile = await _getCurrentProfile();
    if (currentProfile != null) {
      profileSaved = await save_profile_to_list.ProfileListManager.isProfileSaved('saved', currentProfile['name']);
      profileLiked = await save_profile_to_list.ProfileListManager.isProfileSaved('liked', currentProfile['name']);
      profileDisliked = await save_profile_to_list.ProfileListManager.isProfileSaved('disliked', currentProfile['name']);
      final savedProfiles = await save_profile_to_list.ProfileListManager.loadProfilesInList('saved');
      setState(() {
        profilesInList = savedProfiles;
      });
    }
  }

  Future<Map<dynamic, dynamic>?> _getCurrentProfile() async {
    final holderSnapshot = await widget.profiles;
    if (widget.searchedProfile != null && !hasDisplayedSearchedProfile) {
      return widget.searchedProfile!['profile_data'];
    }

    if (resetIndexAfterFilter) {  // The index stays at the last profile index after filtering (I am not sure why), but it should be reset to 0
      profileIndex = 0;
      resetIndexAfterFilter = false;
    }

    print('holderSnapshot.length ${holderSnapshot.length}');
    print('profileIndex $profileIndex');
    
    return holderSnapshot.isNotEmpty ? holderSnapshot[profileIndex] : null;
  }

  Future<void> _toggleProfile(String listName, bool isCurrentlyInList) async {
    final currentProfile = await _getCurrentProfile();
    if (currentProfile == null) return;

    await save_profile_to_list.ProfileListManager.toggleProfileInList(
      listName: listName,
      profileName: currentProfile['name'] as String,
      profileData: currentProfile,
      isCurrentlySaved: isCurrentlyInList,
      context: context,
      setStateCallback: (Map<String, dynamic> state) {
        setState(() {
          if (listName == 'saved') {
            profilesInList = state['profilesInList'] as List<Map<dynamic, dynamic>>;
            profileSaved = state['profileSaved'] as bool;
          } else if (listName == 'liked') {
            profileLiked = state['profileSaved'] as bool;
          } else if (listName == 'disliked') {
            profileDisliked = state['profileSaved'] as bool;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Swipe page building now!');
    //print('searchedProfile: ${widget.searchedProfile}');

    List<Map<dynamic, dynamic>> profiles = [];

    void nextProfile() {  
      print('next profile');
      setState(() {
        if (widget.searchedProfile != null && !hasDisplayedSearchedProfile) {
          print('Mark searchedProfile as displayed and reset index for next profiles');
          hasDisplayedSearchedProfile = true;
          
          profileIndex = 0;
          print(profileIndex);
        } else {
          // Move to next profile in the list
          profileIndex += 1;
          if (profileIndex >= profiles.length) {
            profileIndex = 0;
          }
          print(profileIndex);
        }
      });
      _loadProfiles(); // Reload profile states for the new profile
    }

    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: widget.profiles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          //print('SwipePage: Loading profiles...');
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          //print('SwipePage: Error loading profiles: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          //print('SwipePage: No profiles available');
          return const Center(child: Text('No profiles available'));
        }

        profiles = snapshot.data!;
        //print('SwipePage: Loaded ${profiles.length} profiles');

        // Use searchedProfile if it exists and hasn't been displayed
        final currentProfile = (widget.searchedProfile != null && !hasDisplayedSearchedProfile)
          ? widget.searchedProfile!['profile_data']
          : profiles[profileIndex];

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            children: [
              Stack(
                children: [
                  Center(
                    child: SizedBox(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: FutureBuilder<String?>(
                            future: _getImagePath(currentProfile['profilePic'], currentProfile['name']?.toString() ?? 'Unknown', context, profiles),
                            builder: (context, snapshot) {
                              //print('SwipePage: Loading profile image for ${currentProfile['name']}, profilePic=${currentProfile['profilePic']}, connectionState=${snapshot.connectionState}');
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final imagePath = snapshot.data;
                              if (imagePath == null || !File(imagePath).existsSync()) {
                                //print('SwipePage: No valid profile image for ${currentProfile['name']}');
                                return Container(
                                  color: Colors.grey,
                                  child: const Center(child: Icon(Icons.person, color: Colors.white, size: 48)),
                                );
                              }
                              //print('SwipePage: Displaying profile image $imagePath');
                              return Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 10,
                    child: Container(
                      alignment: Alignment.topRight,
                      child: filters_menu.FiltersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: SizedBox(
                      width: 90,
                      child: IconButton(
                        onPressed: () async{
                          await _toggleProfile('disliked', profileDisliked);
                          nextProfile();
                        },
                        icon: Image.asset('assets/icons/x.png'),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: SizedBox(
                      width: 100,
                      child: IconButton(
                        onPressed: () async{
                          await _toggleProfile('liked', profileLiked);
                          nextProfile();
                        },
                        icon: Image.asset('assets/icons/heart.png'),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentProfile['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            currentProfile['age']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            currentProfile['height']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentProfile['location']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            currentProfile['distance']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              for (var imagePath in (currentProfile['images'] as List<dynamic>? ?? []))
                Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: FutureBuilder<String?>(
                                  future: _getImagePath(imagePath, currentProfile['name']?.toString() ?? 'Unknown', context, profiles),
                                  builder: (context, snapshot) {
                                    ////print('SwipePage: Loading additional image for ${currentProfile['name']}, imagePath=$imagePath, connectionState=${snapshot.connectionState}');
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final resolvedPath = snapshot.data;
                                    if (resolvedPath == null || !File(resolvedPath).existsSync()) {
                                      ////print('SwipePage: No valid additional image for ${currentProfile['name']}');
                                      return Container(
                                        color: Colors.grey,
                                        child: const Center(child: Icon(Icons.image, color: Colors.white, size: 48)),
                                      );
                                    }
                                    //print('SwipePage: Displaying additional image $resolvedPath');
                                    return Image.file(
                                      File(resolvedPath),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(  // Dislike button
                          bottom: 20,
                          left: 20,
                          child: SizedBox(
                            width: 90,
                            child: IconButton(
                              onPressed: () async{
                                await _toggleProfile('disliked', profileDisliked);
                                nextProfile();  // Increment profiles list index
                              },
                              icon: Image.asset('assets/icons/x.png'),
                            ),
                          ),
                        ),
                        Positioned(  // Like button
                          bottom: 20,
                          right: 20,
                          child: SizedBox(
                            width: 100,
                            child: IconButton(
                              onPressed: () async{
                                await _toggleProfile('liked', profileLiked);
                                nextProfile();  // Increment profiles list index
                              },
                              icon: Image.asset('assets/icons/heart.png'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getImagePath(
      String? imagePath, String profileId, BuildContext context, profiles) async {
    // Use searchedProfile if it exists and hasn't been displayed
    final currentProfile = (widget.searchedProfile != null && !hasDisplayedSearchedProfile)
      ? widget.searchedProfile!['profile_data']
      : profiles[profileIndex];

    if (imagePath == null || !File(imagePath).existsSync()) {
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, currentProfile['images']?.isNotEmpty == true ? currentProfile['images'][0] : '');
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return cachedPath;
      }
      return null; // Return null instead of asset path
    }
    return imagePath;
  }
}

/* import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;

class SwipePage extends StatefulWidget {
  const SwipePage({
    super.key,
    required this.profiles,
    this.databaseIndex, 
  });

  final Future<List<Map<dynamic, dynamic>>> profiles;
  final int? databaseIndex;

  @ override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  int profileIndex = 0;

  @override
  void didUpdateWidget(SwipePage oldWidget) {  // Update profileIndex when a banner / grid view is selected in database mode
    super.didUpdateWidget(oldWidget);
    if (widget.databaseIndex != oldWidget.databaseIndex) {
      setState(() {
        profileIndex = widget.databaseIndex ?? 0;  
      });
    }
  }

  @override
  Widget build(BuildContext context) {  // Scoll of profile widgets
    dynamic profiles;
    
    void nextProfile() {
      setState( () {
        profileIndex += 1;  // Iterate to next profile
        if (profileIndex == profiles.length) {
          profileIndex = 0;
        }
      });
    }

    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: widget.profiles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No profiles available'));
        }

        profiles = snapshot.data!;

        return SafeArea(  
          child: ListView(
            padding: EdgeInsets.only(left: 10, right: 10, top: 10),
          
            children: [
              Stack(  
                children: [
                  Center(  // First image
                    child: SizedBox(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),  // Adjust radius for rounded corners
                        child: AspectRatio(aspectRatio: 4/5, child: Image.asset(currentProfile['profilePic'], fit: BoxFit.cover))
                      )
                    ),
                  ),
                  
                  Positioned(
                    top: 5,
                    right: 10,
                    child: Container(  // Filters menu
                      alignment: Alignment.topRight,
                      // padding: EdgeInsets.only(right: 0),
                      child: filters_menu.FiltersMenu()
                    ),
                  ),

                  Positioned(  // Dislike button
                    bottom: 20,
                    left: 20,
                    child: SizedBox(
                      width: 90,
                      child: IconButton(
                        onPressed: () {
                          nextProfile();
                        }, 
                        
                        icon: Image.asset('assets/icons/x.png')),
                    ),
                  ),
          
                  Positioned(  // Like button
                    bottom: 20,
                    right: 20,
                    child: SizedBox(
                      width: 100,
                      child: IconButton(
                        onPressed: () {
                          nextProfile();
                        }, 
                        
                        icon: Image.asset('assets/icons/heart.png')),
                    ),
                  ),
                ],
              ),
          
              Padding(  // Basic Info
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: Container(  // Background
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  
                  child: Column(  // Text
                    children: [
                      SizedBox(height: 25),
                      Row(  // Row one of text with each entry seperated for accurate spacing
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentProfile['name'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
          
                          SizedBox(width: 30),
          
                          Text(
                            currentProfile['age'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
          
                          SizedBox(width: 30),
          
                          Text(
                            currentProfile['height'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
                        ],
                      ),
          
                      SizedBox(height: 10),  // Space between the rows
                      
                      Row(  // Row two of text 
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(currentProfile['location'], 
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 30),
                          Text(currentProfile['distance'], 
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
                        ],
                      ),
                      SizedBox(height: 25)
                    ],
                  ),
                ),
              ),
          
              // Display tags
              
              for (var imagePath in currentProfile['images'])  // Display all other images
                Column(
                  children: [
                    Stack(
                      children: [
                      
                        Center(
                          child: SizedBox(
                            // width: MediaQuery.of(context).size.width - 80,
                            //height: 589,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10), // Adjust radius for rounded corners
                              child: AspectRatio(aspectRatio: 4/5, child: Image.asset(imagePath, fit: BoxFit.cover,))
                            )
                          ),
                        ),
                        
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: SizedBox(
                            width: 90,
                            child: IconButton(
                              onPressed: () {
                                nextProfile();
                              }, 
                              
                              icon: Image.asset('assets/icons/x.png')),
                          ),
                        ),
                      
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: SizedBox(
                            width: 100,
                            child: IconButton(
                              onPressed: () {
                                nextProfile();
                              }, 
                              
                              icon: Image.asset('assets/icons/heart.png')),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 15),
                  ],
                ),
            ],
          ),
        );
      }
    );  
  }
} */