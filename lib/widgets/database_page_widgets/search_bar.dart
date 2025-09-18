import 'package:flutter/material.dart';
import 'dart:io';

import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/scripts/search_bar_query.dart' as search_bar_query;
import 'package:integra_date/widgets/share_popup.dart' as share_popup; 

class DateSearch extends StatefulWidget {
  const DateSearch({
    super.key,
    required this.theme,
    required this.onToggleViewMode,
    required this.addNewFilteredProfiles,
    required this.switchPage
  });

  final ThemeData theme;
  final VoidCallback onToggleViewMode;
  final Function(bool?) addNewFilteredProfiles;
  final Function(int, int?, Map<dynamic, dynamic>?) switchPage;

  @override
  State<DateSearch> createState() => _DateSearchState();
}

class _DateSearchState extends State<DateSearch> {
  final FocusNode _focusNode = FocusNode();
  bool isBannerView = true;  // track the view mode to change the toggle button text when view is toggled 
  String? selectedFilter;
  bool _isFullScreen = false; // State variable to track fullscreen mode
  final SearchController _searchController = SearchController(); // Explicit controller

  List<Map<dynamic, dynamic>>? firebaseProfiles;

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();  // Call this every time dispose() is used bc of framework idiosyncrasies 
  }
  
  String formatPhone(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If fewer than 10 digits, return the original phone number or empty string
    if (digits.length < 10) {
      return '';
    }
    
    // Take the first 10 digits for formatting
    String firstTen = digits.length >= 10 ? digits.substring(0, 10) : digits;
    
    // Format as (000) 000-0000
    String formattedPhone = '(${firstTen.substring(0, 3)}) ${firstTen.substring(3, 6)}-${firstTen.substring(6, 10)}';
    
    // Append remaining digits if any
    if (digits.length > 10) {
      formattedPhone += ' ${digits.substring(10)}';
    }
    
    return formattedPhone;
  }

  @override
  Widget build(BuildContext context) {  
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(top: 30, bottom: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
      
            buildToggleButton(),
      
            buildSearchBar(context),
      
            filters_menu.FiltersMenu(addNewFilteredProfiles: widget.addNewFilteredProfiles),
      
          ],
        ),
      ),
    );
  }

  TextButton buildToggleButton() {  // View toggle button
    return TextButton(  
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
        foregroundColor: WidgetStatePropertyAll(Color(0x90000000)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        // overlayColor: ,
        // padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 0, vertical: 0)),
        fixedSize: WidgetStatePropertyAll(Size(70, 0)),
        // maximumSize: WidgetStatePropertyAll(Size(10, 10)),
      ),
      onPressed: () {
        setState(() {
          isBannerView = !isBannerView;
        });
        widget.onToggleViewMode(); 
      },

      child: Text(isBannerView ? 'Grid' : 'Banner'),  // Update button text on view toggle
    );
  }

  SearchAnchor buildSearchBar(BuildContext context) {  // Search Bar
    return SearchAnchor(  
      searchController: _searchController,
      isFullScreen: _isFullScreen, // Use state variable      
      viewBackgroundColor: Color.fromARGB(255,190,198,233),
      viewElevation: 0,
      viewShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      viewConstraints: BoxConstraints(maxWidth: 250, maxHeight: MediaQuery.of(context).size.height / 4),
      viewLeading: IconButton(
        onPressed: () {
          setState(() {
            _isFullScreen = !_isFullScreen;
          });
          
          // Ensure the suggestions view updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchController.closeView(_searchController.text);
            _searchController.openView();
          });
        }, 
        icon: _isFullScreen ? Icon(Icons.fullscreen_exit_rounded) : Icon(Icons.fullscreen)
      ),
      builder: (BuildContext context, SearchController controller) {

        return SearchBar(
          controller: controller,  // Listner for user interaction
          focusNode: _focusNode,  // Attatch the focus node to the search bar
          constraints: BoxConstraints(maxWidth: 250, minWidth: 250, minHeight: 50, maxHeight: 50),   
          
          backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255,190,198,233)),
          // overlayColor: WidgetStatePropertyAll(Color(0x30303030)),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
        
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
          
          padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0),),  // Pads cursor

          // onTap: () {  // Open suggestions
          //   setState(() {
          //     //_isFullScreen = false;
          //     print(_isFullScreen);
          //   });
          // },
           
          onChanged: (_) {  // Update with keystrokes ?
            controller.openView();
          },
                
          onTapOutside: (_) {  // Close suggestions and remove cursor 
            _focusNode.unfocus();
            firebaseProfiles = null;
            //_isFullScreen = false;
          },
                
          leading: const Icon(Icons.search),  // Search icon
        );
      },
    
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
         List<Map<dynamic, dynamic>>? profiles = await sqlite.DatabaseHelper.instance.searchCache(
          controller.text.isNotEmpty ? controller.text : null,
          controller.text.isNotEmpty ? controller.text : null,
        );

        // After the load more button is pressed and firebase is queried, if profiles are found the suggestions will be rebuilt.
        // When rebuilt the additional profiles are appended here so that they are on the bottom of the list.
        // They will be removed from the firebase list if the controller.text is changed so that they are not displayed as falsae results for a new search bar query
        if (firebaseProfiles != null && firebaseProfiles!.isNotEmpty) {  
          if (profiles != null) {
            profiles.addAll(firebaseProfiles!);
          }
          if (profiles == null) {  // If profiles is null addAll will not work, so set it equal 
            profiles = firebaseProfiles;
          }
        }

        List<Widget> suggestions = [];

        var title = controller.text.isNotEmpty ? Text('no results found') : null;  // Set title to null if there is no text in the search bar

        if (profiles == null || profiles.isEmpty) {
          suggestions.add(
            ListTile(
              title: title,
            ),
          );
        } else {
          suggestions.addAll(
            profiles.map((profile) {
              final name = profile['name']?.toString() ?? 'Unknown';
              final unformattedPhone = profile['profile_data']?['phone']?.toString() ?? '';
              final phone = formatPhone(unformattedPhone);
              return ListTile(
                leading: 
                  InkWell(
                    onTap: () =>
                      share_popup.showProfileDialog(
                        context: context,
                        imagePath: profile['profile_data']['profilePic'],
                        index: 0,
                        onMenuAction: (action) {
                        },
                        tapPosition: const Offset(0, 0),
                        profileId: profile['name'],
                      ),
                    borderRadius: BorderRadius.circular(24),
                    child: FutureBuilder<String?>(
                      future: _getImagePath(
                          profile['profile_data']['profilePic'], profile['name'], profile, context),
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
                                                  print(imagePath);

                          return const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey,
                          );
                        }
                        print(imagePath);
                        return CircleAvatar(
                          radius: 24,
                          backgroundImage: FileImage(File(imagePath)),
                          backgroundColor: Colors.grey,
                        );
                      },
                    ),
                  ),
                title: Text('$name ${profile['profile_data']?['age'] ?? ''}'),
                subtitle: phone.isNotEmpty ? Text(phone) : null,
                onTap: () {
                  setState(() {
                    controller.closeView(name);
                    widget.switchPage(1, null, profile);
                    swipe_page.toggleDisplaySearchFalse(); 
                  });
                },
              );
            }).toList(),
          );
        }

        // Add a recent searched icon to the last batch of queried profiles ? 
        // If so then they would have to be clickable which means either a cache or a new query. 
        // Otherwise just delete recent searches. That should be fine for now.
        // Deleted in onTapOutside()

        // It would be annoying to have to press load more every time tho. 

        // Add a button at the bottom of the suggestions
        if (controller.text.isNotEmpty) {
          suggestions.add(
            TextButton(
              style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF))),
              onPressed: () async{
                print('Load more pressed');
                firebaseProfiles = await search_bar_query.searchBarQuery(controller.text);
                print(firebaseProfiles);
                
                if (firebaseProfiles != null && firebaseProfiles!.isNotEmpty) {  // Don't add them to suggestions here because they will be bellow the load more button
                  firebaseProfiles!.map((profile) {
                    final name = profile['name']?.toString() ?? 'Unknown';
                    final unformattedPhone = profile['profile_data']?['phone']?.toString() ?? '';
                    final phone = formatPhone(unformattedPhone);
                    return ListTile(
                      title: Text('$name ${profile['profile_data']?['age'] ?? ''}'),
                      subtitle: phone.isNotEmpty ? Text(phone) : null,
                      onTap: () {
                        setState(() {
                          controller.closeView(name);
                          widget.switchPage(1, null, profile);
                          swipe_page.toggleDisplaySearchFalse(); 
                        });
                      },
                    );
                  }).toList();

                  setState(() {  // Rebuild the page to append the firebase profiles to suggestions with the if statement at the begining 
                    print('state set');
                  });

                  // Ensure the suggestions view updates
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchController.closeView(_searchController.text);
                    _searchController.openView();
                  });
                }
              },
              child: Text('load more'),
            ),
          );
        }

        return suggestions;
      },
    );
  }
}

Future<String?> _getImagePath(
      String? imagePath, String profileId, profile, BuildContext context) async {
    //print(imagePath);
    if (imagePath == null || !File(imagePath).existsSync()) {
      //print('path is not null or exists: $imagePath');
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, profile['images']?.isNotEmpty == true ? profile['images'][0] : '');
      //print(cachedPath);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        //print('got cached path');
        return cachedPath;
      }
      return null; // Return null instead of asset path
    }
    return imagePath;
  }