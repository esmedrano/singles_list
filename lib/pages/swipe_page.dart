import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;
import 'package:integra_date/widgets/sort_menu.dart' as sort_menu;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' show _getImagePath;
import 'dart:io';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/scripts/save_profile_to_list.dart' as save_profile_to_list; 
import 'package:integra_date/scripts/create_profile_url.dart' as create_profile_url;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view; 

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
void resetIndexAfterFiltering() {  // This is triggered by pressing the apply filters button
  resetIndexAfterFilter = true;
}

class SwipePageWrapper extends StatefulWidget {
  const SwipePageWrapper({
    super.key,
    required this.profiles,
    this.databaseIndex,
    required this.addNewFilteredProfiles,
    required this.searchedProfile,
  });

  final Future<List<Map<dynamic, dynamic>>> profiles;
  final int? databaseIndex;
  final Function(bool?) addNewFilteredProfiles;
  final Map<dynamic, dynamic>? searchedProfile;

  @override
  SwipePageWrapperState createState() => SwipePageWrapperState();
}

class SwipePageWrapperState extends State<SwipePageWrapper> {


  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Child SwipePage with profile content
          SwipePage(
            profiles: widget.profiles,
            databaseIndex: widget.databaseIndex,
            addNewFilteredProfiles: widget.addNewFilteredProfiles,
            searchedProfile: widget.searchedProfile,
          ),

          // // Sort and Filter buttons
          // Positioned(
          //   child: Padding(
          //     padding: const EdgeInsets.only(top: 5, right: 10),
          //     child: Align(
          //       alignment: Alignment.topRight,
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           sort_menu.SortersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
          //           filters_menu.FiltersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
          //         ],
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
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
    print('swipe_page.dart: Loaded lists from swipe page');
    final currentProfile = await _getCurrentProfile();
    if (currentProfile != null) {
      profileSaved = await save_profile_to_list.ProfileListManager.isProfileSaved('saved', currentProfile['hashedId']);
      profileLiked = await save_profile_to_list.ProfileListManager.isProfileSaved('liked', currentProfile['hashedId']);
      profileDisliked = await save_profile_to_list.ProfileListManager.isProfileSaved('disliked', currentProfile['hashedId']);
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
    
    return holderSnapshot.isNotEmpty ? holderSnapshot[profileIndex] : null;
  }

  Future<void> _toggleProfile(String listName, bool isCurrentlyInList) async {
    final currentProfile = await _getCurrentProfile();
    if (currentProfile == null) return;

    await save_profile_to_list.ProfileListManager.toggleProfileInList(
      listName: listName,
      profileHashedId: currentProfile['hashedId'] as String,
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
            if (profileLiked) {
              profileDisliked = false;
            }
            // Notify BannerView of state change
            banner_view.notifyProfileStateChange(currentProfile['hashedId'], profileLiked, profileDisliked);
          } else if (listName == 'disliked') {
            profileDisliked = state['profileSaved'] as bool;
            if (profileDisliked) {
              profileLiked = false;
            }
            // Notify BannerView of state change
            banner_view.notifyProfileStateChange(currentProfile['hashedId'], profileLiked, profileDisliked);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Swipe page building now!');
    //print('searchedProfile: ${widget.searchedProfile}');
    
    //_loadProfiles();  // Set the saved, liked, and disliked bools to true if the profile is in any of those lists

    List<Map<dynamic, dynamic>> profiles = [];

    Future<void> nextProfile() async{  
      print('next profile');
      setState(() {
        if (widget.searchedProfile != null && !hasDisplayedSearchedProfile) {
          print('Mark searchedProfile as displayed and reset index for next profiles');
          hasDisplayedSearchedProfile = true;
          
          profileIndex = 0;
          print('swipe page: profileIndex: $profileIndex');
        } else {
          // Move to next profile in the list
          profileIndex += 1;
          if (profileIndex >= profiles.length) {
            profileIndex = 0;
          }
          print('swipe page: profileIndex: $profileIndex');
        }
      });
      await _loadProfiles(); // Reload profile states for the new profile
    }

    Future<void> previousProfile() async{  
      print('previous profile');
      setState(() {
        if (widget.searchedProfile != null && !hasDisplayedSearchedProfile) {
          print('Mark searchedProfile as displayed and reset index for next profiles');
          hasDisplayedSearchedProfile = true;
          
          profileIndex = 0;
          print('swipe page: profileIndex: $profileIndex');
        } else {
          // Move to next profile in the list
          profileIndex -= 1;
          if (profileIndex < 0) {
            profileIndex = profiles.length - 1;
          }
          print('swipe page: profileIndex: $profileIndex');
        }
      });
      await _loadProfiles(); // Reload profile states for the new profile
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
            padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
            children: [
              
              ///// PROFILE PICTURE /////

              Stack(
                children: [
                  Center(
                    child: SizedBox(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
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
              
              ///// PROFILE CONTAINER /////
              
              Container(
                margin: EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 151, 160, 210),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                child: Column(
                  children: [
                    
                    ///// INFO /////

                    Container(
                      margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
                      //padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: const Color.fromARGB(255, 196, 205, 255),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.6),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentProfile['name']?.toString() ?? 'Unknown',
                                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                                ),
                                Column(
                                  children: [
                                    if (profileLiked)
                                      SizedBox(
                                        height: 20,
                                        child: Row(
                                          children: [
                                            Text('liked', style: TextStyle(fontStyle: FontStyle.italic)),
                                            SizedBox(width: 10),
                                            SizedBox(width: 20, child: Image.asset('assets/icons/heart.png')),
                                          ],
                                        ),
                                      ),
                                    if (profileDisliked)
                                      SizedBox(
                                        height: 20,
                                        child: Row(
                                          children: [
                                            Text('disliked', style: TextStyle(fontStyle: FontStyle.italic)),
                                            SizedBox(width: 10),
                                            SizedBox(width: 20, child: Image.asset('assets/icons/x.png')),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [  // If statements prevent blank text boxes from being displayed. 
                                if (currentProfile['age'] != null && (currentProfile['age'] != null ? currentProfile['age'] != '' : false))
                                Text(
                                  '${currentProfile['age']?.toString() ?? 'N/A'}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
                                ),

                                if (currentProfile['biology'] != null && (currentProfile['biology'] != null ? currentProfile['biology'] != '' : false))
                                const SizedBox(width: 25),
                                if (currentProfile['biology'] != null && (currentProfile['biology'] != null ? currentProfile['biology'] != '' : false))
                                Text(
                                  '${currentProfile['biology']?.toString() ?? ''}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
                                ),

                                if (currentProfile['height'] != null && (currentProfile['height'] != null ? currentProfile['height'] != '' : false))
                                const SizedBox(width: 25),
                                if (currentProfile['height'] != null && (currentProfile['height'] != null ? currentProfile['height'] != '' : false))
                                Text(
                                  '${currentProfile['height']?.toString() ?? 'N/A'}',
                                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
                                ),

                                if (currentProfile['distance'] != null && (currentProfile['distance'] != null ? currentProfile['distance'] != '' : false))
                                const SizedBox(width: 25),
                                if (currentProfile['distance'] != null && (currentProfile['distance'] != null ? currentProfile['distance'] != '' : false))
                                Text(
                                  '${currentProfile['distance']?.toString() ?? 'N/A'} mi',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              
                    /////// BUTTONS /////// 
                    
                    const SizedBox(height: 25),
              
                    Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black, width: 2), top: BorderSide(color: Colors.black, width: 2))
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () async{
                              await previousProfile();
                            },
                            icon: Icon(Icons.replay)
                          ),
                      
                          IconButton(
                            onPressed: () {
                              create_profile_url.DeepLinkHandler().shareProfileLink(currentProfile['hashedId']);
                            },
                            icon: const Icon(Icons.share, size: 25),
                          ),
                                    
                          SaveButton(
                            profile: currentProfile,
                          ),
                                    
                          IconButton(
                            onPressed: () async{
                              await nextProfile();
                            },
                            icon: Transform.scale(
                              scaleX: -1.0, // Mirrors horizontally
                              scaleY: 1.0,  // No vertical scaling
                              child: Icon(Icons.replay),
                            )
                          )
                        ]
                      ),
                    ),
                  
                    /////// INTRO ///////
                    
                    if (currentProfile['intro'] != null && (currentProfile['intro'] != null ? currentProfile['intro'] != '' : false))
                    Container(
                      margin: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
                      
                      //padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: const Color.fromARGB(255, 196, 205, 255),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.6),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(  // Keep this row to expand the intro box if the user does not add an intro. Also, go ahead and remove the intro box entirely if the user does not have one
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text('Intro:'),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text(
                              currentProfile['intro']?.toString() ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ]
                        ),
                      ),
                    ),

                    ///// TAGS /////
                    
                    if(currentProfile['tags'] != null && (currentProfile['tags'] != null ? currentProfile['tags'].isNotEmpty : false))
                    Container(
                      margin: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
                      //padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.black),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: const Color.fromARGB(255, 196, 205, 255),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.6),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text('Tags:'),
                              ],
                            ),
                            SizedBox(height: 15),
                            Wrap(
                              spacing: 8.0, // Space between chips
                              runSpacing: 4.0, // Space between rows
                              children: [
                                for (String tag in currentProfile['tags'])
                                Chip(
                                  color: WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210)),

                                  label: Text(tag, style: TextStyle(color: Color(0xFF000000))),
                                ),
                                // for (int x in [1, 1, 1, 1, 1, 1, 1, 1])
                                // Chip(
                                //   color: WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210)),

                                //   label: Text('tag', style: TextStyle(color: Color(0xFF000000))),
                                // )
                              ]
                            )
                          ]
                        ),
                      )
                    ),
                  
                    ///// CHILDREN /////
                    
                    if(currentProfile['children'] != null && (currentProfile['children'] != null ? currentProfile['children'] != '' : false))
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          Text('Children:'),
                          SizedBox(width: 15),
                          Chip(
                            color: WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210)),
                            label: Text(
                              currentProfile['children'],
                              style: TextStyle(color: Color(0xFF000000))
                            ),
                          ),
                        ],
                      ),
                    ),

                    ///// RELATIONSHIP INTENT /////
                    
                    if(currentProfile['relationship_intent'] != null && (currentProfile['relationship_intent'] != null ? currentProfile['relationship_intent'].isNotEmpty : false))
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 15),
                      child: Row(
                        children: [
                          Text('Relationship intent:'),
                          SizedBox(width: 15),
                          Wrap(
                            spacing: 8.0, // Space between chips
                            runSpacing: 4.0, // Space between rows
                            children: [
                              for (String entry in currentProfile['relationship_intent'])
                              Chip(
                                color: WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210)),
                                label: Text(
                                  entry,
                                  style: TextStyle(color: Color(0xFF000000))
                                ),
                              ),
                            ]
                          ),
                        ],
                      ),
                    ),

                    ///// PERSONALITY TYPE /////

                    if(currentProfile['personality'] != null && (currentProfile['personality'] != null ? currentProfile['personality'] != 'none' : false))
                    Chip(
                      color: WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210)),
                      label: Text(
                        currentProfile['personality'],
                        style: TextStyle(color: Color(0xFF000000))
                      ),
                    ),
                  ],
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

class SaveButton extends StatefulWidget {
  const SaveButton({
    super.key,
    required this.profile,
  });

  final Map<dynamic, dynamic> profile;

  @override
  _SaveButtonState createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  bool profileSaved = false;

  @override
  void initState() {
    super.initState();
    _loadLikeDislikeStatus();
  }

  Future<void> _loadLikeDislikeStatus() async {
    profileSaved = await save_profile_to_list.ProfileListManager.isProfileSaved('saved', widget.profile['hashedId']);  
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleProfile(String listName, bool isCurrentlyInList) async {
    await save_profile_to_list.ProfileListManager.toggleProfileInList(
      listName: listName,
      profileHashedId: widget.profile['hashedId'] as String,
      profileData: widget.profile,
      isCurrentlySaved: isCurrentlyInList,
      context: context,
      setStateCallback: (Map<String, dynamic> state) {
        setState(() {
          if (listName == 'saved') {
            //profilesInList = state['profilesInList'] as List<Map<dynamic, dynamic>>;
            profileSaved = state['profileSaved'] as bool;
          // } else if (listName == 'liked') {
          //   profileLiked = state['profileSaved'] as bool;
          //   if (profileLiked) {
          //     profileDisliked = false;
          //   }
          // } else if (listName == 'disliked') {
          //   profileDisliked = state['profileSaved'] as bool;
          //   if (profileDisliked) {
          //     profileLiked = false;
          //   }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async{ 
        await toggleProfile('saved', profileSaved); // Toggle saved profile
      },
      isSelected: profileSaved,
      icon: const Icon(Icons.bookmark_border_rounded, size: 25),
      selectedIcon: const Icon(Icons.bookmark_added_rounded, size: 25),
    );
  }
}

class FilterAndSortButtons extends StatefulWidget {
  const FilterAndSortButtons({
    super.key,
    required this.addNewFilteredProfiles,
  });

  final Function(bool?) addNewFilteredProfiles;

  @override
  _FilterAndSortButtonsState createState() => _FilterAndSortButtonsState();
}

class _FilterAndSortButtonsState extends State<FilterAndSortButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          alignment: Alignment.topRight,
          child: sort_menu.SortersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
        ),
        Container(
          alignment: Alignment.topRight,
          child: filters_menu.FiltersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
        ),
      ]
    );
  }
}