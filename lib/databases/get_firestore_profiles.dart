import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:integra_date/databases/geohash_grid.dart' as geohash_grid;

import 'package:integra_date/widgets/pagination_buttons.dart' as pagination_buttons;
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;
import 'package:integra_date/widgets/navigation_bar.dart' as navigation_bar;

String? optimalPrefix;

int max_profiles = 20;

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
  int maxProfilesPerHash = 210;

  int basePrecision = 5; // Start with precision 5 (~4.9km × 4.9km)
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
        .where('name', isNotEqualTo: user.uid)
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
      //////////(e);
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

  sqlite.DatabaseHelper.instance.setOptimalPrefix(optimalPrefix!);
  return optimalPrefix!;
}

Future<List<dynamic>> runQuery(query, userLat, userLon) async{  // Run query and cache profiles in firebase and client. Return number of profiles collected
  List profileCountAndLastDoc = [];
  late int profilesQueried;
  try{
    print('attempting query');
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

        ////////////(distance);

        // Cache images locally
        // final phoneNumber =
        //     data['name']?.toString().replaceFirst('testUser', '') ?? 'Unknown';
        final hashedId = data['hashedId'];
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
        
        for (String path in imagePaths) {
          await sqlite.DatabaseHelper.instance.cacheFireStoragePaths(hashedId, path);
        }

        final cachedProfilePicPath = await _cacheImage(profilePicPath, hashedId, doc.id);
        if (cachedProfilePicPath.isNotEmpty) {
          cachedImagePaths.add(cachedProfilePicPath);
          profilePic = cachedProfilePicPath;
        }  // 10 miles 82 profiles 28 sec

        // This is good but now I need to load in all firestore image paths, get the download urls, and cache them to sqlite
        // Then when I opent the profiles I can download the images to the doc dir

        final profile = {
          'profilePic': profilePic,
          'images': cachedImagePaths,
          'hashedId': data['hashedId'],
          'name': data['name'],
          'phone': data['phone'],
          'age': data['age'],
          'height': data['height'] ?? 'N/A',
          'location': 'Euless, TX',
          'geohash': data['geohash'],
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
        lastDocIdReturned = doc.id;  // This is the phone number btw 
      }
    
      // Sort by distance  
      // batchProfiles.sort((a, b) => double.parse(a['distance'].replaceAll(' mi', ''))  This is already done in a sqlite function 
      //     .compareTo(double.parse(b['distance'].replaceAll(' km', ''))));

      if (batchProfiles.isEmpty) {  // If there are no profiles in the hash, return 0 profiles queried and null for the last doc snapshot 
        profileCountAndLastDoc.addAll([0, null]);
      } else {  // Continue as usual
        await sqlite.DatabaseHelper.instance.cacheAllOtherUserProfiles(batchProfiles);

        print('First profile retrieved: ${batchProfiles[0]['phone']}');
        print('Last profile retrieved: ${batchProfiles.last['phone']}');
        
        print('${profiles.length} profiles have been cached');

        profilesQueried = profiles.length;

        if (profiles.length == null) {
          profilesQueried = 0;
        }
        
        final lastDocSnapshot = profiles.last;  // Last doc snapshot will be needed if the hash returned 105 profiles and still has some in it

        profileCountAndLastDoc.addAll([profilesQueried, lastDocSnapshot]);
      }
    } 
    catch(e) {
      print('You need to log in');
      //////////(e);
    }
    return profileCountAndLastDoc;
}

Future<void> fetchInitialEntries(String? nextDocId, optimalHash, userLat, userLon) async {
  List profileCountAndLastDoc = [];
  print('fetching initial profiles... ');
  try {
    final firestore = FirebaseFirestore.instance;  // Firestore reference
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be signed in');
    
    int zs = 0;
    final stopwatch = Stopwatch()..start();

    Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 78 sec
      .collection('user_ids')
      .where('name', isNotEqualTo: user.uid)  // Don't load in the users own profile
      .orderBy('geohash')
      .startAt([optimalHash])
      .endAt([optimalHash + '\uf8ff'])  /////////////////////////////////////////////////////////////////////
      .limit(210);  

    // Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 88 sec
    //   .collection('user_ids')
    //   .where('name', isNotEqualTo: user.uid)
    //   .where('geohash', isEqualTo: hash) // 6 char hashes must exactly match 
    //   .limit(105);

    // If paginating
    if (nextDocId != null) {
      final lastDoc =
          await firestore.collection('user_ids').doc(nextDocId).get();
      if (lastDoc.exists) query = query.startAfterDocument(lastDoc);
    }

    // Run query
    await runQuery(query, userLat, userLon);
    stopwatch.stop();
    print('Elapsed time: ${stopwatch.elapsedMilliseconds} ms');
    print('Empty hashes: $zs');
  }   
  catch (e) {
    print('Error fetching profiles: $e');
  }
  //print('Profiles from firestore function: $allProfiles');
}

List<List<String>> shortenGeohashRings(List<List<String>> geohashRings, String optimalPrefix, int shortenMethod) {
  List<List<String>> filteredRings = [];
  
  if (shortenMethod == 1) {
    // Filter out rings where all hashes start with optimalPrefix
    filteredRings = geohashRings.where((ring) {
      // Return true (keep the ring) if at least one hash does NOT start with optimalPrefix
      return ring.any((hash) => !hash.startsWith(optimalPrefix));
    }).toList();
  } 

  if (shortenMethod == 2) {
    final firstMatchIndex = geohashRings.indexWhere((ring) => ring.any((hash) => hash == optimalPrefix));
    filteredRings = firstMatchIndex != -1 ? geohashRings.sublist(firstMatchIndex + 2) : [];  /////////////////////////// CHECK + 2 is correct and accounts for the central ring and the central hash not being in ring list
  }

  if (shortenMethod == 3 || shortenMethod == 4) {
    final firstMatchIndex = geohashRings.indexWhere((ring) => ring.any((hash) => hash == optimalPrefix.substring(0, 5)));
    if (firstMatchIndex != -1) {
      // Get the ring containing the matching 5-character prefix
      final targetRing = geohashRings[firstMatchIndex];
      // Find the index of the matching 5-character prefix
      final hashIndex = targetRing.indexWhere((hash) => hash == optimalPrefix.substring(0, 5));
      // Keep hashes after the matching prefix in the target ring
      List<String> remainingHashes = []; 
      shortenMethod == 3
        ? remainingHashes = targetRing.sublist(hashIndex)
        : remainingHashes = targetRing.sublist(hashIndex + 1);
      // Combine remaining hashes from the target ring with all subsequent rings
      filteredRings = [
          if (remainingHashes.isNotEmpty) remainingHashes,
          ...geohashRings.sublist(firstMatchIndex + 1),
        ];
      
      // print('optimalPrefix: $optimalPrefix');
      // print('Matching 5-char prefix: ${optimalPrefix.substring(0, 5)}');
      // print('firstMatchIndex: $firstMatchIndex');
      // print('targetRing: $targetRing');
      // print('remainingHashes: $remainingHashes');
      // print('filteredRings: $filteredRings');
    }
  }

  // Log for debugging
  // if (filteredRings.length == geohashRings.length) {
  //   print('No rings removed; all rings have at least one hash not matching prefix: $optimalPrefix');
  // } else {
  //   print('Removed ${geohashRings.length - filteredRings.length} rings where all hashes matched prefix: $optimalPrefix');
  // }

  return filteredRings;
}

Future<Map<dynamic, dynamic>> requeryHash(firestore, hash, lastDocSnapshot, userLat, userLon, profilesQueried) async{
  bool requerying = true;
  bool depleted = false;
  //int profilesQueried = 0;

  print('This is a requery of hash $hash!');

  // If this is the second pagination requery, the lastDocSnapshot was saved to sqlite as a Map, but firebase will need the snapshot datatype 
  if (lastDocSnapshot is Map<String, dynamic>) {
    print('This is the intial pagination requery. Starting profile: ${lastDocSnapshot['phone']}');
    // The lastDocSnapshot is a Map, and .startAfterDocument needs a firebase type, so retrieve the actual snapshot based on the doc id (phone number)
    try {
      lastDocSnapshot = await firestore.collection('user_ids').doc(lastDocSnapshot['phone']).get();
      print('Fetched DocumentSnapshot for docId: ${lastDocSnapshot['phone']}');
    } catch (e) {
      print('Error fetching DocumentSnapshot (${lastDocSnapshot['phone']}): $e');
      lastDocSnapshot = null;
    }
  } else {
    var data = lastDocSnapshot.data();
    print('This is a requery of a new hash query.');
  }

  while (requerying) {  // This repeates the requery as long as the last query continues to return 105 profiles
    Query<Map<String, dynamic>> requeryHash = firestore  // 10 miles 82 profiles 78 sec
      .collection('user_ids')
      //.where('name', isNotEqualTo: user.uid) Wow don't include this it breaks startAfterDocument. Also, it is already filtered out client side in the runQuery function
      .orderBy('geohash')
      .startAfterDocument(lastDocSnapshot)  // CHECK does this cost extra
      .endAt([hash + '\uf8ff'])  
      .limit(max_profiles);  

    // Run query
    var profileCountAndLastDoc = await runQuery(requeryHash, userLat, userLon);  // The query returns the number of profiles it just cached
    int lastCount = profileCountAndLastDoc[0];    
    var lastLastDoc = lastDocSnapshot;  // Set the holder before updating 
    lastDocSnapshot = profileCountAndLastDoc[1];
    if (lastDocSnapshot == null) {  // This avoids setting the doc as null if 0 profiles are returned on a requery
      lastDocSnapshot = lastLastDoc;  // Pass the holder oif the update is null
    }

    profilesQueried += lastCount;

    if (lastCount < max_profiles) {  // exit the requery loop if the last query depeletes the current hash
      print('$hash has been depleted. Breaking requery loop.');
      requerying = false;
      depleted = true;
      break;
    }

    // The last profile is not saved to sqlite here. Instead, wait untill the hash loop limit check in fetchProfilesInRings()
    if (profilesQueried >= 210) {  // Be sure to exit the requery while loop if the query profile limit is reached
      print('Requery while loop found $lastCount profiles and the total count has reached $profilesQueried');
      print('Breaking loop and saving last profile to sqlite');
      break;
    }
  }

  Map<dynamic, dynamic> requeryData = {'profilesQueried': profilesQueried, 'lastDocSnapshot': lastDocSnapshot, 'depleted': depleted};
  return requeryData;
}

Future<void> fetchProfilesInRings(int radius, centerGeohash) async{  // get rings after finding first large hash
  // This code turns off certain troublesome sections whenever there is a query in progress. 
  // All of these occur in two other places below for this to work properly. 
  // There is also a condition to allow pagination during the query if within the cached profile pages. 
  pagination_buttons.toggleRings(true);
  filters_menu.toggleRings(true);
  navigation_bar.toggleRings(true);

  // int lastCachePageCount = (totalProfileCount % 105);  // Modulus returns the remainder. Then multiplying by 105 yields the numerator of the remainder of total / page_max. ie. the number of profiles on the last page 
  // print('last: $lastCachePageCount');

  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User must be signed in');
  
  final stopwatch = Stopwatch()..start();  // Time the whole query process
  int profilesQueried = 0;
  Map requeryData = {'profilesQueried': 0, 'lastDocSnapshot': null, 'depleted': false};  // CHECK shouldn't need the lastDocSnapshot bc the requery loop already saves the last profile every iteration 
  
  bool lastHashDepleted = false;  // Set to false to lock continue until after pagination query depletes first hash. Set to true to continue with next hash after pagination query depletes the first hash
  bool dontRequeryOldHash = false;  // Set to false to allow pagination query. Set to true after first for loop iteration to lock inital requery
  bool? requeryBool = await sqlite.DatabaseHelper.instance.getRequeryBool();  // Check sqlite settings for requery bool
  if (requeryBool == null) {
    requeryBool = false;
  }

  print('RequeryBool: $requeryBool');

  // Get current location
  
  // This resets the location every time. To make sure it doesn't generate hash lists that are offset from the initial query, the users central location (the location of account creation) should be used. 
  // Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high);
  // final userLat = position.latitude;
  // final userLon = position.longitude;
  // print('Got user location: $userLat, $userLon');

  Map<String, dynamic>? position = await sqlite.DatabaseHelper.instance.getUserLocation('central_location');  // This may break if the permissions are not granted and the app tries to run the first time. Pretty sure I already fixed it though.
  final userLat = position!['latitude'];
  final userLon = position['longitude'];
  print('Got user location: $userLat, $userLon');

  // Generate ring list
  // First cache trigger hashes
  Map<int, String> collectedTriggerHashes = await sqlite.DatabaseHelper.instance.getTriggerHashes();
  List radiusArgs = [5, 10, 25, 50, 75, 100, 125, 150, 175, 200];
  for (int radiusArg in radiusArgs.sublist(0, radiusArgs.indexOf(radius))) {  // This gets everything to the current radius arg non-inclusive
    if (!collectedTriggerHashes.containsKey(radiusArg)) {
      List<List<String>> ringsForTriggerHashes = await geohash_grid.collectGeohashesInRings(userLat, userLon, radius, centerGeohash);  // get rings 
      sqlite.DatabaseHelper.instance.cacheTriggerHash(radius, ringsForTriggerHashes.last.last);  // Add the last hash of the last ring to the map for the given radius. Now, no matter what, if the last radius is hit, the ring algo caches the correct completed radius
    }
  }

  List<List<String>> geohashRings = await geohash_grid.collectGeohashesInRings(userLat, userLon, radius, centerGeohash);  // get rings 
  //print('full ring list $geohashRings in $radius mile radius');
  sqlite.DatabaseHelper.instance.cacheTriggerHash(radius, geohashRings.last.last);  // Add the last hash of the last ring to the map for the given radius. Now, no matter what, if the last radius is hit, the ring algo caches the correct completed radius
  print('Cached trigger hash: ${geohashRings.last.last} for $radius mile radius');

  // There are three different ways the list can be shortened
  //
  // 1. This is the first query and the list should have the large initially queried prefix removed
  //
  // 2. This is a query for a new radius and the radii list is not empty
  //     - The entire radius should be removed from the new ring list, becuase it includes the old radius due to how the ring generator works
  //
  // 3. The last query hit the query limit and this new query was triggered by pagination
  //     - In this case, remove every ring and hash before the target hash, including the target hash
  //     - be sure to keep the hashes in the same ring as the target hash that occur after the target hash  
  
  // If this is a pagination requery, the last profile was saved and should be retrieved from sqlite
  Map<String, dynamic>? lastProfileSnapshot = await sqlite.DatabaseHelper.instance.getLastFirebaseProfile();
  // if (lastProfileSnapshot != null) {  // There is a 'last profile' saved every time the query function is run. The resume query only needs to happen if 
  //   print('not null: ${lastProfileSnapshot['phone']}');
  //   // This is only accessed after the query limit of 210 is met. Then upon requery the list of hashes should be shortened, the first query should start at the last profile, and the next hashes should be iterated
  // } else {
  //   print('null');
  // }

  // If this is a new radius query, the largest old radius should be retrieved from sqlite to be removed from the generated ring list  
  List<int> radii = await sqlite.DatabaseHelper.instance.getCachedRadii();  // the rings need to be shortened up to the ring containing the target hash of the last radius 

  // Shorten methods bellow
  late List<List<String>> shortenedRings;
  String radiusPrefix = '';
  if (radii.isEmpty && lastProfileSnapshot == null) {  // If so this is the first query and the optimal prefix contianing the first batch of profiles should be removed
    print('No radii found, this must be the inital ring algo');
    if (optimalPrefix == null) {
      optimalPrefix = await sqlite.DatabaseHelper.instance.getOptimalPrefix();
    }
    shortenedRings = shortenGeohashRings(geohashRings, optimalPrefix!, 1);  // This is good for the initial prefix, but on subsequent queries the rings need to be shortened up to the ring containing the target hash of the last radius   
  } else if (radii.isNotEmpty) {  // Otherwise the preffix should be recaculated for the last radius collected 
    radiusPrefix = await geohash_grid.getTargetGeohash(userLat, userLon, radii.reduce(math.max));
    shortenedRings = shortenGeohashRings(geohashRings, radiusPrefix, 2);
  } else if (lastProfileSnapshot != null) {
    String lastProfilePrefix = lastProfileSnapshot['geohash'];
    print('Unshortened hash of last profile: $lastProfilePrefix');
    shortenedRings = shortenGeohashRings(geohashRings, lastProfilePrefix, 3);

    if (requeryBool != null && !requeryBool) {
      print('\n\n');
      print('The hash that was depleted last time should be removed upon this pagination query!');
      String lastProfilePrefix = lastProfileSnapshot['geohash'].substring(0, 5);
      shortenedRings = shortenGeohashRings(geohashRings, lastProfilePrefix, 4);
      print('Hash removed: $lastProfilePrefix');
    }

    print('\n\n');
    //////////(shortenedRings);
    print('\n\n');
  }
  
  //print('User hash $centerGeohash');
  //print('User ID ${user.uid}');
  //print('Optimal prefix $optimalPrefix');
  //print('New prefix $newPrefix');
  //print('Shortened rings list $shortenedRings');

  if (shortenedRings.isEmpty) {  // Check if the optimal prefix contains all rings in radius
    sqlite.DatabaseHelper.instance.cacheCollectedRadiusArg(radius);  // If the shortener depletes the radius, cache it.
    print('The shortener depleted the entire radius! Cached trigger hash: ${geohashRings.last.last} for $radius mile radius');
    pagination_buttons.toggleRings(false);
    filters_menu.toggleRings(false);
    navigation_bar.toggleRings(false);
    return;
  }

  Map<int, String> triggerHashes = await sqlite.DatabaseHelper.instance.getTriggerHashes(); 
  print('Trigger hashes: $triggerHashes');

  for (List ring in shortenedRings) {
    for (String hash in ring) {

      for (int key in triggerHashes.keys) { // Cache the radius if trigger hash hit
        String triggerHash = triggerHashes[key]!;
        if (triggerHash == hash) {
          sqlite.DatabaseHelper.instance.cacheCollectedRadiusArg(key);
        } 
      }

      if (radii.isEmpty && optimalPrefix != null) {
        if (hash.contains(optimalPrefix!)) {  // This should take care of duplicates in the intial ring
          print('Hash contains optimal prefix $hash');
          continue;
        }
      } else if (radiusPrefix != ''){
        if (hash.contains(radiusPrefix)) {  // This should take care of duplicates in all rings after the intial ring
          print('Hash contains optimal prefix $hash');
          continue;
        }
      }

      // If this is a pagination requery, the correct hash is started in the for loop, but only the remaining profiles should be queried. Run the requery while loop until it depletes the current hash
      if (lastProfileSnapshot != null && !dontRequeryOldHash && requeryBool! ) {  // Don't requery if the last requery depleted the hash
        requeryData = await requeryHash(firestore, hash, lastProfileSnapshot, userLat, userLon, profilesQueried);
        profilesQueried += requeryData['profilesQueried'] as int;
        print('count after intial pagination requery: $profilesQueried');
        lastHashDepleted = requeryData['depleted'];
      }

      if (profilesQueried >= 210) {  // The while loop breaks if the limit is reached, so if that is the case break the inner for loop as well 
        //sqlite.DatabaseHelper.instance.saveLastFirebaseProfile(requeryData['lastDocSnapshot']); this is not needed bc it is saved in the requery loop  // Save the last profile snapshot locally only if the query limit is reached. It should be reset after the radius is fully depleted
        break;  
      } 

      // After the hash has been depleted the next hash should be started
      if (lastHashDepleted) {
        lastHashDepleted = false;  // Avoid continueing over and over agian, but use the bool bellow to lock the initial requery 
        dontRequeryOldHash = true;  // The old hash was depleted, so keep the requery from activating when the inner for loop restarts after the continue
        requeryBool = false;  
        print('Last hash depleted, iterating to next hash');
        continue;
      }

      // dontRequeryOldHash = false;  do not reset so that next time the for loop restarts, it continues to the next hash
      // This is only reset each time the ring algo is restarted
      
      print('\n\n');
      print('\n\n');
      print('Next hash queried: $hash');

      Query<Map<String, dynamic>> query = firestore  // 10 miles 82 profiles 78 sec
        .collection('user_ids')
        //.where('name', isNotEqualTo: user.uid)  // Don't load in the users own profile
        .orderBy('geohash')
        .startAt([hash])
        .endAt([hash + '\uf8ff'])  /////////////////////////////////////////////////////////////////////
        .limit(max_profiles);  // CHECK edge case of > 105: pick back up        

      // Run query
      var profileCountAndLastDoc = await runQuery(query, userLat, userLon);  // The query returns the number of profiles it just cached
      late int lastCount;
      late var lastDocSnapshot;

      if (profileCountAndLastDoc[1] == null) {  // If there are no profiles in the queried hash, no need to go through the profile count checks. Just continue to the next hash
        // Some of the time, the last hash will be empty on the first query, in that case this works.
        // Otherwise, if the last hash is requeried until it is depleted, this code needs to be repeated after the last requery
        if (ring == shortenedRings.last && hash == ring.last) {  // Check if the radius has been fully searched when the last ring index has finished querying all hashes 
          print('The last hash in the radius was empty!');
          print('Ring algo stopped as there are no more hashes in within $radius miles. Collected and cached $profilesQueried new profiles.');
          print('Cached radii: ${sqlite.DatabaseHelper.instance.getCachedRadii()}');
          sqlite.DatabaseHelper.instance.cacheCollectedRadiusArg(radius);  // Add the radius just FULLY cached to the radiusArgsCached list so that the grid isnt checked again  
        }

        continue;
      } else {  // Otherwise it is ok to continue without returning null values fo the late vars lastCount and lastDocSnapshot
        lastCount = profileCountAndLastDoc[0];
        lastDocSnapshot = profileCountAndLastDoc[1];
        profilesQueried += lastCount;
      }

      print('count after new hash query: $profilesQueried');
      print('\n\n');
      var data = lastDocSnapshot.data();
      if (profilesQueried >= 210) {  // The for ring for hash loops should break if there are 210 profiles ready for the user to scroll through. It won't start again until the page is incremented 
        sqlite.DatabaseHelper.instance.saveLastFirebaseProfile(lastDocSnapshot.data());  // Save the last profile snapshot locally only if the query limit is reached. It should be reset after the radius is fully depleted
        print('\n\n');
        print('Limit reached after new hash query. Last queried hash: ${data['phone']}');
        if (lastCount < max_profiles) {
          // the next time the queries are started the hash that got depleted last time should be removed, and the requery function should not run.
          requeryBool = false;
          await sqlite.DatabaseHelper.instance.saveRequeryBool(requeryBool);
        } 
        if (lastCount == max_profiles) {
          requeryBool = true;
          await sqlite.DatabaseHelper.instance.saveRequeryBool(requeryBool);  // Save requeryBool as true if the hash is not depleted 
        }
        break;  
      }
      
      // If the last query did not reach the limit, and it was = 105, requery the current hash
      if (lastCount == max_profiles) {
        requeryData = await requeryHash(firestore, hash, lastDocSnapshot, userLat, userLon, profilesQueried);  // THIS IS A WHILE LOOP THAT BREAKS
        profilesQueried += requeryData['profilesQueried'] as int;

        print('count after requery: $profilesQueried');
      }

      // This needs to break the for loop after the requery while loop is broken, otherwise it restarts the hash for loop at the next hash
      if (profilesQueried >= 210) {  // The for ring for hash loops should break if there are 210 profiles ready for the user to scroll through. It won't start again until the page is incremented 
        // This is not called in the requery loop, so save it here. That way, if the requery depletes the hash AND hits the limit, OR if the requery only reaches the limit without depleteing, the last doc is saved 
        sqlite.DatabaseHelper.instance.saveLastFirebaseProfile(requeryData['lastDocSnapshot'].data()); 
        print('\n\n');
        print('Limit reached after hash requery.');
        if (requeryData['profilesQueried'] < max_profiles) {
          // the next time the queries are started the hash that got depleted last time should be removed, and the requery function should not run.
          requeryBool = false;
          await sqlite.DatabaseHelper.instance.saveRequeryBool(requeryBool);
        } 
        if (requeryData['profilesQueried'] == max_profiles) {
          requeryBool = true;
          await sqlite.DatabaseHelper.instance.saveRequeryBool(requeryBool);  // Save requeryBool as true if the hash is not depleted 
        }
        break;  
      }
  
      // This is only here for the case that the last hash in the radius is a requery. Check if the radius has been fully searched when the last ring for loop has finished querying all hashes. 
      if (ring == shortenedRings.last && hash == ring.last) {  
        print('The last hash in the radius was either depleted after one query or it was a requery!');
        print('Ring algo stopped as there are no more hashes in within $radius miles. Collected and cached $profilesQueried new profiles.');
        print('Cached radii: ${sqlite.DatabaseHelper.instance.getCachedRadii()}');
        sqlite.DatabaseHelper.instance.cacheCollectedRadiusArg(radius);  // Add the radius just FULLY cached to the radiusArgsCached list so that the grid isnt checked again  
      }

      // // This is to load in full pages as they are discovered for users with very low nearby profile density
      // if (lastCachePageCount + profilesQueried >= 105) {  // All that must be done is a refresh of the total pages, as the cache is updated after each query! :)
      //   print('Total: ${lastCachePageCount + profilesQueried}');
      //   int totalProfileCount_2 = await sqlite.DatabaseHelper.instance.getAllOtherUserProfilesCount();
      //   int totalPages_2 = (totalProfileCount_2 / 105).floor();
      //   pagination_buttons.getTotalPages(totalPages_2);  // Pass total pages to paginator to allow next page clicks within cache during query

      //   // Update the lastPageCount
      //   lastCachePageCount = (totalProfileCount_2 % 105);
      // }
    }  // for hash in ring   

    // Break out of the ring for loop as well
    if (profilesQueried >= 210) {  // If the requery data is keeping track of the count and not the profiles queried, it should be checked with an OR. CHECK change this to be only the one var later
      print('Ring algo stopped as there are $profilesQueried new profiles cached');
      break;
    }
  }  // for ring in rings

  stopwatch.stop();
  print('Elapsed time: ${stopwatch.elapsedMilliseconds} ms');
  print('\n\n');
  print('\n\n');
  print('\n\n');
  print('\n\n');
  print('\n\n');
  print('\n\n');

  pagination_buttons.toggleRings(false);
  filters_menu.toggleRings(false);
  navigation_bar.toggleRings(false);
}

Future<String> _cacheImage(String storagePath, String hashedId, String docId) async {
  try {
    // Resolve path into URL (emulator or prod)
    final ref = firebase_storage.FirebaseStorage.instance.ref().child(storagePath);
    final url = await ref.getDownloadURL();

    final uri = Uri.parse(url);
    final fileName = uri.pathSegments.last;

    final docDir = await getApplicationDocumentsDirectory();
    final filePath = '${docDir.path}/profile_images/$hashedId/$fileName';
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
