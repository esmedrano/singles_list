import 'package:flutter/material.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'dart:io';
import 'package:integra_date/widgets/share_popup.dart';
import 'package:integra_date/widgets/pagination_buttons.dart' as pagination_buttons;

bool startedRingAlgo = false;
bool paginatingNext = false;
bool paginatingPrevious = false;

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
  });

  final ScrollController scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final double initialOffset;
  final Function(int, int?) switchPage;
  final double bannerH;
  static double bannerHeight = 80;

  final VoidCallback startRingAlgo;

  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final Function([int?]) onPreviousPage;
  final Function([int?]) onNextPage;
  final int pageCount;

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
    required this.profile,
    required this.index,
    required this.switchPage,
    required this.startRingAlgo  // From navigation_bar.dart. Updates the page with profiles after the ring algo query completes for the radius set in filters
  });

  final Map<dynamic, dynamic> profile;
  final int index;
  final Function(int, int?) switchPage;

  final VoidCallback startRingAlgo;

  @override
  _BannerItemState createState() => _BannerItemState();
}

class _BannerItemState extends State<BannerItem> {
  bool picsAreExpanded = false;
  bool introIsExpanded = false;
  Offset? _tapPosition;

  @override
  void initState() {  // This is called every time the page is rebuilt
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {  // After the page is fully built, the ring algo is used to continue getting profiles within the radius until the page is full
      if (!startedRingAlgo) {  // This is starting multiple times bc the page is rebuilding when I scroll so this is a global bool for debugging
        widget.startRingAlgo();  // This only goes once for now
        startedRingAlgo = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
      child: InkWell(
        onTap: () => setState(() => picsAreExpanded = !picsAreExpanded),
        onDoubleTap: () => widget.switchPage(1, widget.index),
        onLongPress: () {
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
            picsAreExpanded: picsAreExpanded,
          );
        },
        onTapDown: (details) {
          setState(() {
            _tapPosition = details.globalPosition;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: BannerContent(
          profile: widget.profile,
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
          onIntroToggle: () => setState(() => introIsExpanded = !introIsExpanded),
        ),
      ),
    );
  }
}

class BannerContent extends StatelessWidget {
  const BannerContent({
    super.key,
    required this.profile,
    required this.picsAreExpanded,
    required this.onProfileTap,
    required this.onIntroToggle,
    this.introIsExpanded = false,
  });

  final Map<dynamic, dynamic> profile;
  final bool picsAreExpanded;
  final bool introIsExpanded;
  final VoidCallback onProfileTap;
  final VoidCallback onIntroToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: picsAreExpanded ? 80 + 266 : 80,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 151, 160, 210),
            borderRadius: picsAreExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(10), topRight: Radius.circular(10))
                : const BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, right: 15.0, top: 15, bottom: 15),
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(24),
                      child: FutureBuilder<String?>(
                        future: _getImagePath(
                            profile['profilePic'], profile['name'], context),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: CircularProgressIndicator(),
                            );
                          }
                          final imagePath = snapshot.data;
                          if (imagePath == null || !File(imagePath).existsSync()) {
                            return const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                            );
                          }
                          return CircleAvatar(
                            radius: 24,
                            backgroundImage: FileImage(File(imagePath)),
                            backgroundColor: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  profile['age']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 25),
                                Text(
                                  profile['height']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${profile['distance']?.toString()} mi' ?? 'N/A',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('save'),
                    ),
                  ),
                ],
              ),
              if (picsAreExpanded && profile['images'] != null)
                Column(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 266,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemCount: (profile['images'] as List).length.clamp(0, 6),
                        itemBuilder: (context, imageIndex) {
                          final imagePath = profile['images'][imageIndex];
                          return Container(
                            decoration: const BoxDecoration(color: Color(0x50FFFFFF)),
                            child: SizedBox(
                              child: InkWell(
                                onTap: () => showProfileDialog(
                                  context: context,
                                  imagePath: imagePath,
                                  index: 0,
                                  onMenuAction: (action) {
                                    print('$action selected for image $imageIndex');
                                  },
                                  tapPosition: const Offset(0, 0),
                                  profileId: profile['name'],
                                ),
                                child: FutureBuilder<String?>(
                                  future: _getImagePath(
                                      imagePath, profile['name'], context),
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
                  ],
                ),
            ],
          ),
        ),
        if (picsAreExpanded)
          Container(
            decoration: const BoxDecoration(
              color: Color(0x50FFFFFF),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text('Intro'),
                    ),
                    IconButton(
                      onPressed: onIntroToggle,
                      isSelected: introIsExpanded,
                      selectedIcon: const Icon(Icons.keyboard_arrow_up),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
                if (introIsExpanded && profile['intro'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      profile['intro']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<String?> _getImagePath(
      String? imagePath, String profileId, BuildContext context) async {
    if (imagePath == null || !File(imagePath).existsSync()) {
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, profile['images']?.isNotEmpty == true ? profile['images'][0] : '');
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return cachedPath;
      }
      return null; // Return null instead of asset path
    }
    return imagePath;
  }
}

/* import 'package:flutter/material.dart';
import 'package:integra_date/widgets/share_popup.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'dart:io';

class BannerView extends StatelessWidget {
  const BannerView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.switchPage,
    this.bannerH = 80,
  });

  final ScrollController scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final double initialOffset;
  final Function(int, int?) switchPage;
  final double bannerH;
  static double bannerHeight = 80;

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients && scrollController.offset != initialOffset) {
            scrollController.jumpTo(initialOffset.clamp(0.0, scrollController.position.maxScrollExtent));
          }
        });

        return ListView.builder(
          padding: EdgeInsets.only(top: 30),
          controller: scrollController,
          itemCount: profiles.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == profiles.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return BannerItem(
              profile: profiles[index],
              index: index,
              onBannerTap: switchPage,
            );
          },
        );
      },
    );
  }
}

class BannerItem extends StatefulWidget {
  const BannerItem({
    super.key,
    required this.profile,
    required this.index,
    required this.onBannerTap,
  });

  final Map<dynamic, dynamic> profile;
  final int index;
  final Function(int, int?) onBannerTap;

  @override
  _BannerItemState createState() => _BannerItemState();
}

class _BannerItemState extends State<BannerItem> {
  bool picsAreExpanded = false;
  bool introIsExpanded = false;
  // Added: Stores the position for the popup menu
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
      child: InkWell(
        onTap: () => setState(() => picsAreExpanded = !picsAreExpanded),
        onDoubleTap: () => widget.onBannerTap(1, widget.index),
        // Added: Handle long press on entire banner to open it and show focused banner with menu
        onLongPress: () {
          setState(() {
            picsAreExpanded = true; // Open the banner
          });
          showBannerDialog(
            context: context,
            profile: widget.profile,
            index: widget.index,
            // Added: Handle menu actions
            onMenuAction: (action) {
              print('$action selected for index ${widget.index}');
            },
            tapPosition: _tapPosition ?? Offset.zero,
            picsAreExpanded: picsAreExpanded,
          );
        },
        // Added: Store tap position for long press
        onTapDown: (details) {
          setState(() {
            _tapPosition = details.globalPosition;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: BannerContent(
          profile: widget.profile,
          picsAreExpanded: picsAreExpanded,
          introIsExpanded: introIsExpanded,
          // Added: Handle profile picture tap
          onProfileTap: () => showProfileDialog(
            context: context,
            imagePath: widget.profile['profilePic'] ?? 'assets/profile_image.jpg',
            index: widget.index,
            onMenuAction: (action) {
              print('$action selected for index ${widget.index}');
            },
            tapPosition: _tapPosition ?? Offset.zero,
            profileId: widget.profile['name']
          ),
          // Added: Handle intro toggle
          onIntroToggle: () => setState(() => introIsExpanded = !introIsExpanded),
        ),
      ),
    );
  }
}

// Added: Widget to encapsulate banner content for reuse in BannerItem and dialog
class BannerContent extends StatelessWidget {
  const BannerContent({
    super.key,
    required this.profile,
    required this.picsAreExpanded,
    required this.onProfileTap,
    required this.onIntroToggle,
    this.introIsExpanded = false,
  });

  final Map<dynamic, dynamic> profile;
  final bool picsAreExpanded;
  final bool introIsExpanded;
  final VoidCallback onProfileTap;
  final VoidCallback onIntroToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: picsAreExpanded ? 80 + 266 : 80,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 151, 160, 210),
            borderRadius: picsAreExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(10), topRight: Radius.circular(10))
                : const BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15.0, right: 15.0, top: 15, bottom: 15),
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(24),
                      child: FutureBuilder<String?>(
                        future: _getImagePath(
                            profile['profilePic'], profile['name'], context),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: CircularProgressIndicator(),
                            );
                          }
                          final imagePath = snapshot.data ?? 'assets/profile_image.jpg';
                          return CircleAvatar(
                            radius: 24,
                            backgroundImage: imagePath != 'assets/profile_image.jpg' &&
                                    File(imagePath).existsSync()
                                ? FileImage(File(imagePath))
                                : const AssetImage('assets/profile_image.jpg'),
                            backgroundColor: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  profile['age']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 25),
                                Text(
                                  profile['height']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          profile['distance']?.toString() ?? 'N/A',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('save'),
                    ),
                  ),
                ],
              ),
              if (picsAreExpanded && profile['images'] != null)
                Column(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 266,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemCount: (profile['images'] as List).length.clamp(0, 6),
                        itemBuilder: (context, imageIndex) {
                          final imagePath = profile['images'][imageIndex];
                          return Container(
                            decoration: const BoxDecoration(color: Color(0x50FFFFFF)),
                            child: SizedBox(
                              child: InkWell(
                                onTap: () => showProfileDialog(
                                  context: context,
                                  imagePath: imagePath,
                                  index: 0,
                                  onMenuAction: (action) {
                                    print('$action selected for image $imageIndex');
                                  },
                                  tapPosition: const Offset(0, 0),
                                  profileId: profile['name'],
                                ),
                                child: FutureBuilder<String?>(
                                  future: _getImagePath(
                                      imagePath, profile['name'], context),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    final resolvedPath =
                                        snapshot.data ?? 'assets/profile_image.jpg';
                                    return resolvedPath !=
                                                'assets/profile_image.jpg' &&
                                            File(resolvedPath).existsSync()
                                        ? Image.file(
                                            File(resolvedPath),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              'assets/profile_image.jpg',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/profile_image.jpg',
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
                  ],
                ),
            ],
          ),
        ),
        if (picsAreExpanded)
          Container(
            decoration: const BoxDecoration(
              color: Color(0x50FFFFFF),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text('Intro'),
                    ),
                    IconButton(
                      onPressed: onIntroToggle,
                      isSelected: introIsExpanded,
                      selectedIcon: const Icon(Icons.keyboard_arrow_up),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
                if (introIsExpanded && profile['intro'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      profile['intro']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<String?> _getImagePath(
      String imagePath, String profileId, BuildContext context) async {
    if (imagePath == 'assets/profile_image.jpg' || !File(imagePath).existsSync()) {
      // Try to retrieve from SQLite
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, profile['images']?.isNotEmpty == true ? profile['images'][0] : '');
      return cachedPath ?? 'assets/profile_image.jpg';
    }
    return imagePath;
  }
} */