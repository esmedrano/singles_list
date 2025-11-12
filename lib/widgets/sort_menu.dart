import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/pages/swipe_page.dart' as swipe_page;
import 'package:integra_date/widgets/database_page_widgets/banner_view.dart' as banner_view;

bool runningRings = false;
void toggleRings(bool running) {
  runningRings = running;
}

class SortersMenu extends StatefulWidget {
  const SortersMenu({
    super.key,
    required this.addNewFilteredProfiles  
  });

  final Function(bool?) addNewFilteredProfiles;

  @override
  SortersMenuState createState() => SortersMenuState();
}

class SortersMenuState extends State<SortersMenu> {
  List<String> _distanceSort = [];
  List<String> _ageSort = [];
  List<String> _heightSort = [];

  final List<String> _sortOptions = ['increasing', 'decreasing'];

  List<String> sortCategories = ['distance_increasing']; // Track order of selected sort categories

  bool incDecSelected = false; // Tracks if one of the first three is selected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSortValues();
    });
  }

  void refresh() {
    loadSortValues();
  }

  Future<void> loadSortValues() async {
    try {
      final db = sqlite.DatabaseHelper.instance;
      await db.setFilterValue('distanceSort', jsonEncode(['increasing']));
      List<String> distanceSort = (jsonDecode(await db.getFilterValue('distanceSort') ?? '[]') as List<dynamic>).cast<String>();
      
      await db.setFilterValue('ageSort', jsonEncode([]));
      await db.setFilterValue('heightSort', jsonEncode([]));
      List<String> ageSort = (jsonDecode(await db.getFilterValue('ageSort') ?? '[]') as List<dynamic>).cast<String>();
      List<String> heightSort = (jsonDecode(await db.getFilterValue('heightSort') ?? '[]') as List<dynamic>).cast<String>();
      
      if (mounted) {
        setState(() {
          _distanceSort = distanceSort;
          _ageSort = ageSort;
          _heightSort = heightSort;

          incDecSelected = _distanceSort.isNotEmpty || _ageSort.isNotEmpty || _heightSort.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error loading sort values: $e');
      if (mounted) {
        setState(() {
          _distanceSort = [];
          _ageSort = [];
          _heightSort = [];
          
          incDecSelected = false;
        });
      }
    }
  }

  Future<void> saveAndApplySortArgs() async {
    try {
      final db = sqlite.DatabaseHelper.instance;
      await db.setFilterValue('distanceSort', jsonEncode(_distanceSort));
      await db.setFilterValue('ageSort', jsonEncode(_ageSort));
      await db.setFilterValue('heightSort', jsonEncode(_heightSort));
      
      print('sort_menu.dart: sort values saved to sqlite');
    } catch (e) {
      print('Error saving sort values: $e');
    }

    print('sort_menu.dart: sort categories passed to the nav bar: $sortCategories');
    widget.addNewFilteredProfiles(null);  //////////////////////////////////////////////// pass the sort order here and then to the sqlite filter funnction, then use that to modify the sorter logic
  }

  void displaySorters() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                void updateParentState(void Function() callback, [bool? isSelected]) {
                  callback();
                  setState(() {}); // Trigger local rebuild
                  if (isSelected != null) {
                    setState(() {
                      incDecSelected = isSelected;
                    });
                  }
                }

                return Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade200, Colors.indigo.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      ///// CLEAR AND APPLY /////
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              updateParentState(() {
                                _distanceSort.clear();
                                _distanceSort.add('increasing');
                                _ageSort.clear();
                                _heightSort.clear();
                              
                                sortCategories.clear(); // Clear sort categories
                              }, false);
                              saveAndApplySortArgs();
                              swipe_page.resetIndexAfterFiltering();
                              banner_view.loadListsAfterFiltering();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
                              shape: WidgetStatePropertyAll(StadiumBorder()),
                            ),
                            child: Text('clear sort'),
                          ),
                          TextButton(
                            onPressed: () {
                              saveAndApplySortArgs();
                              swipe_page.resetIndexAfterFiltering();
                              banner_view.loadListsAfterFiltering();
                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
                              shape: WidgetStatePropertyAll(StadiumBorder()),
                            ),
                            child: Text('apply sort'),
                          ),
                        ],
                      ),
                                            
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(height: 55),
                            
                                ///// DISTANCE /////
                                
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    //color: Color(0x50FFFFFF),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text('distance:'),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: _sortOptions.map((option) {
                                          return ChoiceChip(
                                            label: Text(option),
                                            selected: _distanceSort.contains(option),
                                            onSelected: (selected) {
                                              updateParentState(() {
                                                if (selected && !_distanceSort.contains(option)) {
                                                  _ageSort.clear();
                                                  _distanceSort.clear();
                                                  _heightSort.clear();
                                                  sortCategories.removeWhere((key) => key.startsWith('height_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('age_')); // Remove if exists
                                                  sortCategories.removeWhere((key) => key.startsWith('distance_')); // Remove if exists
                                                  sortCategories.add('distance_$option'); // Add to end to preserve order
                                                  print('sort menu: $sortCategories');
                                                  _distanceSort.add(option);
                                                  incDecSelected = true;
                                                } else if (!selected && _distanceSort.contains(option) && option != 'increasing') {
                                                  _distanceSort.remove(option);
                                                  sortCategories.remove('distance_$option'); // Remove if exists
                                                  sortCategories.removeWhere((key) => key.startsWith('age_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('height_'));
                                                  incDecSelected = false;
                                                }
                                              });
                                            },
                                            shape: StadiumBorder(),
                                            selectedColor: Colors.indigo[300],
                                            backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 55),
                                
                                ///// AGE /////
                                
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    //color: Color(0x50FFFFFF),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text('age:'),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: _sortOptions.map((option) {
                                          return ChoiceChip(
                                            label: Text(option),
                                            selected: _ageSort.contains(option),
                                            onSelected: (selected) {
                                              updateParentState(() {
                                                if (selected && !_ageSort.contains(option)) {
                                                  _ageSort.clear();
                                                  _distanceSort.clear();
                                                  _heightSort.clear();
                                                  _ageSort.add(option);
                                                  sortCategories.removeWhere((key) => key.startsWith('distance_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('height_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('age_')); // Remove if exists
                                                  sortCategories.add('age_$option'); // Add to end to preserve order
                                                  incDecSelected = true;
                                                } else if (!selected && _ageSort.contains(option)) {
                                                  _ageSort.remove(option);
                                                  _distanceSort.add('increasing');
                                                  sortCategories.remove('age_$option');
                                                  sortCategories.removeWhere((key) => key.startsWith('age_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('height_'));
                                                  incDecSelected = false;
                                                }
                                              });
                                            },
                                            shape: StadiumBorder(),
                                            selectedColor: Colors.indigo[300],
                                            backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 55),
                                
                                ///// HEIGHT /////
                                
                                Container(decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    //color: Color(0x50FFFFFF),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text('height:'),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: _sortOptions.map((option) {
                                          return ChoiceChip(
                                            label: Text(option),
                                            selected: _heightSort.contains(option),
                                            onSelected: (selected) {
                                              updateParentState(() {
                                                if (selected && !_heightSort.contains(option)) {
                                                  _ageSort.clear();
                                                  _distanceSort.clear();
                                                  _heightSort.clear();
                                                  _heightSort.add(option);
                                                  sortCategories.removeWhere((key) => key.startsWith('distance_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('age_')); // Remove if exists
                                                  sortCategories.removeWhere((key) => key.startsWith('height_')); // Remove if exists
                                                  sortCategories.add('height_$option'); // Add to end to preserve order
                                                  incDecSelected = true;
                                                } else if (!selected && _heightSort.contains(option)) {
                                                  _heightSort.remove(option);
                                                  _distanceSort.add('increasing');
                                                  sortCategories.remove('height_$option');
                                                  sortCategories.removeWhere((key) => key.startsWith('age_'));
                                                  sortCategories.removeWhere((key) => key.startsWith('height_'));
                                                  incDecSelected = false;
                                                }
                                              });
                                            },
                                            shape: StadiumBorder(),
                                            selectedColor: Colors.indigo[300],
                                            backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            )
                          ]
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: displaySorters,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
        foregroundColor: WidgetStatePropertyAll(Color(0x90000000)),
      ),
      icon: Icon(Icons.sort_rounded),
    );
  }
}
