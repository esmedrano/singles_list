import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:integra_date/databases/geohash_grid.dart' as geohash_grid;

Future<void> logFirestoreContents() async {
  print('\n\n=== Firestore user_ids Collection Contents ===');
  try {
    final firestore = FirebaseFirestore.instance;
    //await FirebaseFirestore.instance.clearPersistence();  // maybe the firestore instance is stale
    final querySnapshot = await firestore.collection('user_ids').get();
    final docs = querySnapshot.docs;

    if (docs.isEmpty) {
      print('Firestore: No documents found in user_ids collection');
    } else {
      print('Firestore: Found ${docs.length} documents');
      int onePrint = 0;
      for (var doc in docs) {
        final data = doc.data();
        // Pretty-print JSON with indentation
        // final jsonEncoded = JsonEncoder.withIndent('  ').convert({
        //   'docId': doc.id,
        //   'data': data,
        // });
        if (onePrint <= 1) {
         print('Document:\n${data['imageUrls']}');
         onePrint ++;
        }

        // http://192.168.1.153:9199/v0/b/integridate.firebasestorage.app/o/profile_images%2F%2B123456789000%2Fthrough%20the%20dome.webp?alt=media
      }
    }
  } catch (e) {
    print('Firestore: Error fetching contents: $e');
  }
  print('=== End Firestore Contents ===\n\n');
}

Future<void> logDocumentDirectoryContents() async {
  print('\n\n=== Phone Document Directory Contents (Profile Images) ===');
  try {
    final docDir = await getApplicationDocumentsDirectory();
    final profileImagesDir = Directory('${docDir.path}/profile_images');
    
    if (!await profileImagesDir.exists()) {
      print('Profile images directory does not exist: ${profileImagesDir.path}');
    } else {
      final entities = profileImagesDir.listSync(recursive: false);
      print('Profile images directory: ${profileImagesDir.path}');
      print('Found ${entities.length} items');
      
      if (entities.isEmpty) {
        print('  No files or directories found');
      } else {
        for (var entity in entities) {
          if (entity is File) {
            //print('  File: ${entity.path} (exists: ${await entity.exists()})');
          } else if (entity is Directory) {
            //print('  Directory: ${entity.path}');
          }
        }
      }
    }
  } catch (e) {
    print('Document Directory: Error listing contents: $e');
  }
  print('=== End Document Directory Contents ===\n\n');
}

Future<String> getOptimalGeohashPrefix(userGeohash) async{  
  final firestore = FirebaseFirestore.instance;  // Firestore reference
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User must be signed in');

  // Find optimal geohash prefix
  int minProfilesPerHash = 105;
  int maxProfilesPerHash = 200;

  int basePrecision = 5; // Start with precision 5 (~4.9km × 4.9km)
  String? optimalPrefix;
  int profileCount = 0;

  bool lastHashProfilesInsufficient = false;
  bool nextHashProfilesExceedMax = false;
  String? prefixHolder;
  int? profileCountHolder;

  // Edge case 1: If there is a very dense urban area on one side of the user, the profiles in the inclusive hash may exceed 200, but the prefix one char deeper may be less than 105. 
  // In this case the optimalPrefix is returned as null, and the next best prefix that is less than and closest to 105 should be used.
  // Then start the ring algo to get profiles from more smaller hashes 

  // Test precisions from 4 to 7
  for (int precision = 4; precision <= 7; precision++) {
    String prefix = userGeohash.substring(0, precision);
    print('Testing prefix: $prefix (precision: $precision)');

    // Count profiles with this prefix
    Query<Map<String, dynamic>> countQuery = firestore
        .collection('user_ids')
        .where('uid', isNotEqualTo: user.uid)
        .orderBy('geohash')
        .startAt([prefix])
        .endAt([prefix + '\uf8ff']);

    // Use count() aggregation if available (Firebase Firestore SDK >= 9.0.0)
    // Otherwise, fetch documents and count manually
    try {
      // Note: count() requires Firestore v9+ and may incur costs
      // If not available, replace with manual counting
      AggregateQuerySnapshot countSnapshot = await countQuery.count().get();
      profileCount = countSnapshot.count!;  // Assuming the count is not null, return the count
      print('Found $profileCount profiles for prefix: $prefix');
    } catch (e) {
      // Manual counting fallback
      QuerySnapshot<Map<String, dynamic>> snapshot = await countQuery.get();
      profileCount = snapshot.docs.length;
      print('Found $profileCount profiles for prefix: $prefix (manual count)');
    }

    if (profileCount >= minProfilesPerHash && profileCount <= maxProfilesPerHash) {
      optimalPrefix = prefix;
      break;
    } else if (profileCount > maxProfilesPerHash && precision < 7) {
      // Too many profiles, try a longer (more precise) prefix
      if (lastHashProfilesInsufficient == true) {  // The precision one char deeper than this one was insufficient
        nextHashProfilesExceedMax == true;  // And this precision is too many which means the char one deeper should be returned as the optimal hash 
        optimalPrefix = prefixHolder;
        profileCount = profileCountHolder!;
        break;
      } 
      continue;
    } else if (profileCount < minProfilesPerHash && precision >= 2) {
      // Too few profiles, try a shorter (less precise) prefix
      lastHashProfilesInsufficient = true;  
      prefixHolder = prefix;
      profileCountHolder = profileCount;
      precision = precision - 2; // Step back to try a shorter prefix
      print('Too few profiles, try a shorter (less precise) prefix $prefixHolder');
      continue;
    }
  }

  if (optimalPrefix == null) {
    print('No prefix found with profile count between $minProfilesPerHash and $maxProfilesPerHash');
    return "no hash found"; // Return empty list or handle as needed
  }

  print('Using optimal prefix: $optimalPrefix with $profileCount profiles');

  return optimalPrefix;
}

Future<List<Map<dynamic, dynamic>>> runQuery(query, userLat, userLon, allProfiles, nextDocId) async{  // Run query and cache profiles in firebase and client
  try{
      final querySnapshot = await query.get();
      final profiles = querySnapshot.docs;

      print('Got ${profiles.length} profiles from firestore');
      
      List<Map<dynamic, dynamic>> batchProfiles = [];
      String? lastDocIdReturned;

      for (var doc in profiles) {
        final data = doc.data();
        final lat2 = data['latitude'] as double? ?? 0.0;
        final lon2 = data['longitude'] as double? ?? 0.0;

        if (lat2 == 0.0 || lon2 == 0.0) continue;  // skips invalid profiles by setting null lat as 0 and skipping
        
        //print('$userLat, $userLon, $lat2, $lon2');

        double meters = Geolocator.distanceBetween(
          userLat, 
          userLon,   // your location
          lat2, 
          lon2          // other profile location
        ); // returns meters
        
        // convert to miles
        double distance = meters * 0.00062137;

        //print(distance);

        // Cache images locally
        final phoneNumber =
            data['uid']?.toString().replaceFirst('testUser', '') ?? 'Unknown';
        final imagePaths = (data['imagePaths'] as List<dynamic>?)
                ?.where((url) => url is String && url.isNotEmpty)
                .toList() ??
            [];

        List<String> cachedImagePaths = [];
        String? profilePic;

        // for (var imageUrl in imagePaths) {  // This caches all images in images list
        //   try {
        //     final cachedPath =
        //         await _cacheImage(imageUrl, phoneNumber, doc.id);
        //     if (cachedPath.isNotEmpty) {
        //       cachedImagePaths.add(cachedPath);
        //       if (imageUrl == imagePaths[0]) {
        //         profilePic = cachedPath;
        //       }
        //     }
        //   } catch (_) {}
        // }  // 10 miles 82 profiles 78 seconds 

        String profilePicPath = imagePaths[0];  // This only downloads and caches the profile pic. The other pictures can be downloaded and cached when the full profile is opened
        final cachedProfilePicPath = await _cacheImage(profilePicPath, phoneNumber, doc.id);
        if (cachedProfilePicPath.isNotEmpty) {
          cachedImagePaths.add(cachedProfilePicPath);
          profilePic = cachedProfilePicPath;
        }  // 10 miles 82 profiles 28 sec

        // This is good but now I need to load in all firestore image paths, get the download urls, and cache them to sqlite
        // Then when I opent the profiles I can download the images to the doc dir

        final profile = {
          'profilePic': profilePic,
          'images': cachedImagePaths,
          'name': phoneNumber,
          'age': 'N/A',
          'height': data['height'] ?? 'N/A',
          'location': 'Euless, TX',
          'distance': distance.toStringAsFixed(1),
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
        lastDocIdReturned = doc.id;
      }
    
      // Sort by distance
      // batchProfiles.sort((a, b) => double.parse(a['distance'].replaceAll(' mi', ''))
      //     .compareTo(double.parse(b['distance'].replaceAll(' km', ''))));

      await sqlite.DatabaseHelper.instance.cacheAllOtherUserProfiles(batchProfiles);
      allProfiles.addAll(batchProfiles);

      nextDocId = batchProfiles.length >= 100 ? lastDocIdReturned : null;
      //return allProfiles;
    } 
    
    catch(e) {
      print('You need to log in');
      return allProfiles;
    }
  return allProfiles;
}

Future<List<Map<dynamic, dynamic>>> fetchInitialEntries(String? nextDocId, optimalHash, userLat, userLon) async {
  List<Map<dynamic, dynamic>> allProfiles = [];
  print('fetching initial profiles... ');
  try {
    final firestore = FirebaseFirestore.instance;  // Firestore reference
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be signed in');
    
    int zs = 0;
    final stopwatch = Stopwatch()..start();

    Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 78 sec
      .collection('user_ids')
      .where('uid', isNotEqualTo: user.uid)  // Don't load in the users own profile
      .orderBy('geohash')
      .startAt([optimalHash])
      .endAt([optimalHash + '\uf8ff'])  /////////////////////////////////////////////////////////////////////
      .limit(105);

    // Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 88 sec
    //   .collection('user_ids')
    //   .where('uid', isNotEqualTo: user.uid)
    //   .where('geohash', isEqualTo: hash) // 6 char hashes must exactly match 
    //   .limit(105);

    // If paginating
    if (nextDocId != null) {
      final lastDoc =
          await firestore.collection('user_ids').doc(nextDocId).get();
      if (lastDoc.exists) query = query.startAfterDocument(lastDoc);
    }

    // Run query
    allProfiles = await runQuery(query, userLat, userLon, allProfiles, nextDocId);
    stopwatch.stop();
    print('Elapsed time: ${stopwatch.elapsedMilliseconds} ms');
    print('Empty hashes: $zs');
  }   
  catch (e) {
    print('Error fetching profiles: $e');
    return allProfiles;
  }
  //print('Profiles from firestore function: $allProfiles');
  return allProfiles;
}
  
Future<List<Map<dynamic, dynamic>>> fetchProfilesInRings(String? nextDocId, double radius, List<Map<dynamic, dynamic>> allProfiles, centerGeohash) async{  // get rings after finding first large hash
  // if (allProfiles.length > 105) {
  //   print('max page length reached');
  //   return allProfiles;
  // }
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User must be signed in');

  late List<Map<dynamic, dynamic>> additionalProfiles;
  
  // Get current location
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  final userLat = position.latitude;
  final userLon = position.longitude;

  print('Got user location: $userLat, $userLon');

  List geohashRings = await geohash_grid.collectGeohashesInRings(userLat, userLon, radius, centerGeohash);  // get rings 

  print(geohashRings);

  // Firestore reference
  final firestore = FirebaseFirestore.instance;
  
  int zs = 0;
  final stopwatch = Stopwatch()..start();

  for (List ring in geohashRings) {
    for (String hash in ring) {
      print(hash);

      Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 78 sec
        .collection('user_ids')
        .where('uid', isNotEqualTo: user.uid)  // Don't load in the users own profile
        .orderBy('geohash')
        .startAt([hash])
        .endAt([hash + '\uf8ff'])  /////////////////////////////////////////////////////////////////////
        .limit(105);

      // Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 88 sec
      //   .collection('user_ids')
      //   .where('uid', isNotEqualTo: user.uid)
      //   .where('geohash', isEqualTo: hash) // 6 char hashes must exactly match 
      //   .limit(105);

      // If paginating
      if (nextDocId != null) {
        final lastDoc =
            await firestore.collection('user_ids').doc(nextDocId).get();
        if (lastDoc.exists) query = query.startAfterDocument(lastDoc);
      }

      // Run query
      allProfiles = await runQuery(query, userLat, userLon, allProfiles, nextDocId); 

      stopwatch.stop();
      print('Elapsed time: ${stopwatch.elapsedMilliseconds} ms');
      print('Empty hashes: $zs');
    }
  }
  //print('Profiles from firestore function: $allProfiles');
  //allProfiles.addAll(additionalProfiles);
  return allProfiles;
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
