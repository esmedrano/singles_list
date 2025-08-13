import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.switchPage,
  });

  final Function(int, int?) switchPage;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<File?> images = List.generate(6, (_) => null); // List for images
  List<File?> _originalImages = List.generate(6, (_) => null); // Track initial images
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  final TextEditingController _controller = TextEditingController(); // Intro box
  String _originalIntro = ''; // Track initial intro
  final FocusNode _focusNode = FocusNode();

  List<String> tagsSelected = []; // Track selected tags
  List<String> _originalTagsSelected = []; // Track initial tags
  bool showTags = false;
  Map<String, bool> categoryVisibility = {};

  String childrenSelection = '';
  String _originalChildrenSelection = ''; // Track initial children selection
  bool showChildren = false;

  List<String> relationshipIntentSelected = [];
  List<String> _originalRelationshipIntentSelected = []; // Track initial relationship intent
  bool showRelationshipIntent = false;

  String personality = 'none';
  String _originalPersonality = 'none'; // Track initial personality
  bool personalityInitialSync = false;
  bool showPersonality = false;

  String height = '5\' 0\"';
  String _originalHeight = '5\' 0\"'; // Track initial height
  bool showHeight = false;
  bool heightInitialSync = false;

  bool _hasUnsavedChanges = false; // Track if changes are made

  late FixedExtentScrollController personalityController;
  late FixedExtentScrollController heightController;

  // Tags list (unchanged)
  final List<Map<String, List<String>>> tags = [
    {
      'Outdoors': ['Hiking', 'Camping', 'Rock Climbing', 'Cycling', 'Kayaking', 'Paddleboarding', 'Fishing', 'Gardening', 'Bird Watching', 'Stargazing', 'Foraging', 'Surfing', 'Skiing', 'Snowboarding']
    },
    {
      'Creative': ['Photography', 'Videography', 'Painting', 'Drawing', 'Sculpting', 'Pottery', 'Knitting', 'Crocheting', 'Writing', 'Poetry', 'Calligraphy', 'Origami', 'Fashion Design', 'Music Production']
    },
    {
      'Sports & Fitness': ['Running', 'Yoga', 'Swimming', 'Fitness Training', 'Weightlifting', 'Martial Arts', 'Boxing', 'Tennis', 'Soccer', 'Basketball', 'Volleyball', 'Golf', 'Archery', 'Skateboarding']
    },
    {
      'Intellectual': ['Reading', 'Journaling', 'Blogging', 'Chess', 'Puzzles', 'Astronomy', 'History Buff', 'Language Learning', 'Debating', 'Book Club']
    },
    {
      'Entertainment': ['Video Games', 'Board Games', 'Tabletop RPGs', 'Movie Buff', 'Anime Watching', 'Concert Going', 'Theater Going', 'Stand-Up Comedy', 'Cosplay', 'Karaoke']
    },
    {
      'Food & Drink': ['Cooking', 'Baking', 'Food Tasting', 'Wine Tasting', 'Craft Beer Brewing', 'Mixology', 'Coffee Roasting', 'Food Blogging']
    },
    {
      'Music': ['Playing Guitar', 'Playing Piano', 'Singing', 'DJing', 'Drumming', 'Songwriting']
    },
    {
      'Lifestyle': ['Student', 'Traveling', 'Backpacking', 'Road Tripping', 'Volunteering', 'Pet Care', 'Minimalism', 'Sustainable Living']
    },
    {
      'Crafts & DIY': ['DIY Projects', 'Woodworking', 'Metalworking', 'Sewing', 'Model Building', 'Car Restoration']
    },
    {
      'Other': ['Collecting Vinyl Records', 'Collecting Books', 'Collecting Antiques', 'Urban Exploration', 'Meditation', 'Beekeeping', 'Horseback Riding']
    },
    {
      'Custom': [''] // Placeholder for user-added tags
    }
  ];
  final List<String> childrenOptions = ['I have children', 'no children'];
  final List<String> relationshipIntentOptions = ['Casual', 'Serious', 'Open'];
  final List<String> personalityOptions = ['none', 'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP', 'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP'];
  final List<String> heightOptions = [
    for (int feet = 4; feet <= 7; feet++)
      for (int inches = 0; inches <= 11; inches++)
        "$feet' ${inches.toString()}\""
  ];

  @override
  void initState() {
    super.initState();
    personalityController = FixedExtentScrollController(
      initialItem: personalityOptions.indexOf(personality),
    );
    heightController = FixedExtentScrollController(
      initialItem: heightOptions.indexOf(height),
    );

    // Load initial profile data from Firestore
    _loadProfileData();
  }

  @override
  void dispose() {
    personalityController.dispose();
    heightController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Load profile data from Firestore
  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _controller.text = data['intro'] ?? '';
        _originalIntro = _controller.text;
        tagsSelected = List<String>.from(data['tags'] ?? []);
        _originalTagsSelected = List<String>.from(tagsSelected);
        childrenSelection = data['children'] ?? '';
        _originalChildrenSelection = childrenSelection;
        relationshipIntentSelected = List<String>.from(data['relationship_intent'] ?? []);
        _originalRelationshipIntentSelected = List<String>.from(relationshipIntentSelected);
        personality = data['personality'] ?? 'none';
        _originalPersonality = personality;
        height = data['height'] ?? '5\' 0\"';
        _originalHeight = height;
        // Note: Images are not loaded here; handle image loading separately if stored in Firebase Storage
      });
    }
  }

  // Check if there are unsaved changes
  bool _checkForChanges() {
    return _controller.text != _originalIntro ||
        tagsSelected.toSet() != _originalTagsSelected.toSet() ||
        childrenSelection != _originalChildrenSelection ||
        relationshipIntentSelected.toSet() != _originalRelationshipIntentSelected.toSet() ||
        personality != _originalPersonality ||
        height != _originalHeight ||
        images.asMap().entries.any((entry) => entry.value?.path != _originalImages[entry.key]?.path);
  }

  // Future<void> _saveProfile() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     print('No user signed in');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No user signed in')),
  //     );
  //     return;
  //   }

  //   final data = {
  //     'intro': _controller.text,
  //     'tags': tagsSelected,
  //     'children': childrenSelection,
  //     'relationship_intent': relationshipIntentSelected,
  //     'personality': personality,
  //     'height': height,
  //     'updated_at': Timestamp.now(),
  //   };

  //   try {
  //     print('Saving profile for user ${user.uid} with data: $data');
  //     await FirebaseFirestore.instance
  //         .collection('profiles')
  //         .doc(user.uid)
  //         .set(data, SetOptions(merge: true));
      
  //     setState(() {
  //       _originalIntro = _controller.text;
  //       _originalTagsSelected = List<String>.from(tagsSelected);
  //       _originalChildrenSelection = childrenSelection;
  //       _originalRelationshipIntentSelected = List<String>.from(relationshipIntentSelected);
  //       _originalPersonality = personality;
  //       _originalHeight = height;
  //       _originalImages = List<File?>.from(images);
  //       _hasUnsavedChanges = false;
  //     });

  //     print('Profile saved successfully for user ${user.uid}');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Profile saved successfully')),
  //     );
  //   } catch (e, stackTrace) {
  //     print('Error saving profile: $e\n$stackTrace');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to save profile: $e')),
  //     );
  //   }
  // }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user signed in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    final data = {
      'intro': _controller.text,
      'tags': tagsSelected,
      'children': childrenSelection,
      'relationship_intent': relationshipIntentSelected,
      'personality': personality,
      'height': height,
      'updated_at': Timestamp.now(),
    };

    try {
      print('Checking profile existence for user ${user.uid}...');

      final docRef = FirebaseFirestore.instance.collection('profiles').doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // print('Profile not found for user ${user.uid}, skipping update.');
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Profile not found — update skipped')),
        // );
        print('Creating new profile for user ${user.uid} with data: $data');
        await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set(data);
      } 

      print('Updating profile for user ${user.uid} with data: $data');
      
      try {
        await docRef.update(data);
      } catch (e) {
          await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid);
          //.set(data);
      }

      setState(() {
        _originalIntro = _controller.text;
        _originalTagsSelected = List<String>.from(tagsSelected);
        _originalChildrenSelection = childrenSelection;
        _originalRelationshipIntentSelected = List<String>.from(relationshipIntentSelected);
        _originalPersonality = personality;
        _originalHeight = height;
        _originalImages = List<File?>.from(images);
        _hasUnsavedChanges = false;
      });

      print('Profile updated successfully for user ${user.uid}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

    } catch (e, stackTrace) {
      print('Error updating profile: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  // Show confirmation dialog if there are unsaved changes
  Future<bool> _showUnsavedChangesDialog(int page, int? index) async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Would you like to save them before switching pages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _saveProfile();
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.switchPage(page, index);
    }
    return result ?? false;
  }

  Future<void> _pickImage(int index) async {
    var emptySlots = images.where((image) => image == null).length;

    if (emptySlots == 0) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (images[index] == null) {
            images[index] = File(pickedFile.path);
            _hasUnsavedChanges = _checkForChanges();
          }
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      images[index] = null;
      _hasUnsavedChanges = _checkForChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Save button (visible only when there are unsaved changes)
                _hasUnsavedChanges
                    ? TextButton(
                        onPressed: _saveProfile,
                        child: Text('Save'),
                      )
                    : const SizedBox(width: 30), // Placeholder to maintain layout
                // Menu button
                MenuAnchor(
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                    elevation: WidgetStatePropertyAll(0),
                  ),
                  menuChildren: [
                    MenuItemButton(onPressed: () {}, child: const Text('View as profile')),
                    MenuItemButton(onPressed: () {}, child: const Text('Preferences')),
                    MenuItemButton(
                      onPressed: () => _hasUnsavedChanges ? _showUnsavedChangesDialog(4, null) : widget.switchPage(4, null),
                      child: const Text('Settings'),
                    ),
                  ],
                  alignmentOffset: const Offset(-86, 0),
                  builder: (_, MenuController controller, Widget? child) {
                    return IconButton(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      iconSize: 30,
                      icon: const Icon(Icons.more_vert),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 4,
                  ),
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: images[index] == null ? const Color(0x50FFFFFF) : null,
                        borderRadius: BorderRadius.circular(8),
                        image: images[index] != null
                            ? DecorationImage(
                                image: FileImage(images[index]!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 1,
                            right: 1,
                            child: IconButton(
                              highlightColor: const Color(0x50FFFFFF),
                              splashRadius: 5,
                              icon: Icon(
                                size: 30,
                                images[index] == null ? Icons.add : Icons.close,
                                color: const Color.fromARGB(255, 70, 78, 66),
                              ),
                              onPressed: () {
                                if (images[index] == null) {
                                  _pickImage(index);
                                } else {
                                  _removeImage(index);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onTapOutside: (_) {
                      _focusNode.unfocus();
                    },
                    minLines: 5,
                    maxLines: 10,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 70, 78, 66),
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(fontSize: 14, color: Color.fromARGB(255, 70, 78, 66)),
                      hintText: 'Write an intro!',
                      fillColor: Color(0x50FFFFFF),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _hasUnsavedChanges = _checkForChanges();
                      });
                    },
                    onTap: () => _focusNode.requestFocus(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  padding: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x50FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showTags = !showTags;
                            });
                          },
                          child: const Text('Tags'),
                        ),
                      ),
                      if (showTags)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tags.map((categoryMap) {
                            final category = categoryMap.keys.first;
                            final tagList = categoryMap[category]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        categoryVisibility[category] = !(categoryVisibility[category] ?? false);
                                      });
                                    },
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (categoryVisibility[category] ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: tagList.map((option) {
                                        if (option.isEmpty) return const SizedBox.shrink();
                                        return ChoiceChip(
                                          label: Text(option),
                                          shape: const StadiumBorder(),
                                          selectedColor: Colors.indigo[300],
                                          backgroundColor: const Color.fromARGB(255, 151, 159, 209),
                                          selected: tagsSelected.contains(option),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected && !tagsSelected.contains(option)) {
                                                tagsSelected.add(option);
                                              } else if (!selected && tagsSelected.contains(option)) {
                                                tagsSelected.remove(option);
                                              }
                                              _hasUnsavedChanges = _checkForChanges();
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      if (showTags)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    TextEditingController customTagController = TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Add Custom Tag'),
                                      content: TextField(
                                        controller: customTagController,
                                        decoration: const InputDecoration(hintText: 'Enter tag'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            String newTag = customTagController.text.trim();
                                            if (newTag.isNotEmpty && !tagsSelected.contains(newTag)) {
                                              setState(() {
                                                tags.last['Custom']!.add(newTag);
                                                tagsSelected.add(newTag);
                                                _hasUnsavedChanges = _checkForChanges();
                                              });
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text('Add Custom Tag'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  padding: const EdgeInsets.only(left: 15),
                  decoration: BoxDecoration(
                    color: const Color(0x50FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showChildren = !showChildren;
                            });
                          },
                          child: const Text('children', style: TextStyle(color: Color(0xFF101010))),
                        ),
                      ),
                      if (showChildren)
                        Wrap(
                          spacing: 8,
                          children: childrenOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option),
                              shape: const StadiumBorder(),
                              selectedColor: Colors.indigo[300],
                              backgroundColor: const Color.fromARGB(255, 151, 159, 209),
                              selected: childrenSelection == option,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected && childrenSelection != option) {
                                    childrenSelection = option;
                                  } else if (!selected && childrenSelection == option) {
                                    childrenSelection = '';
                                  }
                                  _hasUnsavedChanges = _checkForChanges();
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  padding: const EdgeInsets.only(left: 15),
                  decoration: BoxDecoration(
                    color: const Color(0x50FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showRelationshipIntent = !showRelationshipIntent;
                            });
                          },
                          child: const Text('relationship intent', style: TextStyle(color: Color(0xFF101010))),
                        ),
                      ),
                      if (showRelationshipIntent)
                        Wrap(
                          spacing: 8,
                          children: relationshipIntentOptions.map((option) {
                            return ChoiceChip(
                              label: Text(option),
                              shape: const StadiumBorder(),
                              selectedColor: Colors.indigo[200],
                              backgroundColor: const Color.fromARGB(255, 151, 159, 209),
                              selected: relationshipIntentSelected.contains(option),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected && !relationshipIntentSelected.contains(option)) {
                                    relationshipIntentSelected.add(option);
                                  } else if (!selected && relationshipIntentSelected.contains(option)) {
                                    relationshipIntentSelected.remove(option);
                                  }
                                  _hasUnsavedChanges = _checkForChanges();
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0x50FFFFFF),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  showPersonality = !showPersonality;
                                });
                              },
                              child: const Text('Personality Type'),
                            ),
                          ),
                          if (showPersonality)
                            Positioned(
                              right: 10,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('About Personality Types'),
                                      content: const Text(
                                        'This app uses the Myers-Briggs Personality Types due to their consistent accuracy and popularity.\n\n'
                                        'If you don\'t know your type, you can take the short personality test at 16personalities.com.\n\n'
                                        'If you don\'t want to take the test, feel free to leave this blank and select some tags that describe your personality instead.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.info,
                                  size: 20,
                                  color: Color(0x50FFFFFF),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (showPersonality)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 70,
                                    child: Builder(
                                      builder: (BuildContext context) {
                                        if (!personalityInitialSync) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (personalityController.hasClients) {
                                              final index = personalityOptions.contains(personality)
                                                  ? personalityOptions.indexOf(personality)
                                                  : 0;
                                              personalityController.jumpToItem(index);
                                              personalityInitialSync = true;
                                            }
                                          });
                                        }
                                        return CupertinoPicker(
                                          scrollController: personalityController,
                                          itemExtent: 30,
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              personality = personalityOptions[index];
                                              _hasUnsavedChanges = _checkForChanges();
                                            });
                                          },
                                          children: personalityOptions
                                              .map((item) => Center(child: Text(item)))
                                              .toList(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0x50FFFFFF),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showHeight = !showHeight;
                              if (showHeight) {
                                heightInitialSync = false;
                              }
                            });
                          },
                          child: const Text('height', style: TextStyle(color: Color(0xFF101010))),
                        ),
                      ),
                      if (showHeight)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 70,
                                    child: Builder(
                                      builder: (BuildContext context) {
                                        if (!heightInitialSync) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (heightController.hasClients) {
                                              final index = heightOptions.contains(height)
                                                  ? heightOptions.indexOf(height)
                                                  : 0;
                                              heightController.jumpToItem(index);
                                              heightInitialSync = true;
                                            }
                                          });
                                        }
                                        return CupertinoPicker(
                                          scrollController: heightController,
                                          itemExtent: 30,
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              height = heightOptions[index];
                                              _hasUnsavedChanges = _checkForChanges();
                                            });
                                          },
                                          children: heightOptions
                                              .map((item) => Center(child: Text(item)))
                                              .toList(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
  }
}
