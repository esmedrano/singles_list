import 'package:flutter/material.dart';
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;

class BannerView extends StatelessWidget {
  BannerView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.onBannerTap,
  }); 
  
  final scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final initialOffset;
  final Function(int, int?) onBannerTap;  // Callback to switch pages when the banner is clicked

  static const double bannerHeight = 80;

  void _showLargeProfilePicture(BuildContext context, String imagePath) {  // Display profile picture over screen
    showDialog(
      context: context,
      barrierDismissible: true,  // Dismiss when tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: CircleBorder(),
          clipBehavior: Clip.hardEdge,
          backgroundColor: Colors.transparent,

          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, 
              height: MediaQuery.of(context).size.height * 0.6, 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.contain,  // Preserve aspect ratio
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && scrollController.offset != initialOffset) {
        scrollController.jumpTo(initialOffset.clamp(
          0.0, scrollController.position.maxScrollExtent
        ));
      }
    });

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

        // The profiles list starts out as a Future<List<Map<dynamic, dynamic>>>> type so it can be called from the database, 
        // and is used as a List<Map<dynamic, dynamic>> type, so the Future builder is required to wait on the async database call.
        // Then it can be used as a List<Map<dynamic, dynamic>> type. If this is still necessary later, I can place it in a widget 
        // to avoid the rewrites found in other files. 

        final profiles = snapshot.data!;  

        return ListView.builder(
          controller: scrollController,
          itemCount: profiles.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == profiles.length) {
              return Center(child: CircularProgressIndicator());
            }
            return Padding(  // build a banner at the next index
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),

              child: InkWell(  // Animated, clickable container
                onTap: () {  // Change to the profile page with the clicked profile
                  onBannerTap(1, index);
                },
                
                onLongPress: null,  // I could do something cool here
                
                borderRadius: BorderRadius.circular(10), // Match ink's borderRadius to avoid draing outside of border
              
                child: Ink(  // each banner is an ink container
                  height: bannerHeight,
                  decoration: BoxDecoration(
                    color: Color(0x50FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                          
                  child: Row(children: [
                    Padding(  // Circular profile picture
                        padding: const EdgeInsets.only(left: 15.0, right: 15.0),

                        child: InkWell(  // Clickable profile picture
                          onTap: () {
                            _showLargeProfilePicture(context, profiles[index]['profilePic']);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(profiles[index]['profilePic']),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ),

                      Expanded(  // Stacked text
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Row(  // all text
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(  // name, age, and height
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profiles[index]['name'], // Title (e.g., Entry name)
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Ensure visibility on background
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 5),

                                  Row(  // age and height
                                    spacing: 25,
                                    children: [
                                      Text(
                                        profiles[index]['age'], // Example subtitle
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                            
                                      Text(
                                        profiles[index]['height'], // Example subtitle
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                                            
                              Text(  // distance
                                profiles[index]['distance'],
                                style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),  
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(  // save profile button
                        padding: const EdgeInsets.only(right: 8.0),
                        child: TextButton(
                          onPressed: () {
                            
                          },
                          child: const Text(
                            'save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],)
                ),
              ),
            );
          },
        );
      }
    );
  }
}