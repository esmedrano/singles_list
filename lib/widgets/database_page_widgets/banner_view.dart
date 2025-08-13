import 'package:flutter/material.dart';
import 'package:integra_date/widgets/share_popup.dart';

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
            imagePath: widget.profile['profilePic'] ?? 'assets/placeholder.jpg',
            index: widget.index,
            onMenuAction: (action) {
              print('$action selected for index ${widget.index}');
            },
            tapPosition: _tapPosition ?? Offset.zero,
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
            color: const Color.fromARGB(255, 151, 160, 210),  // This used to be tranparent 
            borderRadius: picsAreExpanded
                ? BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
                : BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 15),
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(24),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(profile['profilePic'] ?? 'assets/placeholder.jpg'),
                        backgroundColor: Colors.grey,
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
                                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 25),
                                Text(
                                  profile['height']?.toString() ?? 'N/A',
                                  style: const TextStyle(fontStyle: FontStyle.italic, overflow: TextOverflow.ellipsis),
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
                        padding: EdgeInsets.all(0),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemCount: (profile['images'] as List).length.clamp(0, 6),
                        itemBuilder: (context, imageIndex) {
                          return Container(
                            decoration: BoxDecoration(color: Color(0x50FFFFFF)),
                            child: SizedBox(
                              child: InkWell(
                                onTap: () => showProfileDialog(
                                  context: context,
                                  imagePath: profile['images'][imageIndex],
                                  index: 0, // Added: Index not used in this context
                                  onMenuAction: (action) {
                                    print('$action selected for image $imageIndex');
                                  },
                                  tapPosition: Offset.zero, // Added: Fallback tap position
                                ),
                                child: Image.asset(
                                  profile['images'][imageIndex],
                                  fit: BoxFit.cover,
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
            decoration: BoxDecoration(
              color: Color(0x50FFFFFF),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text('Intro'),
                    ),
                    IconButton(
                      onPressed: onIntroToggle,
                      isSelected: introIsExpanded,
                      selectedIcon: Icon(Icons.keyboard_arrow_up),
                      icon: Icon(Icons.keyboard_arrow_down),
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
}