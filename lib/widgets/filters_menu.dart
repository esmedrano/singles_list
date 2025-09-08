import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'dart:convert';

// This turns off the apply filters button while a query is occuring 
bool runningRings = false;
void toggleRings(bool running) {
  runningRings = running;
}

class FiltersMenu extends StatefulWidget {
  const FiltersMenu({
    super.key,
    required this.addNewFilteredProfiles
  });

  final Function(bool?) addNewFilteredProfiles;

  @override
  FiltersMenuState createState() => FiltersMenuState();
}

class FiltersMenuState extends State<FiltersMenu> {
  String _distance = '5 mi';
  bool _showDistance = false;
  bool _distanceInitialSync = false;

  String _ageMin = '18';
  String _ageMax = '25';
  bool _showAge = false;
  bool _ageInitialSync = false;

  String _heightMin = '4\' 0\"';
  String _heightMax = '5\' 8\"';
  bool _showHeight = false;
  bool _heightInitialSync = false;

  List<String> _childrenSelected = [];
  bool _showChildren = false;

  List<String> _personalityTypesSelected = [];
  bool _showPersonality = false;

  List<String> _relationshipIntentSelected = [];
  bool _showRelationshipIntent = false;

  List<String> _tagsSelected = [];
  bool _showTags = false;

  String _listSelection = '';
  bool _showLists = false;

  final List<String> _distanceOptions = ['5 mi', '10 mi', '25 mi', '50 mi', '75 mi', '100 mi', '125 mi', '150 mi', '175 mi', '200 mi'];
  final List<String> _ageOptions = ['18', '20', '25', '30', '35', '40', '45', '50 +'];
  final List<String> _heightOptions = [
    for (int feet = 4; feet <= 7; feet++)
      for (int inches = 0; inches <= 11; inches++)
        "$feet' ${inches.toString()}\""
  ];
  final List<String> _childrenOptions = ['has children', 'no children'];
  final List<String> _personalityTypes = ['Introvert', 'Extrovert', 'Ambivert'];
  final List<String> _tags = ['#fun', '#serious', '#adventurous', '#calm'];
  final List<String> _listOptions = ['List A', 'List B', 'List C', 'List D'];
  final List<String> _relationshipIntentOptions = ['Casual', 'Serious', 'Open'];

  late FixedExtentScrollController _distanceController;
  late FixedExtentScrollController _ageMinController;
  late FixedExtentScrollController _ageMaxController;
  late FixedExtentScrollController _heightMinController;
  late FixedExtentScrollController _heightMaxController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadFilterValues();
    });
    _distanceController = FixedExtentScrollController(
      initialItem: _distanceOptions.indexOf(_distance),
    );
    _ageMinController = FixedExtentScrollController(
      initialItem: _ageOptions.indexOf(_ageMin),
    );
    _ageMaxController = FixedExtentScrollController(
      initialItem: _ageOptions.indexOf(_ageMax),
    );
    _heightMinController = FixedExtentScrollController(
      initialItem: _heightOptions.indexOf(_heightMin),
    );
    _heightMaxController = FixedExtentScrollController(
      initialItem: _heightOptions.indexOf(_heightMax),
    );
  }

  Future<void> loadFilterValues() async {
    try {
      final db = sqlite.DatabaseHelper.instance;
      // Await each filter value with individual error handling
      String? distance;
      try {
        distance = await db.getFilterValue('distance');
        //print('Loaded distance: $distance');
      } catch (e) {
        //print('Error loading distance: $e');
        distance = '5 mi';
      }

      String? ageMin;
      try {
        ageMin = await db.getFilterValue('ageMin');
        //print('Loaded ageMin: $ageMin');
      } catch (e) {
        //print('Error loading ageMin: $e');
        ageMin = '18';
      }

      String? ageMax;
      try {
        ageMax = await db.getFilterValue('ageMax');
        //print('Loaded ageMax: $ageMax');
      } catch (e) {
        //print('Error loading ageMax: $e');
        ageMax = '25';
      }

      String? heightMin;
      try {
        heightMin = await db.getFilterValue('heightMin');
        //print('Loaded heightMin: $heightMin');
      } catch (e) {
        //print('Error loading heightMin: $e');
        heightMin = "4' 0\"";
      }

      String? heightMax;
      try {
        heightMax = await db.getFilterValue('heightMax');
        //print('Loaded heightMax: $heightMax');
      } catch (e) {
        //print('Error loading heightMax: $e');
        heightMax = "5' 8\"";
      }

      List<String> children = [];
      try {
        final childrenValue = await db.getFilterValue('children') ?? '[]';
        //print('Loaded childrenValue: $childrenValue');
        children = (jsonDecode(childrenValue) as List<dynamic>).cast<String>();
      } catch (e) {
        //print('Error decoding children: $e');
      }

      List<String> relationshipIntent = [];
      try {
        final relationshipIntentValue = await db.getFilterValue('relationshipIntent') ?? '[]';
        //print('Loaded relationshipIntentValue: $relationshipIntentValue');
        relationshipIntent = (jsonDecode(relationshipIntentValue) as List<dynamic>).cast<String>();
      } catch (e) {
        //print('Error decoding relationshipIntent: $e');
      }

      List<String> personalityTypes = [];
      try {
        final personalityTypesValue = await db.getFilterValue('personalityTypes') ?? '[]';
        //print('Loaded personalityTypesValue: $personalityTypesValue');
        personalityTypes = (jsonDecode(personalityTypesValue) as List<dynamic>).cast<String>();
      } catch (e) {
        //print('Error decoding personalityTypes: $e');
      }

      List<String> tags = [];
      try {
        final tagsValue = await db.getFilterValue('tags') ?? '[]';
        //print('Loaded tagsValue: $tagsValue');
        tags = (jsonDecode(tagsValue) as List<dynamic>).cast<String>();
      } catch (e) {
        //print('Error decoding tags: $e');
      }

      String? listSelection;
      try {
        listSelection = await db.getFilterValue('listSelection');
        //print('Loaded listSelection: $listSelection');
      } catch (e) {
        //print('Error loading listSelection: $e');
        listSelection = '';
      }

      if (mounted) {
        setState(() {
          _distance = distance ?? '5 mi';
          _ageMin = ageMin ?? '18';
          _ageMax = ageMax ?? '25';
          _heightMin = heightMin ?? "4' 0\"";
          _heightMax = heightMax ?? "5' 8\"";
          _childrenSelected = children;
          _relationshipIntentSelected = relationshipIntent;
          _personalityTypesSelected = personalityTypes;
          _tagsSelected = tags;
          _listSelection = listSelection ?? '';

          // Update scroll controllers
          _distanceController.jumpToItem(_distanceOptions.indexOf(_distance));
          _ageMinController.jumpToItem(_ageOptions.indexOf(_ageMin));
          _ageMaxController.jumpToItem(_ageOptions.indexOf(_ageMax));
          _heightMinController.jumpToItem(_heightOptions.indexOf(_heightMin));
          _heightMaxController.jumpToItem(_heightOptions.indexOf(_heightMax));
        });
      }
    } catch (e) {
      //print('Error loading filter values: $e');
      if (mounted) {
        setState(() {
          _distance = '5 mi';
          _ageMin = '18';
          _ageMax = '25';
          _heightMin = '4\' 0\"';
          _heightMax = '5\' 8\"';
          _childrenSelected = [];
          _relationshipIntentSelected = [];
          _personalityTypesSelected = [];
          _tagsSelected = [];
          _listSelection = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    _heightMinController.dispose();
    _heightMaxController.dispose();
    super.dispose();
  }

  Future<void> saveAndApplyFilterValues() async {
    try {
      final lastDistance = _distance;
      final lastAgeMin = _ageMin;
      final lastAgeMax = _ageMax;
      final lastHeightMin = _heightMin;
      final lastHeightMax = _heightMax;
      final lastChildren = _childrenSelected;
      final lastRelationshipIntent = _relationshipIntentSelected;
      final lastPersonalityTypes = _personalityTypesSelected;
      final lastTags = _tagsSelected;
      final lastListSelection = _listSelection;

      bool onlyDistanceChanged = false;

      final db = sqlite.DatabaseHelper.instance;
      await db.setFilterValue('distance', _distance);
      await db.setFilterValue('ageMin', _ageMin);
      await db.setFilterValue('ageMax', _ageMax);
      await db.setFilterValue('heightMin', _heightMin);
      await db.setFilterValue('heightMax', _heightMax);
      await db.setFilterValue('children', jsonEncode(_childrenSelected));
      await db.setFilterValue('relationshipIntent', jsonEncode(_relationshipIntentSelected));
      await db.setFilterValue('personalityTypes', jsonEncode(_personalityTypesSelected));
      await db.setFilterValue('tags', jsonEncode(_tagsSelected));
      await db.setFilterValue('listSelection', _listSelection);
      print('filters saved to sqlite');

      if (lastDistance != _distance &&  // This is only true if distance is the only filter updated 
          lastAgeMin == _ageMin && 
          lastAgeMax == _ageMax && 
          lastHeightMin == _heightMin && 
          lastHeightMax == _heightMax && 
          lastChildren == _childrenSelected && 
          lastRelationshipIntent == _relationshipIntentSelected && 
          lastPersonalityTypes == _personalityTypesSelected && 
          lastTags == _tagsSelected && 
          lastListSelection == _listSelection) {
        onlyDistanceChanged = true;
      }

      // Apply filters by sorting current cache and getting more if cache and page are empty
      widget.addNewFilteredProfiles(onlyDistanceChanged);
    } catch (e) {
      print('Error saving filter values: $e');
    }
  }

  void displayFilters() {
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
                return Container(
                  padding: EdgeInsets.all(10),
                  height: MediaQuery.of(context).size.height * 0.8,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: !runningRings 
                              ? () {
                                  setState(() {
                                    _distance = '5 mi';
                                    _ageMin = '18';
                                    _ageMax = '25';
                                    _heightMin = '4\' 0\"';
                                    _heightMax = '5\' 8\"';
                                    _childrenSelected.clear();
                                    _relationshipIntentSelected.clear();
                                    _personalityTypesSelected.clear();
                                    _tagsSelected.clear();
                                    _listSelection = '';
                                    _distanceController.jumpToItem(_distanceOptions.indexOf('5 mi'));
                                    _ageMinController.jumpToItem(_ageOptions.indexOf('18'));
                                    _ageMaxController.jumpToItem(_ageOptions.indexOf('25'));
                                    _heightMinController.jumpToItem(_heightOptions.indexOf('4\' 0\"'));
                                    _heightMaxController.jumpToItem(_heightOptions.indexOf('5\' 8\"'));
                                    _distanceInitialSync = false;
                                    _ageInitialSync = false;
                                    _heightInitialSync = false;
                                  });
                                  saveAndApplyFilterValues();
                                }
                              : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
                              shape: WidgetStatePropertyAll(StadiumBorder()),
                            ),
                            child: Text('Clear Filters'),
                          ),
                          TextButton(
                            onPressed: !runningRings 
                              ? () { 
                                  saveAndApplyFilterValues();
                                  Navigator.pop(context);
                                }
                              : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(Color(0x50FFFFFF)),
                              shape: WidgetStatePropertyAll(StadiumBorder()),
                            ),
                            child: Text('Apply Filters'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            SizedBox(height: 15),
                            // Distance filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showDistance = !_showDistance;
                                          if (_showDistance) {
                                            _distanceInitialSync = false;
                                          }
                                        });
                                      },
                                      child: Text('distance', style: TextStyle(color: Color(0xFF000000))),
                                    ),
                                  ),
                                  if (_showDistance)
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: 100,
                                          child: Builder(
                                            builder: (BuildContext context) {
                                              if (!_distanceInitialSync) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  if (_distanceController.hasClients) {
                                                    final index = _distanceOptions.contains(_distance) ? _distanceOptions.indexOf(_distance) : 0;
                                                    _distanceController.jumpToItem(index);
                                                    _distanceInitialSync = true;
                                                  }
                                                });
                                              }
                                              return SizedBox(
                                                width: 150,
                                                child: CupertinoPicker(
                                                  scrollController: _distanceController,
                                                  itemExtent: 35,
                                                  onSelectedItemChanged: (index) {
                                                    setState(() {
                                                      _distance = _distanceOptions[index];
                                                    });
                                                  },
                                                  children: _distanceOptions
                                                      .map((item) => Center(child: Text(item)))
                                                      .toList(),
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
                            SizedBox(height: 15),
                            // Age filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showAge = !_showAge;
                                          if (_showAge) {
                                            _ageInitialSync = false;
                                          }
                                        });
                                      },
                                      child: Text('age', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showAge)
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                              height: 100,
                                              child: Builder(
                                                builder: (BuildContext context) {
                                                  if (!_ageInitialSync) {
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (_ageMinController.hasClients) {
                                                        final index = _ageOptions.contains(_ageMin) ? _ageOptions.indexOf(_ageMin) : 0;
                                                        _ageMinController.jumpToItem(index);
                                                        _ageInitialSync = true;
                                                      }
                                                    });
                                                  }
                                                  return SizedBox(
                                                    width: 150,
                                                    child: CupertinoPicker(
                                                      scrollController: _ageMinController,
                                                      itemExtent: 35,
                                                      onSelectedItemChanged: (index) {
                                                        setState(() {
                                                          _ageMin = _ageOptions[index];
                                                          if (_ageOptions.indexOf(_ageMax) < index) {
                                                            _ageMax = _ageOptions[index];
                                                            _ageMaxController.jumpToItem(index);
                                                          }
                                                        });
                                                      },
                                                      children: _ageOptions
                                                          .map((item) => Center(child: Text(item)))
                                                          .toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            SizedBox(
                                              height: 100,
                                              child: Builder(
                                                builder: (BuildContext context) {
                                                  if (!_ageInitialSync) {
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (_ageMaxController.hasClients) {
                                                        final index = _ageOptions.contains(_ageMax) ? _ageOptions.indexOf(_ageMax) : 0;
                                                        _ageMaxController.jumpToItem(index);
                                                        _ageInitialSync = true;
                                                      }
                                                    });
                                                  }
                                                  return SizedBox(
                                                    width: 150,
                                                    child: CupertinoPicker(
                                                      scrollController: _ageMaxController,
                                                      itemExtent: 35,
                                                      onSelectedItemChanged: (index) {
                                                        setState(() {
                                                          final newMax = _ageOptions[index];
                                                          if (_ageOptions.indexOf(newMax) >= _ageOptions.indexOf(_ageMin)) {
                                                            _ageMax = newMax;
                                                          } else {
                                                            _ageMax = _ageMin;
                                                            _ageMaxController.jumpToItem(_ageOptions.indexOf(_ageMin));
                                                          }
                                                        });
                                                      },
                                                      children: _ageOptions
                                                          .map((item) => Center(child: Text(item)))
                                                          .toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Height filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showHeight = !_showHeight;
                                          if (_showHeight) {
                                            _heightInitialSync = false;
                                          }
                                        });
                                      },
                                      child: Text('height', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showHeight)
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                              height: 100,
                                              child: Builder(
                                                builder: (BuildContext context) {
                                                  if (!_heightInitialSync) {
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (_heightMinController.hasClients) {
                                                        final index = _heightOptions.contains(_heightMin) ? _heightOptions.indexOf(_heightMin) : 0;
                                                        _heightMinController.jumpToItem(index);
                                                        _heightInitialSync = true;
                                                      }
                                                    });
                                                  }
                                                  return SizedBox(
                                                    width: 150,
                                                    child: CupertinoPicker(
                                                      scrollController: _heightMinController,
                                                      itemExtent: 35,
                                                      onSelectedItemChanged: (index) {
                                                        setState(() {
                                                          _heightMin = _heightOptions[index];
                                                          if (_heightOptions.indexOf(_heightMax) < index) {
                                                            _heightMax = _heightOptions[index];
                                                            _heightMaxController.jumpToItem(index);
                                                          }
                                                        });
                                                      },
                                                      children: _heightOptions
                                                          .map((item) => Center(child: Text(item)))
                                                          .toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            SizedBox(
                                              height: 100,
                                              child: Builder(
                                                builder: (BuildContext context) {
                                                  if (!_heightInitialSync) {
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (_heightMaxController.hasClients) {
                                                        final index = _heightOptions.contains(_heightMax) ? _heightOptions.indexOf(_heightMax) : 0;
                                                        _heightMaxController.jumpToItem(index);
                                                        _heightInitialSync = true;
                                                      }
                                                    });
                                                  }
                                                  return SizedBox(
                                                    width: 150,
                                                    child: CupertinoPicker(
                                                      scrollController: _heightMaxController,
                                                      itemExtent: 35,
                                                      onSelectedItemChanged: (index) {
                                                        setState(() {
                                                          final newMax = _heightOptions[index];
                                                          if (_heightOptions.indexOf(newMax) >= _heightOptions.indexOf(_heightMin)) {
                                                            _heightMax = newMax;
                                                          } else {
                                                            _heightMax = _heightMin;
                                                            _heightMaxController.jumpToItem(_heightOptions.indexOf(_heightMin));
                                                          }
                                                        });
                                                      },
                                                      children: _heightOptions
                                                          .map((item) => Center(child: Text(item)))
                                                          .toList(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Children filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showChildren = !_showChildren;
                                        });
                                      },
                                      child: Text('children', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showChildren)
                                    Wrap(
                                      spacing: 8,
                                      children: _childrenOptions.map((option) {
                                        return ChoiceChip(
                                          label: Text(option),
                                          shape: StadiumBorder(),
                                          selectedColor: Colors.indigo[300],
                                          backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          selected: _childrenSelected.contains(option),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected && !_childrenSelected.contains(option)) {
                                                _childrenSelected.add(option);
                                              } else if (!selected && _childrenSelected.contains(option)) {
                                                _childrenSelected.remove(option);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Relationship Intent filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showRelationshipIntent = !_showRelationshipIntent;
                                        });
                                      },
                                      child: Text('relationship intent', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showRelationshipIntent)
                                    Wrap(
                                      spacing: 8,
                                      children: _relationshipIntentOptions.map((option) {
                                        return ChoiceChip(
                                          label: Text(option),
                                          shape: StadiumBorder(),
                                          selectedColor: Colors.indigo[200],
                                          backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          selected: _relationshipIntentSelected.contains(option),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected && !_relationshipIntentSelected.contains(option)) {
                                                _relationshipIntentSelected.add(option);
                                              } else if (!selected && _relationshipIntentSelected.contains(option)) {
                                                _relationshipIntentSelected.remove(option);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Personality Type filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showPersonality = !_showPersonality;
                                        });
                                      },
                                      child: Text('personality type', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showPersonality)
                                    Wrap(
                                      spacing: 8,
                                      children: _personalityTypes.map((type) {
                                        return ChoiceChip(
                                          label: Text(type),
                                          shape: StadiumBorder(),
                                          selectedColor: Colors.indigo[200],
                                          backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          selected: _personalityTypesSelected.contains(type),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected && !_personalityTypesSelected.contains(type)) {
                                                _personalityTypesSelected.add(type);
                                              } else if (!selected && _personalityTypesSelected.contains(type)) {
                                                _personalityTypesSelected.remove(type);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Tags filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showTags = !_showTags;
                                        });
                                      },
                                      child: Text('tags', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showTags)
                                    Wrap(
                                      spacing: 8,
                                      children: _tags.map((tag) {
                                        return ChoiceChip(
                                          label: Text(tag),
                                          shape: StadiumBorder(),
                                          selectedColor: Colors.indigo[200],
                                          backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          selected: _tagsSelected.contains(tag),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected && !_tagsSelected.contains(tag)) {
                                                _tagsSelected.add(tag);
                                              } else if (!selected && _tagsSelected.contains(tag)) {
                                                _tagsSelected.remove(tag);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            // Lists filter
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0x50FFFFFF),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showLists = !_showLists;
                                        });
                                      },
                                      child: Text('lists', style: TextStyle(color: Color(0xFF101010))),
                                    ),
                                  ),
                                  if (_showLists)
                                    Wrap(
                                      spacing: 8,
                                      children: _listOptions.map((option) {
                                        return ChoiceChip(
                                          label: Text(option),
                                          shape: StadiumBorder(),
                                          selectedColor: Colors.indigo[200],
                                          backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                          selected: _listSelection == option,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _listSelection = option;
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
    ).then((value) {
      if (mounted) {
        setState(() {
          _showDistance = false;
          _showAge = false;
          _showHeight = false;
          _showChildren = false;
          _showRelationshipIntent = false;
          _showPersonality = false;
          _showTags = false;
          _showLists = false;
          _distanceInitialSync = false;
          _ageInitialSync = false;
          _heightInitialSync = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        displayFilters();
      },
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF909090)),
      ),
      child: Text(
        'Filters',
        style: TextStyle(
          color: Color(0xFF101010),
        ),
      ),
    );
  }
}