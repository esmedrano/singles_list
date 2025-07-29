import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart'; // Added: Import BannerContent widget

// Modified: Shows a dialog with a centered focused image and a popup menu directly below it
void showProfileDialog({
  required BuildContext context,
  required String imagePath,
  required int index,
  required Function(String) onMenuAction,
  required Offset tapPosition,
  }) {
  // Added: Key to access the image widget's position
  final imageKey = GlobalKey();
  // Added: Track menu visibility and overlay entry
  bool isMenuVisible = true;
  OverlayEntry? menuOverlay;

  // Modified: Create the dialog with centered image
  showDialog(
    context: context,
    builder: (context) => GestureDetector(
      // Added: Dismiss dialog and menu on tap outside
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
            // Added: GestureDetector to dismiss both menu and dialog when tapping image
            GestureDetector(
              onTap: () {
                if (isMenuVisible) {
                  menuOverlay?.remove();
                  isMenuVisible = false;
                }
                Navigator.of(context).pop();
              },
              child: Align(
                alignment: Alignment(0, -.5),
                child: AspectRatio(
                  aspectRatio: 3/4,
                  child: Container(
                    key: imageKey,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      ),
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
    // Added: Remove menu and reset visibility when dialog is closed
    if (isMenuVisible) {
      menuOverlay?.remove();
      isMenuVisible = false;
    }
  });

  // Modified: Show popup menu directly below the image after layout
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMenuVisible && context.mounted) {
      final RenderBox? imageBox = imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (imageBox != null) {
        final imagePosition = imageBox.localToGlobal(Offset.zero);
        final imageBottomY = imagePosition.dy + imageBox.size.height;
        // Added: Ensure menu is clamped to avoid overflow
        final menuLeft = MediaQuery.sizeOf(context).width / 2 - 125;
        final menuTop = imageBottomY + 10;

        // Added: Create custom menu using OverlayEntry
        menuOverlay = OverlayEntry(
          builder: (context) => Stack(
            children: [
              // Added: Transparent overlay to capture taps outside menu
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
              // Modified: Positioned menu directly below the image
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),

                  child: Container(
                    width: 250,
                    child: Column(
                      //mainAxisSize: MainAxisSize.min,
                      children: [
                        // Added: First menu button
                        ListTile(
                          title: const Text('Action 1'),
                          onTap: () {
                            onMenuAction('action1');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        // Added: Second menu button
                        ListTile(
                          title: const Text('Action 2'),
                          onTap: () {
                            onMenuAction('action2');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        // Added: Third menu button
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

        // Added: Insert the menu overlay
        Overlay.of(context).insert(menuOverlay!);
      }
    }
  });
}

// Modified: Shows a dialog with a centered focused banner container and a popup menu directly below it
void showBannerDialog({
  required BuildContext context,
  required Map<dynamic, dynamic> profile,
  required int index,
  required Function(String) onMenuAction,
  required Offset tapPosition,
  required bool picsAreExpanded,
}) {
  // Added: Key to access the banner widget's position
  final bannerKey = GlobalKey();
  // Added: Track menu visibility and overlay entry
  bool isMenuVisible = true;
  OverlayEntry? menuOverlay;

  // Modified: Show the dialog with the centered banner
  showDialog(
    context: context,
    builder: (context) => GestureDetector(
      // Added: Dismiss dialog and menu on tap outside
      onTap: () {
        if (isMenuVisible) {
          menuOverlay?.remove();
          isMenuVisible = false;
        }
        Navigator.of(context).pop();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          // Added: Center the banner content vertically
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Added: GestureDetector to dismiss both menu and dialog when tapping banner
              GestureDetector(
                onTap: () {
                  if (isMenuVisible) {
                    menuOverlay?.remove();
                    isMenuVisible = false;
                  }
                  Navigator.of(context).pop();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ Container(
                    key: bannerKey,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: BannerContent(
                      profile: profile,
                      picsAreExpanded: picsAreExpanded,
                      // Added: Disable interactive elements in dialog
                      onProfileTap: () {},
                      onIntroToggle: () {},
                    ),
                  ),]
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((_) {
    // Added: Remove menu and reset visibility when dialog is closed
    if (isMenuVisible) {
      menuOverlay?.remove();
      isMenuVisible = false;
    }
  });

  // Modified: Show popup menu directly below the banner after layout
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMenuVisible && context.mounted) {
      final RenderBox? bannerBox = bannerKey.currentContext?.findRenderObject() as RenderBox?;
      if (bannerBox != null) {
        final bannerPosition = bannerBox.localToGlobal(Offset.zero);
        final bannerBottomY = bannerPosition.dy + bannerBox.size.height;  // leave the / 2 idky
        // Added: Ensure menu is clamped to avoid overflow
        final menuLeft = bannerPosition.dx;
        final menuTop = bannerBottomY;

        // Added: Create custom menu using OverlayEntry
        menuOverlay = OverlayEntry(
          builder: (context) => Stack(
            children: [
              // Added: Transparent overlay to capture taps outside menu
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
              // Modified: Positioned menu directly below the banner
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Added: First menu button
                        ListTile(
                          title: const Text('Action 1'),
                          onTap: () {
                            onMenuAction('action1');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        // Added: Second menu button
                        ListTile(
                          title: const Text('Action 2'),
                          onTap: () {
                            onMenuAction('action2');
                            menuOverlay?.remove();
                            isMenuVisible = false;
                            Navigator.of(context).pop();
                          },
                        ),
                        // Added: Third menu button
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

        // Added: Insert the menu overlay
        Overlay.of(context).insert(menuOverlay!);
      }
    }
  });
}