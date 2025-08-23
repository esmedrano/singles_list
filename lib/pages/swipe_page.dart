import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' show _getImagePath;
import 'dart:io';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class SwipePage extends StatefulWidget {
  const SwipePage({
    super.key,
    required this.profiles,
    this.databaseIndex,
    required this.addNewFilteredProfiles
  });

  final Future<List<Map<dynamic, dynamic>>> profiles;
  final int? databaseIndex;

  final VoidCallback addNewFilteredProfiles;

  @override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  int profileIndex = 0;

  @override
  void didUpdateWidget(SwipePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.databaseIndex != oldWidget.databaseIndex) {
      setState(() {
        profileIndex = widget.databaseIndex ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<dynamic, dynamic>> profiles = [];

    void nextProfile() {
      setState(() {
        profileIndex += 1;
        if (profileIndex == profiles.length) {
          profileIndex = 0;
        }
      });
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
                            future: _getImagePath(profiles[profileIndex]['profilePic'], profiles[profileIndex]['name']?.toString() ?? 'Unknown', context, profiles),
                            builder: (context, snapshot) {
                              //print('SwipePage: Loading profile image for ${profiles[profileIndex]['name']}, profilePic=${profiles[profileIndex]['profilePic']}, connectionState=${snapshot.connectionState}');
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final imagePath = snapshot.data;
                              if (imagePath == null || !File(imagePath).existsSync()) {
                                //print('SwipePage: No valid profile image for ${profiles[profileIndex]['name']}');
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
                        onPressed: nextProfile,
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
                        onPressed: nextProfile,
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
                            profiles[profileIndex]['name']?.toString() ?? 'Unknown',
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
                            profiles[profileIndex]['age']?.toString() ?? 'N/A',
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
                            profiles[profileIndex]['height']?.toString() ?? 'N/A',
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
                            profiles[profileIndex]['location']?.toString() ?? 'N/A',
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
                            profiles[profileIndex]['distance']?.toString() ?? 'N/A',
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
              for (var imagePath in (profiles[profileIndex]['images'] as List<dynamic>? ?? []))
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
                                  future: _getImagePath(imagePath, profiles[profileIndex]['name']?.toString() ?? 'Unknown', context, profiles),
                                  builder: (context, snapshot) {
                                    ////print('SwipePage: Loading additional image for ${profiles[profileIndex]['name']}, imagePath=$imagePath, connectionState=${snapshot.connectionState}');
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final resolvedPath = snapshot.data;
                                    if (resolvedPath == null || !File(resolvedPath).existsSync()) {
                                      ////print('SwipePage: No valid additional image for ${profiles[profileIndex]['name']}');
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
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: SizedBox(
                            width: 90,
                            child: IconButton(
                              onPressed: nextProfile,
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
                              onPressed: nextProfile,
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
    if (imagePath == null || !File(imagePath).existsSync()) {
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, profiles[profileIndex]['images']?.isNotEmpty == true ? profiles[profileIndex]['images'][0] : '');
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
                        child: AspectRatio(aspectRatio: 4/5, child: Image.asset(profiles[profileIndex]['profilePic'], fit: BoxFit.cover))
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
                            profiles[profileIndex]['name'],
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
                            profiles[profileIndex]['age'],
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
                            profiles[profileIndex]['height'],
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
                          Text(profiles[profileIndex]['location'], 
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 30),
                          Text(profiles[profileIndex]['distance'], 
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
              
              for (var imagePath in profiles[profileIndex]['images'])  // Display all other images
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