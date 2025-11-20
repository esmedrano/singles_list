import 'package:flutter/material.dart';
import 'package:integra_date/widgets/database_page_widgets/search_bar.dart' as search_bar;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view;
import 'package:integra_date/widgets/database_page_widgets/grid_view.dart' as grid_view;

// only for temp buttons
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/databases/get_firestore_profiles.dart';
import 'package:cloud_functions/cloud_functions.dart' as fire_functions;
import 'package:firebase_auth/firebase_auth.dart';

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
    required this.pageCount,
    required this.filteredPageCount,

    required this.addNewFilteredProfiles,  // From navigation_bar.dart. Updates the page with filtered profiles
    required this.startRingAlgo  // From navigation_bar.dart. Updates the page with profiles after the ring algo query completes for the radius set in filters
  });

  final ThemeData theme;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final Function(int, int?, Map<dynamic, dynamic>?) switchPage;
  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final Function([int?]) onPreviousPage;
  final Function([int?]) onNextPage;
  final int pageCount;
  final int filteredPageCount;

  final Function(bool?) addNewFilteredProfiles;
  final VoidCallback startRingAlgo;

  @override
  State<DatabasePage> createState() => DatabasePageState();
}

class DatabasePageState extends State<DatabasePage> {
  final ScrollController _scrollController = ScrollController();
  //final ScrollController _barController = ScrollController();
  bool isDisposed = false;
  bool isLoading = false;
  bool isBannerView = true;

  // These are passed to the child widget, so when they update, the child widget auto rebuilds
  double listViewOffset = 0.0;  
  double gridViewOffset = 0.0;  

  // These are used for storing the calculation of the offsets (based on the height of the page's profiles). 
  // It should not be used to update the offsets passed to the child pages until either the page switch or
  // max scroll buttons are pressed.
  double listOffsetCalc = 0.0;  
  double gridOffsetCalc = 0.0;
  int firstVisibleIndex = 0;

  late double gridItemHeight;

  bool maxScrollButtonState = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(DatabasePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileData != oldWidget.profileData) {
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
    isDisposed = true;
  }

  void calculateGridHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double gridItemWidth = screenWidth / 3;
    gridItemHeight = gridItemWidth;
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (isBannerView) {
        firstVisibleIndex = (_scrollController.offset / banner_view.BannerView.onlyBannerHeight).floor();
        listOffsetCalc = _scrollController.offset;
        gridOffsetCalc = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
      } else {
        firstVisibleIndex = (_scrollController.offset / gridItemHeight).floor() * 3;
        listOffsetCalc = firstVisibleIndex * banner_view.BannerView.onlyBannerHeight;
        gridOffsetCalc = ((firstVisibleIndex / 3) * gridItemHeight).ceil().toDouble();
      }
    }
  }

  void _toggleViewMode() {
    setState(() {
      isBannerView = !isBannerView;
      listViewOffset = listOffsetCalc;
      gridViewOffset = gridOffsetCalc;    
    });
  }

  // New callback for scroll toggle
  void onScrollToggle(bool scrollToBottom) {
    if (_scrollController.hasClients) {
      final targetOffset = scrollToBottom
          ? _scrollController.position.maxScrollExtent
          : _scrollController.position.minScrollExtent;
      _scrollController.jumpTo(targetOffset); // Instant scroll
      // Alternative: Smooth scroll
      // _scrollController.animateTo(
      //   targetOffset,
      //   duration: const Duration(milliseconds: 500),
      //   curve: Curves.easeInOut,
      // );
    } else {
      // Fallback: Queue scroll for next frame if controller isn't ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final targetOffset = scrollToBottom
              ? _scrollController.position.maxScrollExtent
              : _scrollController.position.minScrollExtent;
          _scrollController.jumpTo(targetOffset);
        }
      });
    }
  }

  Future<int> getRadiusFilterSetting() async {
    int radius = await sqlite.DatabaseHelper.instance.getFilterValue('radius') as int;
    return radius;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    calculateGridHeight(context);

    if (banner_view.BannerView.profilePictureHeight == 0.0) {
      banner_view.BannerView.profilePictureHeight = MediaQuery.of(context).size.width - 10;
      //print('Set bannerHeight to: ${banner_view.BannerView.bannerHeight}'); // Debug
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        search_bar.DateSearch(
          theme: theme, 
          onToggleViewMode: _toggleViewMode, 
          addNewFilteredProfiles: widget.addNewFilteredProfiles,
          switchPage: widget.switchPage,
          onScrollToggle: onScrollToggle 
        ),
        
        ///////////////////// DONT DELETE !!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
    
        // TextButton(onPressed: () async{
        //     sqlite.DatabaseHelper.instance.logDatabaseContents();
        //   }, 
        //   child: Text('log sqlite data')
        // ),
    
        // TextButton(onPressed: () async{
        //     logFirestoreContents();
        //   }, 
        //   child: Text('log firestore data')
        // ),
    
        // TextButton(onPressed: () async{
        //     logDocumentDirectoryContents();
        //   }, 
        //   child: Text('log phone doc dir data')
        // ),

        TextButton(onPressed: () async{
          try {
            print('Logged in as ${FirebaseAuth.instance.currentUser!.uid}');
            final callable = fire_functions.FirebaseFunctions.instance.httpsCallable('likeUser');

            // ← CORRECT: wrap the data in a Map called "data"
            await callable({
              'receiverId': 'CqN9BUUjYFA',      // or your own doc ID for testing
            });
          } catch (e) {
            print('Functions error: $e');
          }
            }, 
          child: Text('send test notification')
        ),
        
        Expanded(
          child: isBannerView
          ? banner_view.BannerView(
              scrollController: _scrollController,
              profileData: widget.profileData,
              isLoading: isLoading,
              initialOffset: listViewOffset,
              switchPage: widget.switchPage,
              startRingAlgo: widget.startRingAlgo,  //add this to grid and profile page//////////////////////////////////////////////////////////////// 
            
              currentPage: widget.currentPage,
              hasPreviousPage: widget.hasPreviousPage,
              hasNextPage: widget.hasNextPage,
              onPreviousPage: widget.onPreviousPage,
              onNextPage: widget.onNextPage,
              pageCount: widget.pageCount,
              filteredPageCount: widget.filteredPageCount,
            )
          : grid_view.BoxView(
              scrollController: _scrollController,
              profileData: widget.profileData,
              isLoading: isLoading,
              initialOffset: gridViewOffset,
              switchPage: widget.switchPage,
            
              currentPage: widget.currentPage,
              hasPreviousPage: widget.hasPreviousPage,
              hasNextPage: widget.hasNextPage,
              onPreviousPage: widget.onPreviousPage,
              onNextPage: widget.onNextPage,
              pageCount: widget.pageCount,
              filteredPageCount: widget.filteredPageCount,
            ),
        ),
        // Pagination buttons used to be here DON'T ADD BACK. Figure out a way to drop below on maxScrollExtent
      ],
    );
  }
}