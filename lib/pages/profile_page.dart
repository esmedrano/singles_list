// In profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:integra_date/databases/sqlite_database.dart';
import 'package:integra_date/scripts/ml_profile_verification.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart'; // For input formatters
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

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
  List<File?> images = List.generate(6, (_) => null);
  List<File?> _originalImages = List.generate(6, (_) => null);
  List<String> imageUrls = List.generate(6, (_) => '');
  List<String> _originalImageUrls = List.generate(6, (_) => '');
  final ImagePicker _picker = ImagePicker();
  bool profileVerified = false;
  bool _originalProfileVerified = false;
  final TextEditingController _introController = TextEditingController();
  String _originalIntro = '';
  final FocusNode _introFocusNode = FocusNode();

  bool showNameAge = false;
  final TextEditingController _nameController = TextEditingController();
  String _originalName = '';
  final FocusNode _nameFocusNode = FocusNode();
  final TextEditingController _ageController = TextEditingController();
  String _originalAge = '';
  final FocusNode _ageFocusNode = FocusNode();

  List<String> tagsSelected = [];
  List<String> _originalTagsSelected = [];
  bool showTags = false;
  Map<String, bool> categoryVisibility = {};
  String childrenSelection = '';
  String _originalChildrenSelection = '';
  bool showChildren = false;
  List<String> relationshipIntentSelected = [];
  List<String> _originalRelationshipIntentSelected = [];
  bool showRelationshipIntent = false;
  String personality = 'none';
  String _originalPersonality = 'none';
  bool personalityInitialSync = false;
  bool showPersonality = false;
  String height = '5\' 0\"';
  String _originalHeight = '5\' 0\"';
  bool showHeight = false;
  bool heightInitialSync = false;
  bool _hasUnsavedChanges = false;
  late FixedExtentScrollController personalityController;
  late FixedExtentScrollController heightController;

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
      'Custom': ['']
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
    _nameFocusNode.addListener(_handleNameFocusChange);
    personalityController = FixedExtentScrollController(
      initialItem: personalityOptions.indexOf(personality),
    );
    heightController = FixedExtentScrollController(
      initialItem: heightOptions.indexOf(height),
    );
    _loadProfileData();
  }

  @override
  void dispose() {
    personalityController.dispose();
    heightController.dispose();
    _introController.dispose();
    _introFocusNode.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _nameFocusNode.removeListener(_handleNameFocusChange);
    _ageController.dispose();
    _ageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user signed in at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      debugPrint('User phone number is null or empty at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required to save profile')),
      );
      return;
    }

    String capitalizedName = _capitalizeWords(_nameController.text);

    final data = {
      'verified': profileVerified,
      'intro': _introController.text,
      'name': capitalizedName,
      'age': _ageController.text,
      'tags': tagsSelected,
      'children': childrenSelection,
      'relationship_intent': relationshipIntentSelected,
      'personality': personality,
      'height': height,
      'imageUrls': imageUrls,
      'updated_at': Timestamp.now().millisecondsSinceEpoch, // Convert to milliseconds
    };

    try {
      debugPrint('Checking profile existence for user ${user.uid} in user_ids collection at ${DateTime.now()}');
      String docTitle = await sqlite.DatabaseHelper.instance.getUserDocTitle();
      final docRef = FirebaseFirestore.instance.collection('user_ids').doc(docTitle);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        debugPrint('Creating profile for user ${user.uid} with data: $data and phone number ${user.phoneNumber} at ${DateTime.now()}');
        await docRef.set(data);
      } else {
        debugPrint('Updating profile for user ${user.uid} with data: $data and phone number ${user.phoneNumber} at ${DateTime.now()}');
        await docRef.update(data);
      }
      
      await DatabaseHelper.instance.cacheUserMetadata('profileData', data);
      print(data);

      setState(() {
        _originalProfileVerified = profileVerified;
        _originalIntro = _introController.text;
        _originalName = _nameController.text;
        _originalAge = _ageController.text;
        _originalTagsSelected = List<String>.from(tagsSelected);
        _originalChildrenSelection = childrenSelection;
        _originalRelationshipIntentSelected = List<String>.from(relationshipIntentSelected);
        _originalPersonality = personality;
        _originalHeight = height;
        _originalImages = List<File?>.from(images);
        _originalImageUrls = List<String>.from(imageUrls);
        _hasUnsavedChanges = false;
      });
      debugPrint('Profile updated successfully for user ${user.uid} at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error updating profile: $e\n$stackTrace at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user signed in at ${DateTime.now()}');
      return;
    }
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      debugPrint('User phone number is null or empty at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required to load profile')),
      );
      return;
    }
    final metadata = await DatabaseHelper.instance.getUserMetadata('profileData');  // No key needed to fetch full user metadata
    print('Metadata: $metadata');
    if (metadata != null) {
      setState(() {
        profileVerified = metadata['verified'] ?? false;
        _originalProfileVerified = profileVerified;
        _introController.text = metadata['intro'] ?? '';
        _nameController.text = metadata['name'] ?? '';
        _ageController.text = metadata['age'] ?? '';
        _originalIntro = _introController.text;
        _originalName = _nameController.text;
        _originalAge = _ageController.text;
        tagsSelected = List<String>.from(metadata['tags'] ?? []);
        _originalTagsSelected = List<String>.from(tagsSelected);
        childrenSelection = metadata['children'] ?? '';
        _originalChildrenSelection = childrenSelection;
        relationshipIntentSelected = List<String>.from(metadata['relationship_intent'] ?? []);
        _originalRelationshipIntentSelected = List<String>.from(relationshipIntentSelected);
        personality = metadata['personality'] ?? 'none';
        _originalPersonality = personality;
        height = metadata['height'] ?? '5\' 0\"';
        _originalHeight = height;
        imageUrls = List<String>.from(metadata['imageUrls'] ?? List.generate(6, (_) => ''));
        _originalImageUrls = List<String>.from(imageUrls);
        for (int i = 0; i < imageUrls.length; i++) {
          if (imageUrls[i].isNotEmpty) {
            final file = File(imageUrls[i]);
            if (file.existsSync()) images[i] = file;
            _originalImages[i] = images[i];
          }
        }
        _hasUnsavedChanges = _checkForChanges();
      });
    } 
  }

  Future<void> _pickImage(int index) async {
    debugPrint('Starting image upload process for index $index at ${DateTime.now()}');
    var emptySlots = images.where((image) => image == null).length;
    if (emptySlots == 0) {
      debugPrint('No empty slots available for new images at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No empty slots available for new images')),
      );
      return;
    }

    try {
      debugPrint('Picking image from gallery at ${DateTime.now()}');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('No image selected at ${DateTime.now()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user signed in at ${DateTime.now()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user signed in')),
        );
        return;
      }
      debugPrint('User signed in: ${user.uid} at ${DateTime.now()}');

      File compressedFile;
      if (!kIsWeb) {
        debugPrint('Compressing image at ${DateTime.now()}');
        final File imageFile = File(pickedFile.path);
        final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) {
          debugPrint('Failed to decode image at ${DateTime.now()}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process image')),
          );
          return;
        }

        final img.Image resizedImage = img.copyResize(image, width: 800, height: 800);
        final compressedBytes = img.encodeJpg(resizedImage, quality: 75);
        final tempDir = await getTemporaryDirectory();
        compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg')
          ..writeAsBytesSync(compressedBytes);
        debugPrint('Compressed image size: ${(await compressedFile.length()) / 1024 / 1024} MB at ${DateTime.now()}');
      } else {
        compressedFile = File(pickedFile.path);
        debugPrint('Using original image for web platform at ${DateTime.now()}');
      }

      debugPrint('Showing upload progress dialog at ${DateTime.now()}');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Uploading image...'),
            ],
          ),
        ),
      );

      if (kDebugMode) {
        //FirebaseStorage.instance.useStorageEmulator('192.168.1.153', 9199);
        //debugPrint('Storage emulator configured: 192.168.1.153:9199 at ${DateTime.now()}');
      }

      debugPrint('Using storage bucket: ${FirebaseStorage.instance.bucket} at ${DateTime.now()}');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      debugPrint('Uploading to storage path: ${storageRef.fullPath} at ${DateTime.now()}');

      final uploadTask = storageRef.putFile(compressedFile);
      debugPrint('Starting upload task at ${DateTime.now()}');
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(2)}% at ${DateTime.now()}');
      });

      int retryCount = 0;
      const int maxRetries = 3;
      TaskSnapshot? snapshot;
      while (retryCount < maxRetries) {
        try {
          snapshot = await uploadTask.timeout(const Duration(seconds: 30));
          break;
        } catch (e) {
          retryCount++;
          debugPrint('Upload attempt $retryCount failed: $e at ${DateTime.now()}');
          if (retryCount == maxRetries) {
            throw Exception('Failed to upload after $maxRetries attempts: $e');
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      debugPrint('Upload task completed with state: ${snapshot!.state} at ${DateTime.now()}');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Download URL obtained: $downloadUrl at ${DateTime.now()}');

      Navigator.pop(context); // Close progress dialog

      setState(() {
        if (images[index] == null) {
          images[index] = compressedFile;
          imageUrls[index] = downloadUrl;
          _hasUnsavedChanges = _checkForChanges();
        }
      });

      debugPrint('Saving profile data at ${DateTime.now()}');
      await _saveProfile();
      debugPrint('Profile saved successfully at ${DateTime.now()}');
    } catch (e, stackTrace) {
      debugPrint('Error uploading image: $e\nStackTrace: $stackTrace at ${DateTime.now()}');
      Navigator.pop(context); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user signed in at ${DateTime.now()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    debugPrint('Attempting to remove image at index $index, current imageUrls: $imageUrls at ${DateTime.now()}');

    if (imageUrls[index].isNotEmpty) {
      try {
        debugPrint('Deleting image from Firebase Storage: ${imageUrls[index]} at ${DateTime.now()}');
        //final storageRef = FirebaseStorage.instance.refFromURL(imageUrls[index]);
        final storageRef = FirebaseStorage.instance.ref().child(Uri.parse(imageUrls[index]).path.split('/o/').last.split('?').first);        
        await storageRef.delete();
        debugPrint('Image deleted successfully from Firebase Storage at ${DateTime.now()}');
      } catch (e) {
        debugPrint('Error deleting image from Firebase Storage: $e at ${DateTime.now()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image from storage: $e')),
        );
        print(e);
      }
    } else {
      debugPrint('No image URL to delete at index $index at ${DateTime.now()}');
    }

    setState(() {
      images[index] = null;
      imageUrls[index] = '';
      _hasUnsavedChanges = _checkForChanges();
    });

    await _saveProfile();
  }

  bool _checkForChanges() {
    return _originalProfileVerified != profileVerified ||
        _introController.text != _originalIntro ||
        _nameController.text != _originalName ||
        _ageController.text != _originalAge ||
        tagsSelected.toSet() != _originalTagsSelected.toSet() ||
        childrenSelection != _originalChildrenSelection ||
        relationshipIntentSelected.toSet() != _originalRelationshipIntentSelected.toSet() ||
        personality != _originalPersonality ||
        height != _originalHeight ||
        images.asMap().entries.any((entry) => entry.value?.path != _originalImages[entry.key]?.path) ||
        imageUrls.toSet() != _originalImageUrls.toSet();
  }

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

  Future<void> _verifyFace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    if (images.every((image) => image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload at least one profile photo before verification.'),
          action: SnackBarAction(
            label: 'Upload Photos',
            onPressed: () => _pickImage(images.indexWhere((image) => image == null)),
          ),
        ),
      );
      return;
    }

    bool isProcessing = true;
    final livenessBytes = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          if (isProcessing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please complete or cancel the liveness verification.')),
            );
            return false;
          }
          return true;
        },
        child: Dialog.fullscreen(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: LivenessCaptureScreen(
            onCaptureComplete: (bytes) {
              isProcessing = false;
              Navigator.pop(context, bytes);
            },
            onCancel: () {
              isProcessing = false;
              Navigator.pop(context, null);
            },
          ),
        ),
      ),
    ).timeout(const Duration(seconds: 60), onTimeout: () {
      isProcessing = false;
      return null;
    });

    if (livenessBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liveness verification canceled or failed. Please try again.')),
      );
      return;
    }

    bool profileVerified = false;
    for (final profilePhoto in images) {
      if (profilePhoto == null) continue;
      final profileBytes = await profilePhoto.readAsBytes();
      final isMatch = await compareFaces(livenessBytes, profileBytes);
      if (isMatch) {
        profileVerified = true;
        break;
      }
    }

    if (profileVerified) {
      setState(() {
        this.profileVerified = true;
        _hasUnsavedChanges = _checkForChanges();
      });
      await _saveProfile();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verification Successful'),
          content: const Text('Your photo has been successfully verified.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No match found. Please upload better profile photos.'),
          action: SnackBarAction(
            label: 'Upload Photos',
            onPressed: () => _pickImage(images.indexWhere((image) => image == null)),
          ),
        ),
      );
    }
  }
  
  void _handleNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      // Capitalize words when focus is lost (e.g., tap outside, keyboard close, or Done)
      final formattedName = _capitalizeWords(_nameController.text);
      _nameController.text = formattedName;
      setState(() {
        _hasUnsavedChanges = _checkForChanges();
      });
    }
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input
      .split(' ')
      .map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : word)
      .join(' ');
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
                _hasUnsavedChanges
                    ? TextButton(
                        onPressed: _saveProfile,
                        child: const Text('Save'),
                      )
                    : const SizedBox(width: 30),
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
                  child: profileVerified
                      ? const Text(
                          'You\'re verified!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : TextButton(
                          onPressed: _verifyFace,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: const Color(0x50FFFFFF),
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text(
                            'Verify Profile',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                ),

                Container(
                  margin: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _introController,
                    focusNode: _introFocusNode,
                    onTapOutside: (_) {
                      _introFocusNode.unfocus();
                    },
                    minLines: 5,
                    maxLines: 10,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 70, 78, 66),
                    ),
                    decoration: InputDecoration(
                      hintStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 70, 78, 66)),
                      hintText: 'Write an intro!',
                      fillColor: const Color(0x50FFFFFF),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                    onTap: () => _introFocusNode.requestFocus(),
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
                    children:[
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showNameAge = !showNameAge;
                            });
                          },
                          child: const Text('name and age'),
                        ),
                      ),
                      
                      if (showNameAge)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text('Name: ')
                              ),
                              
                              SizedBox(width: 10),
                              
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                        
                                  textInputAction: TextInputAction.done, // Show "Done" on keyboard
                                  onSubmitted: (_) {
                                    // Handle keyboard "Done" action
                                    _nameFocusNode.unfocus();
                                    // Capitalization is handled by _handleNameFocusChange
                                  },
                        
                                  // onTapOutside: (_) {
                                  //   _nameFocusNode.unfocus();
                                  // },

                                  minLines: 1,
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 70, 78, 66)),
                                    fillColor: const Color(0x50FFFFFF),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                                  onTap: () => _nameFocusNode.requestFocus(),
                                ),
                              ),
                              
                              SizedBox(width: 10),
                            ],
                          ),

                          SizedBox(height: 10),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text('Age: ')
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _ageController,
                                  focusNode: _ageFocusNode,
                                  
                                  textInputAction: TextInputAction.done, // Show "Done" on keyboard
                                  onSubmitted: (_) {
                                    _ageFocusNode.unfocus();
                                    setState(() {
                                      _hasUnsavedChanges = _checkForChanges();
                                    });
                                  },
                                  
                                  onTapOutside: (_) {
                                    _ageFocusNode.unfocus();
                                  },
                                  
                                  minLines: 1,
                                  keyboardType: TextInputType.numberWithOptions(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                                    LengthLimitingTextInputFormatter(2), // Limit to 2 digits
                                  ],
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 70, 78, 66)),
                                    fillColor: const Color(0x50FFFFFF),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                                  onTap: () => _ageFocusNode.requestFocus(),
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ]
                      ),
                      
                    ],
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