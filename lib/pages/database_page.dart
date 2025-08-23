import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/search_bar.dart' as search_bar;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view;
import 'package:integra_date/widgets/database_page_widgets/grid_view.dart' as grid_view;
import 'package:integra_date/widgets/pagination_buttons.dart';

// only for temp buttons
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/databases/get_firestore_profiles.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({
    super.key,
    required this.theme,
    required this.profileData,
    required this.switchPage,
    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,

    required this.addNewFilteredProfiles,  // From navigation_bar.dart. Updates the page with filtered profiles
    required this.startRingAlgo  // From navigation_bar.dart. Updates the page with profiles after the ring algo query completes for the radius set in filters
  });

  final ThemeData theme;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final Function(int, int?) switchPage;
  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  final VoidCallback addNewFilteredProfiles;
  final VoidCallback startRingAlgo;

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

  late double gridItemHeight;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
    isDisposed = true;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !isLoading) {
      // Disable scroll-based loading since we're using pagination buttons
      // _loadMoreEntries();
    }

    if (_scrollController.hasClients) {
      if (isBannerView) {
        firstVisibleIndex = (_scrollController.offset / banner_view.BannerView.bannerHeight).floor();
        listViewOffset = _scrollController.offset;
        gridViewOffset = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
      } else {
        firstVisibleIndex = (_scrollController.offset / gridItemHeight).floor() * 3;
        listViewOffset = firstVisibleIndex * banner_view.BannerView.bannerHeight;
        gridViewOffset = ((firstVisibleIndex / 3) * gridItemHeight).ceil().toDouble();
      }
    }
  }

  void _toggleViewMode() {
    setState(() {
      isBannerView = !isBannerView;
    });
  }

  void calculateGridHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double gridItemWidth = screenWidth / 3;
    gridItemHeight = gridItemWidth;
  }

  Future<void> _loadMoreEntries() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(seconds: 2));

    if (isDisposed) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    calculateGridHeight(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        search_bar.DateSearch(theme: theme, onToggleViewMode: _toggleViewMode, addNewFilteredProfiles: widget.addNewFilteredProfiles),
        
        TextButton(onPressed: () async{
            sqlite.DatabaseHelper.instance.logDatabaseContents();
          }, 
          child: Text('log sqlite data')
        ),

        TextButton(onPressed: () async{
            logFirestoreContents();
          }, 
          child: Text('log firestore data')
        ),

        TextButton(onPressed: () async{
            logDocumentDirectoryContents();
          }, 
          child: Text('log phone doc dir data')
        ),

        Expanded(
          child: isBannerView
              ? banner_view.BannerView(
                  scrollController: _scrollController,
                  profileData: widget.profileData,
                  isLoading: isLoading,
                  initialOffset: listViewOffset,
                  switchPage: widget.switchPage,
                  startRingAlgo: widget.startRingAlgo  //add this to grid and profile page//////////////////////////////////////////////////////////////// 
                )
              : grid_view.BoxView(
                  scrollController: _scrollController,
                  profileData: widget.profileData,
                  isLoading: isLoading,
                  initialOffset: gridViewOffset,
                  switchPage: widget.switchPage,
                ),
        ),
        PaginationButtons(
          currentPage: widget.currentPage,
          hasPreviousPage: widget.hasPreviousPage,
          hasNextPage: widget.hasNextPage,
          onPreviousPage: () {
            widget.onPreviousPage();
            setState(() {
              listViewOffset = 0.0;
              gridViewOffset = 0.0;
              firstVisibleIndex = 0;
            });
          },
          onNextPage: () {
            widget.onNextPage();
            setState(() {
              listViewOffset = 0.0;
              gridViewOffset = 0.0;
              firstVisibleIndex = 0;
            });
          },
        ),
      ],
    );
  }
}

// version 1
/* import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/search_bar.dart' as search_bar; 
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view; 
import 'package:integra_date/widgets/database_page_widgets/grid_view.dart' as grid_view;

class DatabasePage extends StatefulWidget {
  const DatabasePage({
    super.key,
    required this.theme,
    required this.profileData,
    required this.switchPage,
  });

  final ThemeData theme;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final Function(int, int?) switchPage; // Callback to switch pages

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

    if(_scrollController.hasClients) {  // Calculate the offset to pass to the view when toggled
      if (isBannerView) {  // In the banner view claculate the grid offset 
        firstVisibleIndex = (_scrollController.offset / banner_view.BannerView.bannerHeight).floor();
        listViewOffset = _scrollController.offset;
        gridViewOffset = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
      } else {  // In the grid view calculate the banner offset
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        search_bar.DateSearch(theme: theme, onToggleViewMode: _toggleViewMode),  // Build search bar
    
        Expanded(  // Build profile scroller
          child: isBannerView
            ? banner_view.BannerView(
                scrollController: _scrollController, 
                profileData: widget.profileData, 
                isLoading: isLoading, 
                initialOffset: listViewOffset, 
                switchPage: widget.switchPage
              )
    
            : grid_view.BoxView(  
                scrollController: _scrollController, 
                profileData: widget.profileData, 
                isLoading: isLoading, 
                initialOffset: gridViewOffset, 
                switchPage: widget.switchPage,
              ),
        ),
      ],
    );
  }
} */