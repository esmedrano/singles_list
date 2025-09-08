import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;

class DateSearch extends StatefulWidget {
  const DateSearch({
    super.key,
    required this.theme,
    required this.onToggleViewMode,
    required this.addNewFilteredProfiles
  });

  final ThemeData theme;
  final VoidCallback onToggleViewMode;
  final Function(bool?) addNewFilteredProfiles;

  @override
  State<DateSearch> createState() => _DateSearchState();
}

class _DateSearchState extends State<DateSearch> {
  final FocusNode _focusNode = FocusNode();
  bool isBannerView = true;  // track the view mode to change the toggle button text when view is toggled 
  String? selectedFilter;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();  // Call this every time dispose() is used bc of framework idiosyncrasies 
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
      isFullScreen: false,
      viewBackgroundColor: Color(0x90FFFFFF),
      viewElevation: 0,
      viewShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      viewConstraints: BoxConstraints(maxWidth: 250, maxHeight: MediaQuery.of(context).size.height / 4),  // This took me an hour 
      builder: (BuildContext context, SearchController controller) {

        return SearchBar(
          controller: controller,  // Listner for user interaction
          focusNode: _focusNode,  // Attatch the focus node to the search bar
          constraints: BoxConstraints(maxWidth: 250, minWidth: 250, minHeight: 50, maxHeight: 50),   
        
          backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
          // overlayColor: WidgetStatePropertyAll(Color(0x30303030)),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
        
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
          
          padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 16.0),),  // Pads cursor
                
          onTap: () {  // Open suggestions
            controller.openView();
          },
                
          onChanged: (_) {  // Update with keystrokes ?
            controller.openView();
          },
                
          onTapOutside: (_) {  // Close suggestions and remove cursor 
            _focusNode.unfocus();
          },
                
          leading: const Icon(Icons.search),  // Search icon
        );
      },
    
      suggestionsBuilder: (BuildContext context, SearchController controller) {
      
        return List<ListTile>.generate(5, (int index) {
          final String item = 'item $index';
          return ListTile(
            title: Text(item),
            onTap: () {
              setState(() {
                controller.closeView(item);
              });
            },
          );
        });
      },
    );
  }
}