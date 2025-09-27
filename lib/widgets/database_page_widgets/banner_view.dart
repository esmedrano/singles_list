import 'package:flutter/material.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:integra_date/widgets/share_popup.dart';
import 'package:integra_date/widgets/pagination_buttons.dart' as pagination_buttons;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/scripts/save_profile_to_list.dart' as save_profile_to_list; 

bool startedRingAlgo = false;
bool paginatingNext = false;
bool paginatingPrevious = false;

List profilesInList = [];

bool loadLists = false;
Future<void> loadListsAfterFiltering() async{
  loadLists = true;
}

class BannerView extends StatelessWidget {
  const BannerView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.switchPage,
    this.bannerH = 80,

    required this.startRingAlgo,  // From navigation_bar.dart. Updates the page with profiles after the ring algo query completes for the radius set in filters

    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.pageCount,
    required this.filteredPageCount,
  });

  final ScrollController scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final double initialOffset;
  final Function(int, int?, Map<dynamic, dynamic>?) switchPage;
  final double bannerH;
  static double profilePictureHeight = 0;  // Set in parent widget (database_page.dart). It is screen width - 10 
  static double bannerHeight = profilePictureHeight + 223;
  static double expandedPicturesHeight = 310;

  final VoidCallback startRingAlgo;

  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final Function([int?]) onPreviousPage;
  final Function([int?]) onNextPage;
  final int pageCount;
  final int filteredPageCount;

  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: profileData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No profiles available'));
        }

        final profiles = snapshot.data!;
        print('rebuilt banner view with ${profiles.length} profiles');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients && scrollController.offset != initialOffset && !paginatingNext && !paginatingPrevious) {
            scrollController.jumpTo(initialOffset.clamp(0.0, scrollController.position.maxScrollExtent));
          }

          if (paginatingNext) {  // If paginating to next page, be sure to start the next page at offset = 0 
            scrollController.jumpTo(0);  
            paginatingNext = false;
          }

          if (paginatingPrevious) {  // If paginating to previous page, be sure to start the next pageat max scroll controller offset
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
            paginatingPrevious = false;
          }
        });

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 30),
                controller: scrollController,
                itemCount: profiles.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == profiles.length - 1) {
                    //return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      BannerItem(
                        key: ValueKey('${profiles[index]['name']}_$loadLists'), // Unique key based on profile and loadLists
                        bannerHeight: bannerHeight,
                        profilePictureHeight: profilePictureHeight,
                        expandedPicturesHeight: expandedPicturesHeight,
                        profile: profiles[index],
                        index: index,
                        switchPage: switchPage,
                        startRingAlgo: startRingAlgo
                      ),

                      if (index == profiles.length - 1)  // The way this item builder iterates, an if statemnet is needed to be sure the pagination buttons are only built under the last banner item
                      pagination_buttons.PaginationButtons(
                        currentPage: currentPage,
                        hasPreviousPage: hasPreviousPage,
                        hasNextPage: hasNextPage,
                        onPreviousPage: ([int? cupertinoDestination]) {
                          onPreviousPage(cupertinoDestination);
                          paginatingPrevious = true;  
                        },
                        onNextPage: ([int? cupertinoDestination]) {
                          onNextPage(cupertinoDestination);
                          paginatingNext = true;  
                        },
                        pageCount: pageCount,
                        filteredPageCount: filteredPageCount,
                      ),
                    ],
                  ); 
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class BannerItem extends StatefulWidget {
  const BannerItem({
    super.key,
    required this.bannerHeight,
    required this.profilePictureHeight,
    required this.expandedPicturesHeight,
    required this.profile,
    required this.index,
    required this.switchPage,
    required this.startRingAlgo  // From navigation_bar.dart. Updates the page with profiles after the ring algo query completes for the radius set in filters
  });

  final double bannerHeight;
  final double profilePictureHeight;
  final double expandedPicturesHeight;
  final Map<dynamic, dynamic> profile;
  final int index;
  final Function(int, int?, Map<dynamic, dynamic>?) switchPage;

  final VoidCallback startRingAlgo;

  @override
  _BannerItemState createState() => _BannerItemState();
}

class _BannerItemState extends State<BannerItem> {
  bool picsAreExpanded = false;
  bool introIsExpanded = false;
  Offset? _tapPosition;
  bool profileSaved = false;
  bool profileLiked = false;
  bool profileDisliked = false;
  List<Map<dynamic, dynamic>> profilesInList = []; // State variable for profiles

  @override
  void initState() {  // This is called every time the page is rebuilt
    super.initState();
    if (loadLists) {
      _loadLists(true); // Pass true to reset loadLists after filtering
    } else {
      _loadLists(); // Normal load without resetting loadLists
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {  // After the page is fully built, the ring algo is used to continue getting profiles within the radius until the page is full
      if (!startedRingAlgo) {  // This is starting multiple times bc the page is rebuilding when I scroll so this is a global bool for debugging
        widget.startRingAlgo();  // This only goes once for now
        startedRingAlgo = true;
      }
    });
  }

  Future<void> _loadLists([bool afterFilter = false]) async {
    profileSaved = await save_profile_to_list.ProfileListManager.isProfileSaved('saved', widget.profile['name']);
    profileLiked = await save_profile_to_list.ProfileListManager.isProfileSaved('liked', widget.profile['name']);
    profileDisliked = await save_profile_to_list.ProfileListManager.isProfileSaved('disliked', widget.profile['name']);
    final profiles = await save_profile_to_list.ProfileListManager.loadProfilesInList('saved');
    setState(() {
      profilesInList = profiles;
      if (afterFilter) {
        loadLists = false; // Reset loadLists after filtering
      }
    });
  }
  
  Future<void> _toggleProfile(String listName, bool isCurrentlyInList) async {
    await save_profile_to_list.ProfileListManager.toggleProfileInList(
      listName: listName,
      profileName: widget.profile['name'] as String,
      profileData: widget.profile,
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
          } else if (listName == 'disliked') {
            profileDisliked = state['profileSaved'] as bool;
            if (profileDisliked) {
              profileLiked = false;
            }
          }
        });
      },
    );
  }

  void displayShareDialogue() async{
    setState(() {
      picsAreExpanded = true;
    });
    showBannerDialog(
      context: context,
      profile: widget.profile,
      index: widget.index,
      onMenuAction: (action) {
        print('$action selected for index ${widget.index}');
      },
      tapPosition: _tapPosition ?? Offset.zero,
      picsAreExpanded: false,
    );
  }

  void switchToSipeViewFromProfile() {
    widget.switchPage(1, widget.index, null);
    swipe_page.toggleDisplaySearchTrue();
  }
  
  Future<List<String?>?> _getImagePaths(List<String>? imagePaths, String profileId, BuildContext context) async {
    List<String?> cachedImages = [];
    if (imagePaths == null) {
      for (final path in imagePaths!) {
        cachedImages.add(await sqlite.DatabaseHelper.instance.getCachedImage(profileId, path));
      }
    }
    return cachedImages;
  }

  @override
  Widget build(BuildContext context) {
    //final profilePictures = _getImagePaths(widget.profile['profilePic'], widget.profile['name'], context);

    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
      child: InkWell(  // Tap controls
        onTap: () => picsAreExpanded = !picsAreExpanded,
        onDoubleTap: () {
          switchToSipeViewFromProfile();
        },
        onLongPress: () {
          displayShareDialogue();
        },
        onTapDown: (details) {
          setState(() {
            _tapPosition = details.globalPosition;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: BannerContent(
          bannerHeight: widget.bannerHeight,
          profilePictureHeight: widget.profilePictureHeight,
          expandedPicturesHeight: widget.expandedPicturesHeight,
          profile: widget.profile,
          //profilePictures: profilePictures,
          picsAreExpanded: picsAreExpanded,
          introIsExpanded: introIsExpanded,
          onProfileTap: () => showProfileDialog(
            context: context,
            imagePath: widget.profile['profilePic'],
            index: widget.index,
            onMenuAction: (action) {
              print('$action selected for index ${widget.index}');
            },
            tapPosition: _tapPosition ?? Offset.zero,
            profileId: widget.profile['name'],
          ),
          onIntroToggle: () => setState(() {introIsExpanded = !introIsExpanded;}),
          onPicsToggle: () => setState(() {picsAreExpanded = !picsAreExpanded;}),  // New: Toggle picsAreExpanded
          onSharePress: () => displayShareDialogue(),
          onSwipePress: () => switchToSipeViewFromProfile(),
          profileSaved: profileSaved, 
          profileLiked: profileLiked,
          profileDisliked: profileDisliked,
          toggleProfile: _toggleProfile, 
        ),
      ),
    );
  }
}

class BannerContent extends StatefulWidget {
  const BannerContent({
    super.key,
    required this.bannerHeight,
    required this.profilePictureHeight,
    required this.expandedPicturesHeight,
    required this.profile,
    //required this.profilePictures,
    required this.picsAreExpanded,
    required this.onProfileTap,
    required this.onIntroToggle,
    required this.introIsExpanded,
    required this.onPicsToggle,  
    required this.onSharePress,
    required this.onSwipePress,
    required this.profileSaved, 
    required this.profileLiked,
    required this.profileDisliked,
    required this.toggleProfile, 
  });

  final double bannerHeight; 
  final double profilePictureHeight;
  final double expandedPicturesHeight;
  final Map<dynamic, dynamic> profile;
  //final Future<List<String?>?> profilePictures;
  final bool picsAreExpanded;
  final bool introIsExpanded;
  final VoidCallback onProfileTap;
  final VoidCallback onIntroToggle;
  final VoidCallback onPicsToggle;  
  final VoidCallback onSharePress;
  final VoidCallback onSwipePress;
  final bool profileSaved; 
  final bool profileLiked;
  final bool profileDisliked;
  final Future<void> Function(String, bool) toggleProfile; 
  
  @override
  _BannerContentState createState() => _BannerContentState();
}

class _BannerContentState extends State<BannerContent> {
  bool droppedDown = false;

  @override
  Widget build(BuildContext context) {
    Future<String?> profilePicture = Future.value(widget.profile['images'][0] as String?);    
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: widget.picsAreExpanded ? widget.bannerHeight + widget.expandedPicturesHeight : widget.bannerHeight,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 151, 160, 210),
          borderRadius: widget.picsAreExpanded
              ? const BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10))
              : const BorderRadius.all(Radius.circular(10)),
          //borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
        ),
        child: Column(children: [
          SizedBox(
            height: widget.profilePictureHeight,
            child: InkWell(
              onTap: widget.onProfileTap,
              borderRadius: BorderRadius.circular(24),
              child: FutureBuilder<String?>(
                // future: _getImagePath(widget.profile['profilePic'], widget.profile['name'], context),
                future: profilePicture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: widget.bannerHeight,
                      height: widget.bannerHeight,
                      decoration: ShapeDecoration(
                        color: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final imagePath = snapshot.data;
                  if (imagePath == null || !File(imagePath).existsSync()) {
                    return Container(
                      width: widget.bannerHeight,
                      height: widget.bannerHeight,
                      decoration: ShapeDecoration(
                        color: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: widget.bannerHeight,
                    height: widget.bannerHeight,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      image: DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          //////////////////////////////////////////////////////////////////////
          ///////////////////////////// Basic Info /////////////////////////////
          //////////////////////////////////////////////////////////////////////
                  
          Row(
            children: [
              Expanded(
                child: Container(
                  margin:  EdgeInsets.only(top: 15, left: 15, right: 15),
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.black),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Color.fromARGB(255, 196, 205, 255),  // 255, 151, 160, 210
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6), // Shadow color with opacity
                        spreadRadius: 1, // How much the shadow spreads
                        blurRadius: 5, // How blurry the shadow is
                        offset: Offset(0, 5), // Shadow position (x, y)
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.profile['name']?.toString() ?? 'Unknown',
                              style: TextStyle(overflow: TextOverflow.ellipsis),
                            ),
                            
                            Column(children: [ 
                              if (widget.profileLiked)  
                              SizedBox(
                                height: 20,
                                child: Row(
                                  children: [
                                    Text('liked', style: TextStyle(fontStyle: FontStyle.italic),),
                                    SizedBox(width: 10),
                                    SizedBox(
                                      width: 20,
                                      child: Image.asset('assets/icons/heart.png')
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.profileDisliked)
                              SizedBox(
                                height: 20,
                                child: Row(
                                  children: [
                                    Text('disliked', style: TextStyle(fontStyle: FontStyle.italic),),
                                    SizedBox(width: 10),
                                    SizedBox(
                                      width: 20,
                                      child: Image.asset('assets/icons/x.png')
                                    ),
                                  ],
                                ),
                              ),
                            
                              // if (!widget.profileLiked && ! widget.profileDisliked)
                              // SizedBox(
                              //   height: 20,
                              // ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'age:  ${widget.profile['age']?.toString() ?? 'N/A'}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 25),
                            Text(
                              'height:  ${widget.profile['height']?.toString() ?? 'N/A'}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 25),
                            Text(
                              'distance:  ${'${widget.profile['distance']?.toString()} mi' ?? 'N/A'}',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        
                        ///////////////////////////////////////////////////////////////////////
                        //////////////////// User's choice of profile info ////////////////////
                        ///////////////////////////////////////////////////////////////////////
                        
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
                
          //////////////////////////////////////////////////////////////////////
          /////////////////////////// Like & Dislike ///////////////////////////
          //////////////////////////////////////////////////////////////////////
          
          Container(
            margin: EdgeInsets.only(bottom: 5, top: 5),
            height: 75,
            decoration: BoxDecoration(
              border: Border(
                //top: BorderSide(width: 2, color: Colors.black),
                //bottom: BorderSide(width: 2, color: Colors.black), 
                // left: BorderSide(width: 2, color: Colors.black), 
                // right: BorderSide(width: 2, color: Colors.black)
              ),
              //borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 90,
                  child: IconButton(
                    onPressed: () async{
                      await widget.toggleProfile('disliked', widget.profileDisliked);
                    },
                    icon: Image.asset('assets/icons/x.png'),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: IconButton(
                    onPressed: () async{
                      await widget.toggleProfile('liked', widget.profileLiked);
                    },
                    icon: Image.asset('assets/icons/heart.png'),
                  ),
                ),
              ],
            ),
          ),
                
          /////////////////////////////////////////////////////////////////////////////
          ////////////////////////////////// Buttons //////////////////////////////////
          /////////////////////////////////////////////////////////////////////////////
          
          Container(
            //margin: EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              //color: Color.fromARGB(154, 152, 169, 56),
              border: Border(
                top: BorderSide(width: 2, color: Colors.black),
                bottom: BorderSide(width: 2, color: Colors.black), 
              //   left: BorderSide(width: 2, color: Colors.black), 
              //   right: BorderSide(width: 2, color: Colors.black)
              ),
              borderRadius: widget.picsAreExpanded
              ? null
              : BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async{
                    widget.onPicsToggle();  // Toggle picsAreExpanded
                    await sqlite.DatabaseHelper.instance.getFireStoragePaths(widget.profile['hashedId']);
                    //_cacheImage();
                  },
                  isSelected: widget.picsAreExpanded,  // Reflect picsAreExpanded state
                  selectedIcon: const Icon(Icons.keyboard_arrow_up, size: 25),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 25),
                ),
                IconButton(
                  onPressed: () {
                    widget.onSharePress();
                  },
                  icon: const Icon(Icons.share, size: 25),
                ),
                IconButton(
                  onPressed: () {
                    widget.onSwipePress();
                  },
                  icon: ImageIcon(AssetImage('assets/icons/stack.png'), size: 25),
                ),
                IconButton(
                  onPressed: () async{ 
                    await widget.toggleProfile('saved', widget.profileSaved); // Toggle saved profile
                  },
                  isSelected: widget.profileSaved,
                  icon: const Icon(Icons.bookmark_border_rounded, size: 25),
                  selectedIcon: const Icon(Icons.bookmark_added_rounded, size: 25),
                ),
              ],
            ),
          ),
                
          //////////////////////////////////////////////////////////////////////////
          /////////////////////////// Pictures drop down ///////////////////////////
          //////////////////////////////////////////////////////////////////////////
              
          if (widget.picsAreExpanded && widget.profile['images'] != null)
          Container(
            //margin: EdgeInsets.only(top: 15, left: 15, right: 15),
            padding: EdgeInsets.all(15),
            width: MediaQuery.of(context).size.width,
            height: widget.expandedPicturesHeight - 15,
            // decoration: BoxDecoration(
            //   color: Color.fromARGB(255, 196, 205, 255),
            //   border: Border.all(width: 2, color: Colors.black),
            //   borderRadius: BorderRadius.all(Radius.circular(10))
            // ),
            child: GridView.builder(
              padding: const EdgeInsets.all(0),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemCount: (widget.profile['images'] as List).length.clamp(0, 6),
              itemBuilder: (context, imageIndex) {
                print('item count: ${(widget.profile['images'] as List).length.clamp(0, 6)}');
                final imagePath = widget.profile['images'][imageIndex];
                Future<String?> futureImage = Future.value(widget.profile['images'][imageIndex] as String?);
                return InkWell(
                  onTap: () => showProfileDialog(
                    context: context,
                    imagePath: imagePath,
                    index: 0,
                    onMenuAction: (action) {
                      print('$action selected for image $imageIndex');
                    },
                    tapPosition: const Offset(0, 0),
                    profileId: widget.profile['name'],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6), // Shadow color with opacity
                        spreadRadius: 1, // How much the shadow spreads
                        blurRadius: 5, // How blurry the shadow is
                        offset: Offset(0, 5), // Shadow position (x, y)
                      ),
                    ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(10),
                      child: FutureBuilder<String?>(
                        //future: _getImagePath(imagePath, widget.profile['name'], context),
                        future: futureImage,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final resolvedPath = snapshot.data;
                          if (resolvedPath == null ||
                              !File(resolvedPath).existsSync()) {
                            return Container(
                              color: Colors.grey,
                            );
                          }
                          return Image.file(
                            File(resolvedPath),
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),

      /////////////////////////////////////////////////////////
      //////////////////// Intro drop down ////////////////////
      /////////////////////////////////////////////////////////

      if (widget.picsAreExpanded)  
      Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 151, 160, 210),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Text('Intro'),
                IconButton(
                  onPressed: widget.onIntroToggle,
                  isSelected: widget.introIsExpanded,
                  selectedIcon: const Icon(Icons.keyboard_arrow_up),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),
          if (widget.introIsExpanded && widget.profile['intro'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 15, right: 15),
            child: Text(
              widget.profile['intro']?.toString() ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ]),
      ),
    ]);
  }

  Future<String> _cacheImage(String storagePath, String hashedId, String docId) async {
    try {
      // Resolve path into URL (emulator or prod)
      final ref = firebase_storage.FirebaseStorage.instance.ref().child(storagePath);
      final url = await ref.getDownloadURL();

      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;

      final docDir = await getApplicationDocumentsDirectory();
      final filePath = '${docDir.path}/profile_images/$hashedId/$fileName';
      final file = File(filePath);

      if (!await file.exists()) { 
        final response = await http.get(uri);  // Download the image
        if (response.statusCode != 200) throw Exception("Failed to download: ${response.statusCode}");
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);  // Write image
      }

      await sqlite.DatabaseHelper.instance.cacheImage(docId, storagePath, filePath);
      return filePath;
    } catch (e) {
      print('Error caching image for $storagePath: $e');
      return '';
    }
  }
}

