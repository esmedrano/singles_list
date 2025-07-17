import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:integra_date/widgets/database_page_widgets/search_bar.dart' as search_bar;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view;
import 'package:integra_date/widgets/database_page_widgets/grid_view.dart' as grid_view;

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key, required this.theme});
  final ThemeData theme;

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
  List<Map<String, dynamic>> profiles = []; // Store profiles as a list of dictionaries

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchInitialProfiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
    isDisposed = true;
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
      _loadMoreProfiles();
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
    setState(() => isBannerView = !isBannerView);
  }

  void calculateGridHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double gridItemWidth = screenWidth / 3;
    gridItemHeight = gridItemWidth;
  }

  Future<void> _fetchInitialProfiles() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseDatabase.instance.ref('profiles').limitToFirst(3).once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
        setState(() {
          profiles = data.entries.map((e) => {
            'name': e.value['name'] ?? 'Unknown',
            'imageUrl': e.value['imageUrl'] ?? 'https://fallback.com/image.jpg',
            'coords': e.value['coords'] ?? 'N/A',
            'distance': e.value['distance'] ?? 'N/A',
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching initial profiles: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreProfiles() async {
    setState(() => isLoading = true);
    try {
      final lastKey = profiles.isNotEmpty ? profiles.last.keys.first : null;
      final query = FirebaseDatabase.instance.ref('profiles').orderByKey().startAfter(lastKey).limitToFirst(3);
      final snapshot = await query.once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
        setState(() {
          profiles.addAll(data.entries.map((e) => {
            'name': e.value['name'] ?? 'Unknown',
            'imageUrl': e.value['imageUrl'] ?? 'https://fallback.com/image.jpg',
            'coords': e.value['coords'] ?? 'N/A',
            'distance': e.value['distance'] ?? 'N/A',
          }));
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more profiles: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    calculateGridHeight(context);
    return Center(
      child: Container(
        decoration: const BoxDecoration(border: Border.all()),
        child: Column(
          children: [
            search_bar.DateSearch(theme: widget.theme, onToggleViewMode: _toggleViewMode),
            Expanded(
              child: isBannerView
                  ? banner_view.BannerView(
                      scrollController: _scrollController,
                      profiles: profiles, // Pass profiles instead of entries
                      isLoading: isLoading,
                      initialOffset: listViewOffset,
                    )
                  : grid_view.BoxView(
                      scrollController: _scrollController,
                      profiles: profiles, // Pass profiles
                      isLoading: isLoading,
                      initialOffset: gridViewOffset,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}