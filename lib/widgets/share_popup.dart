import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart'; // Added: Import BannerContent widget

import 'dart:io';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/scripts/create_profile_url.dart' as create_profile_url;

void showProfileDialog({
  required BuildContext context,
  required Future<String?>? imagePath, // Updated: Allow null imagePath
  required int index,
  required Function(String) onMenuAction,
  required Offset tapPosition,
  required String profileId,
}) {
  final imageKey = GlobalKey();
  bool isMenuVisible = true;
  OverlayEntry? menuOverlay;

  final deepLinkHandler = create_profile_url.DeepLinkHandler();

  showDialog(
    context: context,
    builder: (context) => GestureDetector(
      onTap: () {
        if (isMenuVisible) {
          menuOverlay?.remove();
          isMenuVisible = false;
        }
        Navigator.of(context).pop();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (isMenuVisible) {
                  menuOverlay?.remove();
                  isMenuVisible = false;
                }
                Navigator.of(context).pop();
              },
              child: Align(
                alignment: const Alignment(0, -0.5),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    key: imageKey,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    child: FutureBuilder<String?>(
                      future: imagePath,
                      builder: (context, snapshot) {
                        print('showProfileDialog: Loading image for profile $profileId, imagePath=$imagePath, connectionState=${snapshot.connectionState}');
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final resolvedPath = snapshot.data;
                        if (resolvedPath == null || !File(resolvedPath).existsSync()) {
                          print('showProfileDialog: No valid image for profile $profileId');
                          return Container(
                            color: Colors.grey,
                            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 48)),
                          );
                        }
                        print('showProfileDialog: Displaying image $resolvedPath');
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
          ],
        ),
      ),
    ),
  ).then((_) {
    if (isMenuVisible) {
      menuOverlay?.remove();
      isMenuVisible = false;
    }
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMenuVisible && context.mounted) {
      final RenderBox? imageBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (imageBox != null) {
        final imagePosition = imageBox.localToGlobal(Offset.zero);
        final imageBottomY = imagePosition.dy + imageBox.size.height;
        final menuLeft = MediaQuery.sizeOf(context).width / 2 - 125;
        final menuTop = imageBottomY + 10;

        menuOverlay = OverlayEntry(
          builder: (context) => Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (isMenuVisible) {
                    menuOverlay?.remove();
                    isMenuVisible = false;
                    Navigator.of(context).pop();
                  }
                },
                child: Container(color: Colors.transparent),
              ),
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 250,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('copy link to profile'),
                          onTap: () {
                            onMenuAction('copy link to profile');
                            deepLinkHandler.shareProfileLink(profileId);
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: const Text('save'),
                          onTap: () {
                            onMenuAction('action2');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: const Text('Action 3'),
                          onTap: () {
                            onMenuAction('action3');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        Overlay.of(context).insert(menuOverlay!);
      }
    }
  });
}

// Future<String?> _getImagePath(String? imagePath, String profileId) async {
//   if (imagePath == null || !File(imagePath).existsSync()) {
//     final cachedPath =
//         await sqlite.DatabaseHelper.instance.getCachedImage(profileId, imagePath ?? '');
//     if (cachedPath != null && File(cachedPath).existsSync()) {
//       print('showProfileDialog: Retrieved cached image $cachedPath for profile $profileId');
//       return cachedPath;
//     }
//     print('showProfileDialog: No valid image path for profile $profileId');
//     return null;
//   }
//   print('showProfileDialog: Using provided image path $imagePath for profile $profileId');
//   return imagePath;
// }

// Future<List<String?>?> _getImagePath(
//       String? imagePath, String profileId) async {
//     if (imagePath == null || !File(imagePath).existsSync()) {
//       final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
//           profileId, imagePath ?? '');
//       if (cachedPath != null && File(cachedPath).existsSync()) {
//         return cachedPath;
//       }
//       return null;
//     }
//     return imagePath;
//   }

void showBannerDialog({
  required BuildContext context,
  required Map<dynamic, dynamic> profile,
  required int index,
  required Function(String) onMenuAction,
  required Offset tapPosition,
  required bool picsAreExpanded,
}) {
  final bannerKey = GlobalKey();
  bool isMenuVisible = true;
  OverlayEntry? menuOverlay;

  final deepLinkHandler = create_profile_url.DeepLinkHandler();
  final profilePictureHeight  = (MediaQuery.of(context).size.width - 10); 
  final double bannerHeight = 223;
  final double expandedPicturesHeight = 407;

  //final profilePictures = _getImagePath(profile['images'], profile['name']);

  showDialog(
    context: context,
    builder: (context) => GestureDetector(
      onTap: () {
        if (isMenuVisible) {
          menuOverlay?.remove();
          isMenuVisible = false;
        }
        Navigator.of(context).pop();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (isMenuVisible) {
                  menuOverlay?.remove();
                  isMenuVisible = false;
                }
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    key: bannerKey,
                    width: MediaQuery.of(context).size.width,
                    child: BannerContent(
                      bannerHeight: bannerHeight,
                      profilePictureHeight: profilePictureHeight,
                      expandedPicturesHeight: expandedPicturesHeight,
                      profile: profile,
                      //profilePictures: profilePictures,
                      //picsAreExpanded: picsAreExpanded,
                      introIsExpanded: false,
                      onProfileTap: () {},  // These don't need to do anything because this is basically just a picture of the profile 
                      onIntroToggle: () {},  // These don't need to do anything because this is basically just a picture of the profile
                      //onPicsToggle: () {},  // These don't need to do anything because this is basically just a picture of the profile
                      onSharePress: () {},  // These don't need to do anything because this is basically just a picture of the profile
                      onSwipePress: () {},  // These don't need to do anything because this is basically just a picture of the profile
                      profileSaved: false,
                      profileLiked: false,
                      profileDisliked: false,
                      //toggleProfile: (String, bool) {return Future(() {});}, 
                      switchPage: (int, int2, int3) {},
                    ),
                  ),
                  //SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).then((_) {
    if (isMenuVisible) {
      menuOverlay?.remove();
      isMenuVisible = false;
    }
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMenuVisible && context.mounted) {
      final RenderBox? bannerBox = bannerKey.currentContext?.findRenderObject() as RenderBox?;
      if (bannerBox != null) {
        final bannerPosition = bannerBox.localToGlobal(Offset.zero);
        final bannerBottomY = bannerPosition.dy + bannerBox.size.height;
        final menuLeft = MediaQuery.sizeOf(context).width / 2 - 125;
        final menuTop = bannerBottomY + 10;

        menuOverlay = OverlayEntry(
          builder: (context) => Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (isMenuVisible) {
                    menuOverlay?.remove();
                    isMenuVisible = false;
                    Navigator.of(context).pop();
                  }
                },
                child: Container(color: Colors.transparent),
              ),
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 250,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('copy link to profile'),
                          onTap: () {
                            onMenuAction('copy link to profile');
                            deepLinkHandler.shareProfileLink(profile['hashedId']);
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: const Text('save'),
                          onTap: () {
                            onMenuAction('action2');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          title: const Text('Action 3'),
                          onTap: () {
                            onMenuAction('action3');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        Overlay.of(context).insert(menuOverlay!);
      }
    }
  });
}

