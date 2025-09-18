import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:geolocator/geolocator.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

Future<List<Map<String, dynamic>>> searchBarQuery(query) async{  // Profile pictures should be queried but not cached until profiles are opened in the swipe view
  List<Map<String, dynamic>> batchProfiles = [];

  final firestore = FirebaseFirestore.instance;  // Firestore reference
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User must be signed in');
  
  final stopwatch = Stopwatch()..start();

  // Base query
  Query<Map<String, dynamic>> firestoreQuery = firestore
    .collection('user_ids')
    .where('name', isNotEqualTo: user.uid) // Don't load the user's own profile
    .orderBy('name')
    .limit(210);

  // Apply search filter if query is provided
  if (query != null && query.trim().isNotEmpty) {
    String searchQuery = query.trim();
    firestoreQuery = firestoreQuery
      .where('name', isGreaterThanOrEqualTo: searchQuery)
      .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
  }

  try{
    print('attempting query');
      final querySnapshot = await firestoreQuery.get();
      final profiles = querySnapshot.docs;

      print('Got ${profiles.length} profiles from firestore');
      
      for (var doc in profiles) {
        final data = doc.data();
        // final lat2 = data['latitude'] as double? ?? 0.0;
        // final lon2 = data['longitude'] as double? ?? 0.0;

        // if (lat2 == 0.0 || lon2 == 0.0) continue;  // skips invalid profiles by setting null lat as 0 and skipping
        
        // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        // final userLat = position.latitude;
        // final userLon = position.longitude;

        // double meters = Geolocator.distanceBetween(
        //   userLat, 
        //   userLon,   // your location
        //   lat2, 
        //   lon2          // other profile location
        // ); // returns meters
        
        // // convert to miles
        // double distance = meters * 0.00062137;

        // ////////////(distance);

        // // Cache images locally
        // Get profile pic path 
        // final phoneNumber =
        //     data['name']?.toString().replaceFirst('testUser', '') ?? 'Unknown';
        // final imagePaths = (data['imagePaths'] as List<dynamic>?)
        //         ?.where((url) => url is String && url.isNotEmpty)
        //         .toList() ??
        //     [];

        // List<String> cachedImagePaths = [];
        // String? profilePic;

        // // for (var imageUrl in imagePaths) {  // This caches all images in images list
        // //   try {
        // //     final cachedPath =
        // //         await _cacheImage(imageUrl, phoneNumber, doc.id);
        // //     if (cachedPath.isNotEmpty) {
        // //       cachedImagePaths.add(cachedPath);
        // //       if (imageUrl == imagePaths[0]) {
        // //         profilePic = cachedPath;
        // //       }
        // //     }
        // //   } catch (_) {}
        // // }  // 10 miles 82 profiles 78 seconds 

        // String profilePicPath = imagePaths[0];  // This only downloads and caches the profile pic. The other pictures can be downloaded and cached when the full profile is opened
        // dynamic profilePic = await loadProfilePic(profilePicPath);
        // final cachedProfilePicPath = await _cacheImage(profilePicPath, phoneNumber, doc.id);
        // if (cachedProfilePicPath.isNotEmpty) {
        //   cachedImagePaths.add(cachedProfilePicPath);
        //   profilePic = cachedProfilePicPath;
        // }  // 10 miles 82 profiles 28 sec

        // // This is good but now I need to load in all firestore image paths, get the download urls, and cache them to sqlite
        // // Then when I opent the profiles I can download the images to the doc dir

        //final phoneNumber = data['name']?.toString().replaceFirst('testUser', '') ?? 'Unknown';
        final imagePaths = (data['imagePaths'] as List<dynamic>?)
            ?.where((url) => url is String && url.isNotEmpty)
            .cast<String>()
            .toList() ??
        [];

        String? profilePicUrl;
        if (imagePaths.isNotEmpty) {
          try {
            // Get the download URL for the profile picture
            final ref = firebase_storage.FirebaseStorage.instance.ref().child(imagePaths[0]);
            profilePicUrl = await ref.getDownloadURL();
          } catch (e) {
            print('Error getting download URL for ${imagePaths[0]}: $e');
          }
        }

        final profile = {
          'profilePic': profilePicUrl,
          'images': imagePaths,
          'name': data['name'],
          'phone': data['phone'],
          'age': 'N/A',
          'height': data['height'] ?? 'N/A',
          'location': 'Euless, TX',
          'geohash': data['geohash'],
          //'distance': distance.toStringAsFixed(1),
          'intro': data['intro'] ?? '',
          'children': data['children'] ?? '',
          'relationship_intent': (data['relationship_intent'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'tags': (data['tags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'verified': data['verified'] ?? false,
        };

        batchProfiles.add(profile);
      }
    
    }
    catch(e) {
      print('You need to log in');
      print(e);
    }
  stopwatch.stop();
  print(stopwatch);
  return batchProfiles;
}

Future<dynamic> loadProfilePic(storagePath) async{
  final ref = firebase_storage.FirebaseStorage.instance.ref().child(storagePath);
  final url = await ref.getDownloadURL();
  final uri = Uri.parse(url);

  final response = await http.get(uri);  // Download the image
  if (response.statusCode != 200) throw Exception("Failed to download: ${response.statusCode}");

  return response;
}

Future<void> loadFullProfile(profile) async{  // The profiles from the query should not be cached until the user clicks on them to open them in the swipe view.

}
 
Future<String> _cacheImage(String storagePath, String phoneNumber, String docId) async {
  try {
    // Resolve path into URL (emulator or prod)
    final ref = firebase_storage.FirebaseStorage.instance.ref().child(storagePath);
    final url = await ref.getDownloadURL();

    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.last;

    final docDir = await getApplicationDocumentsDirectory();
    final filePath = '${docDir.path}/profile_images/$phoneNumber/$fileName';
    final file = File(filePath);

    if (!await file.exists()) { 
      final response = await http.get(uri);  // Download the image
      if (response.statusCode != 200) throw Exception("Failed to download: ${response.statusCode}");
      await file.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);  // Write image
    }

    await sqlite.DatabaseHelper.instance.cacheImage(docId, storagePath, filePath);
    return filePath;
  } catch (e) {
    print('Error caching image for $storagePath: $e');
    return '';
  }
}