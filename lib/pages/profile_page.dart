import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<File?> images = List.generate(6, (_) => null);  // This list will contain all images for the builder

  final ImagePicker _picker = ImagePicker();  // Image picker instance  
  
  final TextEditingController _controller = TextEditingController();  // Intro box setup
  final FocusNode _focusNode = FocusNode();  // Intro box setup
  
  List<String> tagsSelected = []; // Track selected tags
  bool showTags = false; // Toggle main Tags section
  Map<String, bool> categoryVisibility = {}; // Track visibility of each category

  String childrenSelection = '';  
  bool showChildren = false; 

  List<String> relationshipIntentSelected = [];
  bool showRelationshipIntent = false; 

  String personality = 'none';
  bool personalityInitialSync = false;
  bool showPersonality = false;

  String height = '5\' 0\"';
  bool showHeight = false;
  bool heightInitialSync = false;

  late FixedExtentScrollController personalityController;
  late FixedExtentScrollController heightController;  ///////////////

  // final List<String> tags = ['student', 'gym', 'reading', 'music', 'video games', 'cooking', ''];  
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
  final List<String> heightOptions = [  // Build the height list iteratively 
    for (int feet = 4; feet <= 7; feet++)
      for (int inches = 0; inches <= 11; inches++)
        "$feet' ${inches.toString()}\""
  ]; 

  @override
  void initState() {  // Initialize controllers with default values
    super.initState();  
    personalityController = FixedExtentScrollController(
      initialItem: personalityOptions.indexOf(personality),
    );
    heightController = FixedExtentScrollController(
      initialItem: heightOptions.indexOf(height),
    );  //////////////
  }

  @override
  void dispose() {
    personalityController.dispose();
    heightController.dispose();  /////////////
    
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {  // Get image from phone gallery
    var emptySlots = images.where((image) => image == null).length;
    
    if (emptySlots == 0) return; // No empty slots available
      
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (images[index] == null) {
            images[index] = File(pickedFile.path);
          }
        });
      }
    } catch(e) {
      print("Error picking image: $e");
    }
  }

  void _removeImage(int index) {  // Remove image
    setState(() {
      images[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Container(  // Drop down menu for view as profile and changing match preferences
            alignment: Alignment.topRight,
            margin: EdgeInsets.only(right: 10.5),
            child: MenuAnchor(
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                elevation: WidgetStatePropertyAll(0),
                ),
                    
              menuChildren: [
                MenuItemButton(onPressed: () {}, child: Text('View as profile')),
                MenuItemButton(onPressed: () {}, child: Text('Preferences'))
              ],
              alignmentOffset: Offset(-70, 0),
              builder: (_, MenuController controller, Widget? child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
            
                  icon: Icon(Icons.more_vert)
                );
              }
            ),
          ),
                    
          GridView.builder(  // Pictures grid
            shrinkWrap: true,  // Limit total height of the grid to the height of it's children instead of infinity
            physics: NeverScrollableScrollPhysics(),  // Disable scrolling (it's already in a scollable listView (soon))
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3/4,
            ),
            padding:  EdgeInsets.only(left: 10, right: 10),
            itemCount: 6, 
                    
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: images[index] == null ? Color(0x50FFFFFF) : null,
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
                        highlightColor: Color(0x50FFFFFF),
                        splashRadius: 5,
                        icon: Icon(
                          size: 30,
                          images[index] == null ? Icons.add : Icons.close,
                          color: Color.fromARGB(255, 70, 78, 66),
                        ),
                    
                        onPressed: () {
                          if (images[index] == null) {
                    
                            _pickImage(index);
                          } else {
                            _removeImage(index);
                          }
                        },
                      )
                    )
                  ]
                ),
              );
            }
          ),
          
          Container(  // Intro
            margin: EdgeInsets.all(10),
            child: TextField( 
              controller: _controller,
              focusNode: _focusNode,
              
              onTapOutside: (_) {  // Close keyboard and remove cursor 
                  _focusNode.unfocus();
                },
              
              minLines: 5,
              maxLines: 10,
            
              style: 
                TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 70, 78, 66)
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
            
              onSubmitted: (value) => null,  // Send to database
              onTap: () => _focusNode.requestFocus(),
            ),
          ),
          
          Container(  // Tags
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: EdgeInsets.only(left: 15, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Color(0x50FFFFFF),
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
                    child: Text('Tags'),
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
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (categoryVisibility[category] ?? false)
                            Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tagList.map((option) {
                                  if (option.isEmpty) return SizedBox.shrink();
                                  return ChoiceChip(
                                    label: Text(option),
                                    shape: StadiumBorder(),
                                    selectedColor: Colors.indigo[300],
                                    backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                    selected: tagsSelected.contains(option),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected && !tagsSelected.contains(option)) {
                                          tagsSelected.add(option);
                                        } else if (!selected && tagsSelected.contains(option)) {
                                          tagsSelected.remove(option);
                                        }
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
                    padding: EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Open dialog to add custom tag
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController customTagController = TextEditingController();
                              return AlertDialog(
                                title: Text('Add Custom Tag'),
                                content: TextField(
                                  controller: customTagController,
                                  decoration: InputDecoration(hintText: 'Enter tag'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      String newTag = customTagController.text.trim();
                                      if (newTag.isNotEmpty && !tagsSelected.contains(newTag)) {
                                        setState(() {
                                          tags.last['Custom']!.add(newTag);
                                          tagsSelected.add(newTag);
                                        });
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Add Custom Tag'),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(  // Children
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              color: Color(0x50FFFFFF),
              borderRadius: BorderRadius.circular(8)
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
                    child: Text('children', style: TextStyle(color: Color(0xFF101010))),
                  ),
                ),
                
                if (showChildren)
                  Wrap(
                    spacing: 8,
                    children: childrenOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        shape: StadiumBorder(),
                                                
                        selectedColor: Colors.indigo[300],
                        backgroundColor: Color.fromARGB(255, 151, 159, 209),
                                                
                        selected: childrenSelection == option,

                        onSelected: (selected) {
                          setState(() {
                            if (selected && childrenSelection != option) {
                              childrenSelection = option; // Select new option
                            } else if (!selected && childrenSelection == option) {
                              childrenSelection = ''; // Unselect if already selected
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          
          Container(  // Relationship
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            padding: EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              color: Color(0x50FFFFFF),
              borderRadius: BorderRadius.circular(8)
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
                    child: Text('relationship intent', style: TextStyle(color: Color(0xFF101010))),
                  ),
                ),
                      
                if (showRelationshipIntent)
                  Wrap(
                    spacing: 8,
                    children: relationshipIntentOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        shape: StadiumBorder(),                     
                        selectedColor: Colors.indigo[200],
                        backgroundColor: Color.fromARGB(255, 151, 159, 209),
                        selected: relationshipIntentSelected.contains(option),
                        onSelected: (selected) {
                          setState(() {
                            if (selected &&
                                !relationshipIntentSelected.contains(option)) {
                              relationshipIntentSelected.add(option);
                            } else if (!selected &&
                                relationshipIntentSelected.contains(option)) {
                              relationshipIntentSelected.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            )
          ),

          Container(  // Personality
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(  // Border
              borderRadius: BorderRadius.circular(10),
              color: Color(0x50FFFFFF),
            ),
                      
            child: Column(  // Column that expands when showPersonality is toggled
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(  // show personality button with info button stacked on top
                  children: [
                    SizedBox(  // Expand the button to entire container width 
                      width: double.infinity,

                      child: TextButton(  // The button
                        onPressed: () {
                          setState(() {
                            showPersonality = !showPersonality;
                          });
                        },
                        
                        child: Text('Personality Type'),
                      ),
                    ),
                    
                    if (showPersonality)  // Only show info button if expanded 

                    Positioned(  // Info button
                      right: 10,
                      child: IconButton(
                        onPressed: () {
                          // Show info pop up
                          // This app uses the Myers Briggs Personality types due to their consistent accuracy and popularity
                          // If you don't know your type you can take the short personality test at 16personalities.com 
                          // If you don't want to take the test, feel free to leave this blank and select some tags that you feel describe your personality instead 
                        },

                        icon: Icon(
                          Icons.info,
                          size: 20,
                          color: Color(0x50FFFFFF), 
                        ),
                      ),
                    ),
                  ],
                ),
                      
                if (showPersonality)  // Personality type options
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
                                      final index = personalityOptions.contains(personality) ? personalityOptions.indexOf(personality) : 0;
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
                                      });
                                    },
                                    children: personalityOptions
                                        .map((item) => Center(child: Text(item)))
                                        .toList(),
                                  );
                                }
                              )
                            ),
                          ),
                        ]
                      )
                    ]
                  )

              ]
            )
          ),

          Container(  // Height
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(  // Border
              borderRadius: BorderRadius.circular(10),
              color: Color(0x50FFFFFF),
            ),
                      
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(  // toggle height cuperitno picker
                  width: double.infinity,
                      
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showHeight = !showHeight;
                        if (showHeight) {
                            heightInitialSync = false; // Reset sync flag when opening
                        }
                      });
                    },
                    child: Text('height', style: TextStyle(color: Color(0xFF101010))),
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
                                      final index = heightOptions.contains(height) ? heightOptions.indexOf(height) : 0;
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
                                      });
                                    },
                                    children: heightOptions
                                        .map((item) => Center(child: Text(item)))
                                        .toList(),
                                  );
                                }
                              )
                            ),
                          ),
                        ]
                      )
                    ]
                  )
              ]
            )
          )
        ]
      ),
    );
  }
}
