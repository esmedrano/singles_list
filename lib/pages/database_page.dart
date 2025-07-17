import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/search_bar.dart' as search_bar; 
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view; 
import 'package:integra_date/widgets/database_page_widgets/grid_view.dart' as grid_view;

class DatabasePage extends StatefulWidget {
  const DatabasePage({
    super.key,
    required this.theme,
    required this.profileData,
    required this.onBannerTap,
    //required this.onDataUpdated,
  });

  final ThemeData theme;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final Function(int, int?) onBannerTap; // Callback to switch pages
  //final void Function(List<Map<dynamic, dynamic>>) onDataUpdated;

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  final ScrollController _scrollController = ScrollController();
  bool isDisposed = false;
  bool isLoading = false;
  bool isBannerView = true;  
  double listViewOffset = 0.0;
  double gridViewOffset = 0.0;
  int firstVisibleIndex = 0;

  late double gridItemHeight;  // 137.14285714285714

  @override
  void initState() {  // This function is called when the page is built for the first time
    super.initState();
    _scrollController.addListener(_onScroll);
    // _fetchInitialEntries();
  }

  @override
  void dispose() {  // Disposes the scrollController instance when no longer needed to save memory   
    _scrollController.dispose();
    super.dispose();
    isDisposed = true;
  }

  void _onScroll() {  // The keyword onScroll is linked to the scrollController method in initState. onScroll is activated by scrolling
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
      _loadMoreEntries();
    }
    
    if(_scrollController.hasClients) {
      if (isBannerView) {
        firstVisibleIndex = (_scrollController.offset / banner_view.BannerView.bannerHeight).floor();
        print('first ${firstVisibleIndex}');
        listViewOffset = _scrollController.offset;
        print(listViewOffset);
        gridViewOffset = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
        print(gridViewOffset);
      } else {
        firstVisibleIndex = (_scrollController.offset / gridItemHeight).floor() * 3;  // This calculates the first item that is fully displayed on the grid view
        listViewOffset = firstVisibleIndex * banner_view.BannerView.bannerHeight;
        gridViewOffset = ((firstVisibleIndex / 3) * gridItemHeight).ceil().toDouble();
      }
    }
  }
  
  void _toggleViewMode () {
    setState(() {
      isBannerView = !isBannerView;
    });
  }

  void calculateGridHeight (BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double gridItemWidth = screenWidth / 3;
    gridItemHeight = gridItemWidth;  // The width and height are equal for square grids
  }

  Future<void> _loadMoreEntries() async {  // Load more entires when the user scrolls to the bottom of the list
    setState(() {
      isLoading = true;
    });

    // Simulate a database call with a delay
    await Future.delayed(Duration(seconds: 2));

    if (isDisposed) return;

    // Add new entries to the list
    setState(() {
      // entries.addAll(['13', '14', '15']); // Replace with actual database call
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    calculateGridHeight(context); 

    return Center(
      child: Column(
        children: [
          search_bar.DateSearch(theme: theme, onToggleViewMode: _toggleViewMode),  // Build search bar
      
          // Text('Date Database'),
          Expanded(  // everything in here takes as much room as it needs to build 
        
            child: isBannerView  // Build profile scroller
              ? banner_view.BannerView(scrollController: _scrollController, profileData: widget.profileData, isLoading: isLoading, initialOffset: listViewOffset, onBannerTap: widget.onBannerTap)
              : grid_view.BoxView(scrollController: _scrollController, profileData: widget.profileData, isLoading: isLoading, initialOffset: gridViewOffset, onBannerTap: widget.onBannerTap),
          ),
        ],
      ),
    );
  }
}