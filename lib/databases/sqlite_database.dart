import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
        CREATE TABLE location_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          metadata TEXT
        )
      ''');
    await db.execute('''
      CREATE TABLE profile_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metadata TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE other_user_profiles (
        name TEXT PRIMARY KEY,
        profile_data TEXT,
        created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE filters (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id TEXT,
        image_url TEXT,
        file_path TEXT,
        UNIQUE(profile_id, image_url)
      )
    ''');
    await _initializeFilters(db);
    print('DatabaseHelper: Database created');
  }

  Future<void> _initializeFilters(Database db) async {
    await db.insert('filters', {'key': 'distance', 'value': '5 mi'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'ageMin', 'value': '18'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'ageMax', 'value': '50 +'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'heightMin', 'value': "3' 0\""}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'heightMax', 'value': "7' 11\""}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'children', 'value': jsonEncode([])}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'relationshipIntent', 'value': jsonEncode([])}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'personalityTypes', 'value': jsonEncode([])}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'tags', 'value': jsonEncode([])}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'listSelection', 'value': ''}, conflictAlgorithm: ConflictAlgorithm.ignore);
    //print('DatabaseHelper: Initialized default filter values');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE cached_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profile_id TEXT,
          image_url TEXT,
          file_path TEXT,
          UNIQUE(profile_id, image_url)
        )
      ''');
      //print('DatabaseHelper: Upgraded database to version $newVersion');
    }
    await _initializeFilters(db);
  }



  ////////// SETTINGS TABLE //////////

  Future<void> setHasLocation(bool value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': 'hasLocation', 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('DatabaseHelper: Error saving hasLocation: $e');
    }
  }

  Future<bool> getHasLocation() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['hasLocation'],
      );
      return result.isNotEmpty && result.first['value'] == 'true';
    } catch (e) {
      print('DatabaseHelper: Error reading hasLocation: $e');
      return false;
    }
  }

  Future<void> saveLastFirebaseProfile(Map<String, dynamic> lastProfile) async{  // Used to restart the ring algo from the correct profile
    try {
      final db = await database;
      final jsonStringLastProfile = jsonEncode(lastProfile); // Convert map to JSON string
      await db.insert(
        'settings',
        {'key': 'lastProfile', 'value': jsonStringLastProfile},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('DatabaseHelper: Error saving lastProfile: $e');
    }
  }

  Future<Map<String, dynamic>?> getLastFirebaseProfile() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['lastProfile'],
      );
      if (result.isNotEmpty) {
        final value = result.first['value'] as String?;
        if (value != null && value.isNotEmpty) {
          try {
            final decoded = jsonDecode(value) as Map<String, dynamic>;
            return decoded;
          } catch (e) {
            print('Error decoding JSON: $e');
            return null;
          }
        }
        print('Value is null or empty');
        return null;
      }
      print('No results found for lastProfile');
      return null;
    } catch (e) {
      print('DatabaseHelper: Error reading lastProfile: $e');
      return null;
    }
  }

  Future<void> saveRequeryBool(bool requeryBool) async{
     try {
      final db = await database;
      final jsonString = jsonEncode(requeryBool); // Convert map to JSON string
      await db.insert(
        'settings',
        {'key': 'requeryBool', 'value': jsonString},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('DatabaseHelper: Saved last profile snapshot: $jsonString');
    } catch (e) {
      print('DatabaseHelper: Error saving lastProfile: $e');
    }
  }

  Future<bool?> getRequeryBool() async{
     try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['requeryBool'],
      );
      if (result.isNotEmpty) {
        final value = result.first['value'] as String?;
        if (value != null && value.isNotEmpty) {
          try {
            final decoded = jsonDecode(value) as bool;
            return decoded;
          } catch (e) {
            print('Error decoding JSON: $e');
            return null;
          }
        }
        print('Value is null or empty');
        return null;
      }
      print('No results found for lastProfile');
      return null;
    } catch (e) {
      print('DatabaseHelper: Error reading lastProfile: $e');
      return null;
    }
  }

  // Save a radius value to a list of radii in the database
  Future<void> cacheCollectedRadiusArg(int value) async {
    try {
      final db = await database;

      // Retrieve the existing list of radii
      final List<Map<String, dynamic>> existingData = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['cachedRadiusArgs'],
      );

      // Decode the existing list or create a new one
      List<int> radii = [];
      if (existingData.isNotEmpty) {
        final String? storedValue = existingData.first['value'] as String?;
        if (storedValue != null && storedValue.isNotEmpty) {
          radii = List<int>.from(jsonDecode(storedValue));
        }
      }

      // Add the new radius if it's not already in the list
      if (!radii.contains(value)) {
        radii.add(value);
      }

      // Save the updated list back to the database
      await db.insert(
        'settings',
        {'key': 'cachedRadiusArgs', 'value': jsonEncode(radii)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // print('DatabaseHelper: Cached radius $value. Updated list: $radii');
    } catch (e) {
      // print('DatabaseHelper: Error saving radius: $e');
    }
  }

  // Read the list of cached radii from the database
  Future<List<int>> getCachedRadii() async{
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['cachedRadiusArgs'],
      );

      if (result.isNotEmpty) {
        final String? storedValue = result.first['value'] as String?;
        if (storedValue != null && storedValue.isNotEmpty) {
          try {
            return List<int>.from(jsonDecode(storedValue).map((e) => e as int));
          } catch (e) {
            // Handle JSON decode or type cast error
            return [];
          }
        }
      }
      return [];
    } catch (e) {
      // print('DatabaseHelper: Error reading cached radii: $e');
      return [];
    }
  }

  Future<void> cacheTriggerHash(int radius, String hash) async {  // Cache the last hash in the last ring for the geohash list of lists at a given radius
    try {
      final db = await database;

      // Read existing triggerHashes
      final List<Map<String, dynamic>> result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['triggerHashes'],
      );

      // Initialize map for radius-hash pairs
      Map<int, String> triggerHashes = {};

      // If there's an existing entry, decode it
      if (result.isNotEmpty) {
        final String? storedValue = result.first['value'] as String?;
        if (storedValue != null && storedValue.isNotEmpty) {
          try {
            final decoded = jsonDecode(storedValue);
            if (decoded is Map) {
              triggerHashes = Map<int, String>.from(
                decoded.map((key, value) => MapEntry(int.parse(key.toString()), value.toString())),
              );
            } else {
              print('DatabaseHelper: Stored triggerHashes is not a map: $decoded');
            }
          } catch (e) {
            print('DatabaseHelper: Error decoding triggerHashes: $e');
          }
        }
      }

      // Add the new radius-hash pair
      triggerHashes[radius] = hash;

      // Store the updated map as JSON
      await db.insert(
        'settings',
        {
          'key': 'triggerHashes',
          'value': jsonEncode(triggerHashes),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('DatabaseHelper: Error caching radius-hash pair: $e');
    }
  }

  Future<Map<int, String>> getTriggerHashes() async {  // Get full map of radius-hash pairs
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['triggerHashes'],
      );

      if (result.isNotEmpty) {
        final String? storedValue = result.first['value'] as String?;
        if (storedValue != null && storedValue.isNotEmpty) {
          try {
            final decoded = jsonDecode(storedValue);
            if (decoded is Map) {
              return Map<int, String>.from(
                decoded.map((key, value) => MapEntry(int.parse(key.toString()), value.toString())),
              );
            } else {
              print('DatabaseHelper: Decoded triggerHashes is not a map: $decoded');
            }
          } catch (e) {
            print('DatabaseHelper: Error decoding triggerHashes: $e');
          }
        }
      }
      return {}; // Return empty map if no valid data
    } catch (e) {
      print('DatabaseHelper: Error reading trigger hashes: $e');
      return {};
    }
  }

  Future<void> setUserDocTitle(String value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': 'userDocTitle', 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('DatabaseHelper: Error saving userDocTitle: $e');
    }
  }

  Future<String> getUserDocTitle() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['userDocTitle'],
      );
      return result.first['value'].toString();
    } catch (e) {
      print('DatabaseHelper: Error reading userDocTitle: $e');
      return '';
    }
  }



  ////////// METADATA TABLE & FITLERS TABLE //////////

  Future<List<String>?> getCachedLatLon() async {
    try {
      final db = await database;
      final result = await db.query(
        'profile_metadata',
        limit: 1, // Single row for the current user
      );

      if (result.isEmpty) {
        print('DatabaseHelper: No location data found in profile_metadata');
        return null;
      }

      final row = result.first;
      final metadataJson = row['metadata'] as String?;

      if (metadataJson == null) {
        print('DatabaseHelper: No metadata found');
        return null;
      }

      // Decode JSON metadata
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      final latitude = metadata['latitude']?.toString();
      final longitude = metadata['longitude']?.toString();
      final geohash = metadata['geohash']?.toString();

      if (latitude != null && longitude != null && geohash != null) {
        print('DatabaseHelper: Retrieved cached location ($latitude, $longitude, $geohash)');
        return [latitude, longitude, geohash];
      } else {
        print('DatabaseHelper: Incomplete location data');
        return null;
      }
    } catch (e) {
      print('DatabaseHelper: Error reading user location: $e');
      return null;
    }
  }

  Future<String?> getFilterValue(String key) async {
    try {
      final db = await database;
      final result = await db.query(
        'filters',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) {
        final value = result.first['value'];
        if (value is String) {
          //print('DatabaseHelper: getFilterValue for $key returned $value');
          return value;
        } else {
          //print('DatabaseHelper: Unexpected type for filter $key: ${value.runtimeType}');
          return null;
        }
      }
      //print('DatabaseHelper: No filter value found for $key');
      return null;
    } catch (e) {
      //print('DatabaseHelper: Error reading filter $key: $e');
      return null;
    }
  }

  Future<void> setFilterValue(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'filters',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('DatabaseHelper: Set filter $key to $value');
    } catch (e) {
      //print('DatabaseHelper: Error saving filter $key: $e');
    }
  }

  Future<void> cacheUserMetadata(String key, Map<String, dynamic> data) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        final result = await txn.query('profile_metadata', limit: 1);
        Map<String, dynamic> existingMetadata = {};

        if (result.isNotEmpty) {
          existingMetadata = jsonDecode(result.first['metadata'] as String? ?? '{}') as Map<String, dynamic>;
          existingMetadata[key] = data;
          await txn.update(
            'profile_metadata',
            {'metadata': jsonEncode(existingMetadata)},
            where: 'id = ?',
            whereArgs: [result.first['id']],
          );
          print('DatabaseHelper: Updated metadata for key $key: $existingMetadata');
        } else {
          existingMetadata[key] = data;
          await txn.insert(
            'profile_metadata',
            {'metadata': jsonEncode(existingMetadata)},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('DatabaseHelper: Inserted new metadata for key $key: $existingMetadata');
        }

        final rowCount = await txn.rawQuery('SELECT COUNT(*) as count FROM profile_metadata');
        final count = Sqflite.firstIntValue(rowCount) ?? 0;
        if (count > 1) {
          await txn.delete(
            'profile_metadata',
            where: 'id NOT IN (SELECT id FROM profile_metadata LIMIT 1)',
          );
          print('DatabaseHelper: Cleaned up extra profile_metadata rows, kept one row');
        }
      });
    } catch (e) {
      print('DatabaseHelper: Error caching metadata for key $key: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserMetadata([String? key]) async {
    try {
      final db = await database;
      final result = await db.query('profile_metadata', limit: 1);
      
      if (result.isEmpty) {
        print('DatabaseHelper: No metadata found');
        return null;
      }

      final metadata = jsonDecode(result.first['metadata'] as String? ?? '{}') as Map<String, dynamic>;
      
      if (key == null) {
        print('DatabaseHelper: Retrieved full metadata: $metadata');
        return metadata;
      } else {
        final value = metadata[key];
        print('DatabaseHelper: Retrieved metadata for key $key: $value');
        return value as Map<String, dynamic>?;
      }
    } catch (e) {
      print('DatabaseHelper: Error reading metadata for key $key: $e');
      return null;
    }
  }

  Future<void> cacheUserLocation(String key, Map<String, dynamic> data) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        final result = await txn.query('location_data', limit: 1);
        Map<String, dynamic> existingMetadata = {};

        if (result.isNotEmpty) {
          existingMetadata = jsonDecode(result.first['metadata'] as String? ?? '{}') as Map<String, dynamic>;
          existingMetadata[key] = data;
          await txn.update(
            'location_data',
            {'metadata': jsonEncode(existingMetadata)},
            where: 'id = ?',
            whereArgs: [result.first['id']],
          );
          print('DatabaseHelper: Updated location data for key $key: $existingMetadata');
        } else {
          existingMetadata[key] = data;
          await txn.insert(
            'location_data',
            {'metadata': jsonEncode(existingMetadata)},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('DatabaseHelper: Inserted new location data for key $key: $existingMetadata');
        }

        final rowCount = await txn.rawQuery('SELECT COUNT(*) as count FROM location_data');
        final count = Sqflite.firstIntValue(rowCount) ?? 0;
        if (count > 1) {
          await txn.delete(
            'location_data',
            where: 'id NOT IN (SELECT id FROM location_data LIMIT 1)',
          );
          print('DatabaseHelper: Cleaned up extra location_data rows, kept one row');
        }
      });
    } catch (e) {
      print('DatabaseHelper: Error caching location data for key $key: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserLocation([String? key]) async {
    try {
      final db = await database;
      final result = await db.query('location_data', limit: 1);
      
      if (result.isEmpty) {
        print('DatabaseHelper: No location data found');
        return null;
      }

      final metadata = jsonDecode(result.first['metadata'] as String? ?? '{}') as Map<String, dynamic>;
      
      if (key == null) {
        print('DatabaseHelper: Retrieved full location data: $metadata');
        return metadata;
      } else {
        final value = metadata[key];
        print('DatabaseHelper: Retrieved location data for key $key: $value');
        return value as Map<String, dynamic>?;
      }
    } catch (e) {
      print('DatabaseHelper: Error reading location data for key $key: $e');
      return null;
    }
  }



  ////////// CACHED USERS TABLE //////////

  Future<void> cacheAllOtherUserProfiles(List<Map<dynamic, dynamic>> profiles) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var profile in profiles) {
        batch.insert(
          'other_user_profiles',
          {
            'name': profile['name'],
            'profile_data': jsonEncode(profile),
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      //print('DatabaseHelper: Cached ${profiles.length} profiles');
    } catch (e) {
      print('DatabaseHelper: Error caching all other user profiles: $e');
    }
  }

  Future<Map<dynamic, dynamic>?> getLastCachedProfile() async {
    try {
      final db = await database;
      final result = await db.query(
        'other_user_profiles',
        orderBy: 'created_at DESC', // Order by id in descending order to get the last row
        limit: 1, // Only need the last profile
      );
      if (result.isNotEmpty) {
        final profileDataJson = result[0]['profile_data'] as String;
        final profileData = jsonDecode(profileDataJson) as Map<dynamic, dynamic>;
        print('DatabaseHelper: Retrieved last profile: ${profileData['name']}');
        return profileData;
      }
      print('DatabaseHelper: No profiles found in other_user_profiles');
      return null;
    } 
    catch (e) {
      print('DatabaseHelper: Error reading last profile ID: $e');
      return null;
    }
  }

  Future<List<Map<dynamic, dynamic>>> getAllOtherUserProfiles({int page = 1, int pageSize = 105}) async {
    try {
      final db = await database;
      final result = await db.query('other_user_profiles');
      if (result.isEmpty) {
        print('DatabaseHelper: No profiles found in other_user_profiles');
        return [];
      }
      var profiles = result.map((row) => jsonDecode(row['profile_data'] as String) as Map<dynamic, dynamic>).toList();
      print('DatabaseHelper: Fetched ${profiles.length} profiles before filtering');
      profiles = await applyFilters(profiles);
      print('DatabaseHelper: After filtering, ${profiles.length} profiles remain');
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      //print('DatabaseHelper: Returning ${profiles.sublist(startIndex, endIndex.clamp(0, profiles.length)).length} profiles for page $page (startIndex: $startIndex, endIndex: $endIndex)');
      //print('PROFILES: $profiles');
      return profiles.sublist(startIndex, endIndex.clamp(0, profiles.length));
    } catch (e) {
      //print('DatabaseHelper: Error reading all other user profiles: $e');
      return [];
    }
  }

  Future<List<Map<dynamic, dynamic>>?> searchCache([String? name, String? number]) async {
    try {
      final db = await database;
      
      // Build the WHERE clause dynamically based on provided parameters
      List<String> conditions = [];
      List<dynamic> arguments = [];

      if (name != null && name.isNotEmpty) {
      conditions.add("profile_data LIKE ?");
      arguments.add('%\"name\":\"%$name%\"%');
      }
      if (number != null && number.isNotEmpty) {
        conditions.add("profile_data LIKE ?");
        arguments.add('%\"phone\":\"%$number%\"%');
      }
      
      // If no conditions, return null or query all (depending on your needs)
      if (conditions.isEmpty) {
        print('DatabaseHelper: No search parameters provided');
        return null;
      }
      
      // Construct the query
      String whereClause = conditions.join(' OR ');
      final result = await db.query(
        'other_user_profiles',
        where: whereClause,
        whereArgs: arguments,
      );
      
      if (result.isEmpty) {
        print('DatabaseHelper: No profiles found in other_user_profiles');
        return null;
      }

      // Decode profile_data for each row
      return result.map((row) {
        final mutableRow = Map<String, dynamic>.from(row);
        if (mutableRow['profile_data'] != null && mutableRow['profile_data'] is String) {
          try {
            mutableRow['profile_data'] = jsonDecode(mutableRow['profile_data'] as String);
            //print('DatabaseHelper: Successfully decoded profile_data for id ${mutableRow['id']}');
          } catch (e, stackTrace) {
            print('DatabaseHelper: Error decoding profile_data JSON for id ${mutableRow['id']}: $e');
            print('Raw profile_data: ${mutableRow['profile_data']}');
            print('Stack trace: $stackTrace');
            mutableRow['profile_data'] = {};
          }
        } else {
          print('DatabaseHelper: profile_data is not a String or is null for id ${mutableRow['id']}: ${mutableRow['profile_data']?.runtimeType}');
          mutableRow['profile_data'] = {};
        }
        return mutableRow;
      }).toList();
    } catch (e) {
      print('DatabaseHelper: Error searching all other user profiles: $e');
      return null;
    }
  }

  Future<int> getFilteredProfilesCount() async{
    try {
      final db = await database;
      final result = await db.query('other_user_profiles');
      if (result.isEmpty) {
        print('DatabaseHelper: No profiles found in other_user_profiles');
        return 0;
      }
      var profiles = result.map((row) => jsonDecode(row['profile_data'] as String) as Map<dynamic, dynamic>).toList();
      print('DatabaseHelper: Fetched ${profiles.length} profiles before filtering');
      profiles = await applyFilters(profiles);
      print('DatabaseHelper: After filtering, ${profiles.length} profiles remain');
      return profiles.length;
    } catch (e) {
      //print('DatabaseHelper: Error reading all other user profiles: $e');
      return 0;
    }
  }

  Future<int> getAllOtherUserProfilesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM other_user_profiles');
      final count = Sqflite.firstIntValue(result) ?? 0;
      // print('DatabaseHelper: Found $count profiles in other_user_profiles');
      return count;
    } catch (e) {
      print('DatabaseHelper: Error counting profiles: $e');
      return 0;
    }
  }

  Future<List<Map<dynamic, dynamic>>> applyFilters(List<Map<dynamic, dynamic>> profiles) async {
    print('Applying filters');
    final distanceFilter = await getFilterValue('distance') ?? '10 mi';
    final ageMin = await getFilterValue('ageMin') ?? '18';
    final ageMaxRead = await getFilterValue('ageMax') ?? '100';
    final ageMax = ageMaxRead == '50 +' ? '100' : ageMaxRead;
    final heightMin = await getFilterValue('heightMin') ?? "3' 0\"";
    final heightMax = await getFilterValue('heightMax') ?? "8' 0\"";
    final children = jsonDecode(await getFilterValue('children') ?? '[]') as List;
    final relationshipIntent = jsonDecode(await getFilterValue('relationshipIntent') ?? '[]') as List;
    final personalityTypes = jsonDecode(await getFilterValue('personalityTypes') ?? '[]') as List;
    final tags = jsonDecode(await getFilterValue('tags') ?? '[]') as List;
    final listSelection = await getFilterValue('listSelection') ?? '';

    // await _initializeFilters(await database);  // This should only be done when the database is created. Otherwise the users last filter selection is loaded from the sqlite settings table
    var filteredProfiles = profiles.where((profile) {
      bool matches = true;

      if (distanceFilter != null) {
        final profileDistance = double.tryParse(profile['distance']?.replaceAll(' mi', '') ?? '0.0') ?? 0.0;
        final maxDistance = double.parse(distanceFilter.replaceAll(' mi', ''));
        matches = matches && profileDistance <= maxDistance;
      }

      // Allow null or 'N/A' for age unless specific filter is set
      if (ageMin != null && ageMax != null && profile['age'] != null && profile['age'] != 'N/A') {
        final profileAge = int.tryParse(profile['age'].toString()) ?? 0;
        final minAge = int.parse(ageMin);
        final maxAge = int.parse(ageMax);
        matches = matches && profileAge >= minAge && profileAge <= maxAge;
      }

      // Allow null or 'N/A' for height unless specific filter is set
      if (heightMin != null && heightMax != null && profile['height'] != null && profile['height'] != 'N/A') {
        final profileHeight = parseHeight(profile['height']);
        final minHeight = parseHeight(heightMin);
        final maxHeight = parseHeight(heightMax);
        matches = matches && profileHeight >= minHeight && profileHeight <= maxHeight;
      }

      if (children.isNotEmpty) {
        matches = matches && children.contains(profile['children']);
      }

      if (relationshipIntent.isNotEmpty) {
        matches = matches && profile['relationship_intent'].any((intent) => relationshipIntent.contains(intent));
      }

      if (tags.isNotEmpty) {
        matches = matches && profile['tags'].any((tag) => tags.contains(tag));
      }

      if (listSelection.isNotEmpty) {
        // Implement list-based filtering if applicable
      }
      
      return matches;
    }).toList();

    filteredProfiles.sort((a, b) => double.parse(a['distance'] ?? '0.0').compareTo(double.parse(b['distance'] ?? '0.0')));

    //print('DatabaseHelper: Applied filters, returning ${filteredProfiles.length} profiles');
    return filteredProfiles;
  }

  double parseHeight(String height) {
    try {
      final parts = height.replaceAll('"', '').split("' ");
      final feet = int.parse(parts[0]);
      final inches = int.parse(parts[1]);
      return feet * 12 + inches.toDouble();
    } catch (e) {
      //print('DatabaseHelper: Error parsing height: $e');
      return 0.0;
    }
  }

  Future<void> cacheImage(String profileId, String imageUrl, String filePath) async {
    try {
      final db = await database;
      await db.insert(
        'cached_images',
        {
          'profile_id': profileId,
          'image_url': imageUrl,
          'file_path': filePath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('DatabaseHelper: Cached image for profile $profileId, url=$imageUrl, path=$filePath');
    } catch (e) {
      //print('DatabaseHelper: Error caching image: $e');
    }
  }

  Future<String?> getCachedImage(String profileId, String imageUrl) async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_images',
        where: 'profile_id = ? AND image_url = ?',
        whereArgs: [profileId, imageUrl],
      );
      if (result.isNotEmpty) {
        final filePath = result.first['file_path'] as String?;
        if (filePath != null && File(filePath).existsSync()) {
          //print('DatabaseHelper: Found cached image for profile $profileId, url=$imageUrl, path=$filePath');
          return filePath;
        } else {
          //print('DatabaseHelper: Invalid or missing cached image for profile $profileId, url=$imageUrl, path=$filePath');
          await deleteCachedImage(profileId, imageUrl);
        }
      }
      //print('DatabaseHelper: No cached image found for profile $profileId, url=$imageUrl');
      return null;
    } catch (e) {
      //print('DatabaseHelper: Error reading cached image: $e');
      return null;
    }
  }

  Future<void> deleteCachedImage(String profileId, String imageUrl) async {
    try {
      final db = await database;
      await db.delete(
        'cached_images',
        where: 'profile_id = ? AND image_url = ?',
        whereArgs: [profileId, imageUrl],
      );
      //print('DatabaseHelper: Deleted cached image for profile $profileId, url=$imageUrl');
    } catch (e) {
      //print('DatabaseHelper: Error deleting cached image: $e');
    }
  }

  Future<void> clearCachedImages() async {
    try {
      final db = await database;
      final images = await db.query('cached_images');
      for (var image in images) {
        final filePath = image['file_path'] as String?;
        if (filePath != null && File(filePath).existsSync()) {
          await File(filePath).delete();
          //print('DatabaseHelper: Deleted image file $filePath');
        }
      }
      await db.delete('cached_images');
      //print('DatabaseHelper: Cleared all cached images');
    } catch (e) {
      //print('DatabaseHelper: Error clearing cached images: $e');
    }
  }



  ////////// DATABASE MAINTANENCE //////////

  Future<void> clearAllSettings() async {
    try {
      final db = await database;
      await db.delete('settings');
      await db.delete('profile_metadata');
      await db.delete('other_user_profiles');
      await db.delete('filters');
      await db.delete('cached_images');
      await _initializeFilters(db);
      //print('DatabaseHelper: Cleared all settings and cached images, re-initialized filters');
    } catch (e) {
      //print('DatabaseHelper: Error clearing tables: $e');
    }
  }

  Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    await databaseFactory.deleteDatabase(path);
    print('DatabaseHelper: Deleted database at $path');
    _database = null; // Reset to force reinitialization
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    //print('DatabaseHelper: Database closed');
  }

  Future<void> logDatabaseContents() async {
    print('\n\n\n\n\n\n\n');
    print('\n\n=== SQLite Database Contents ===');
    try {
      final db = await database;

      // Helper function to print table contents
      Future<void> printTable(String tableName, {bool decodeJson = false}) async {
        final result = await db.query(tableName);
        print('$tableName: ${result.length} records');
        if (result.isEmpty) {
          print('  No records found');
        } else {
          for (var row in result) {
            if (decodeJson && row.containsKey('metadata') || row.containsKey('profile_data') || row.containsKey('value')) {
              // Handle JSON fields
              final jsonField = row['metadata'] ?? row['profile_data'] ?? row['value'];
              if (jsonField is String && jsonField.isNotEmpty) {
                try {
                  final decoded = jsonDecode(jsonField);
                  final jsonEncoded = JsonEncoder.withIndent('  ').convert(row..update('metadata', (_) => decoded, ifAbsent: () => decoded));
                  print('  Record:\n$jsonEncoded');
                } catch (e) {
                  print('  Record: $row (Error decoding JSON: $e)');
                }
              } else {
                print('  Record: $row');
              }
            } else {
              print('  Record: $row');
            }
          }
        }
      }

      // Log all tables
      //await printTable('settings');
      //await printTable('profile_metadata', decodeJson: true);
      await printTable('other_user_profiles', decodeJson: true);
      //await printTable('filters', decodeJson: true);
      //await printTable('cached_images');

      // Additional summary
      final tables = ['settings', 'profile_metadata', 'other_user_profiles', 'filters', 'cached_images'];
      final counts = await Future.wait(tables.map((table) async => (await db.query(table)).length));
      print('Summary:');
      for (var i = 0; i < tables.length; i++) {
        print('  ${tables[i]}: ${counts[i]} records');
      }
    } catch (e) {
      print('SQLite: Error logging database contents: $e');
    }
    print('=== End SQLite Contents ===\n\n');
  }
} 