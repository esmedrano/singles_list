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
      CREATE TABLE profile_metadata (
        user_id TEXT PRIMARY KEY,
        metadata TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE other_user_profiles (
        name TEXT PRIMARY KEY,
        profile_data TEXT
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
    //print('DatabaseHelper: Database created with initial filter values');
  }

  Future<void> _initializeFilters(Database db) async {
    await db.insert('filters', {'key': 'distance', 'value': '10 mi'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'ageMin', 'value': '18'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'ageMax', 'value': '100'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'heightMin', 'value': "3' 0\""}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('filters', {'key': 'heightMax', 'value': "8' 0\""}, conflictAlgorithm: ConflictAlgorithm.ignore);
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

  Future<bool> getHasLocation() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['hasLocation'],
      );
      //print('DatabaseHelper: getHasLocation returned ${result.isNotEmpty && result.first['value'] == 'true'}');
      return result.isNotEmpty && result.first['value'] == 'true';
    } catch (e) {
      //print('DatabaseHelper: Error reading hasLocation: $e');
      return false;
    }
  }

  Future<void> setHasLocation(bool value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': 'hasLocation', 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('DatabaseHelper: Set hasLocation to $value');
    } catch (e) {
      //print('DatabaseHelper: Error saving hasLocation: $e');
    }
  }

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

  Future<void> cacheUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final db = await database;
      await db.insert(
        'profile_metadata',
        {'metadata': jsonEncode(metadata)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('DatabaseHelper: Cached metadata for user $userId');
    } catch (e) {
      //print('DatabaseHelper: Error caching profile metadata: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserMetadata(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'profile_metadata',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        //print('DatabaseHelper: Retrieved metadata for user $userId');
        return jsonDecode(result.first['metadata'] as String);
      }
      //print('DatabaseHelper: No metadata found for user $userId');
      return null;
    } catch (e) {
      //print('DatabaseHelper: Error reading profile metadata: $e');
      return null;
    }
  }

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
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      //print('DatabaseHelper: Cached ${profiles.length} profiles');
    } catch (e) {
      //print('DatabaseHelper: Error caching all other user profiles: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile(String name, String tag) async {
    try {
      final db = await database;
      final result = await db.query(
        'other_user_profiles',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (result.isNotEmpty) {
        //print('DatabaseHelper: Retrieved profile for name $name');
        return jsonDecode(result.first['profile_data'] as String);
      }
      //print('DatabaseHelper: No profile found for name $name');
      return null;
    } catch (e) {
      //print('DatabaseHelper: Error reading other user profile: $e');
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
      //print('DatabaseHelper: Fetched ${profiles.length} profiles before filtering');
      profiles = await applyFilters(profiles);
      //print('DatabaseHelper: After filtering, ${profiles.length} profiles remain');
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

  Future<List<Map<dynamic, dynamic>>> applyFilters(List<Map<dynamic, dynamic>> profiles) async {
    final distanceFilter = await getFilterValue('distance') ?? '10 mi';
    final ageMin = await getFilterValue('ageMin') ?? '18';
    final ageMax = await getFilterValue('ageMax') ?? '100';
    final heightMin = await getFilterValue('heightMin') ?? "3' 0\"";
    final heightMax = await getFilterValue('heightMax') ?? "8' 0\"";
    final children = jsonDecode(await getFilterValue('children') ?? '[]') as List;
    final relationshipIntent = jsonDecode(await getFilterValue('relationshipIntent') ?? '[]') as List;
    final personalityTypes = jsonDecode(await getFilterValue('personalityTypes') ?? '[]') as List;
    final tags = jsonDecode(await getFilterValue('tags') ?? '[]') as List;
    final listSelection = await getFilterValue('listSelection') ?? '';

    await _initializeFilters(await database);

    var filteredProfiles = profiles.where((profile) {
      bool matches = true;

      if (distanceFilter != null) {
        final profileDistance = double.tryParse(profile['distance']?.replaceAll(' mi', '') ?? '0.0') ?? 0.0;
        final maxDistance = double.parse(distanceFilter.replaceAll(' mi', ''));
        print('Max Distance: $maxDistance');
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
      await printTable('settings');
      await printTable('profile_metadata', decodeJson: true);
      // await printTable('other_user_profiles', decodeJson: true);
      // await printTable('filters', decodeJson: true);
      // await printTable('cached_images');

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

// version 1
/* import 'dart:convert';
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE profile_metadata (
            user_id TEXT PRIMARY KEY,
            metadata TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE other_user_profiles (
            name TEXT PRIMARY KEY,
            profile_data TEXT
          )
        ''');
      },
    );
  }

  Future<void> clearAllSettings() async {
    try {
      final db = await database;
      await db.delete('settings');
      await db.delete('profile_metadata');
      await db.delete('other_user_profiles');
      //print('Cleared settings, profile_metadata, and other_user_profiles tables');
    } catch (e) {
      //print('Error clearing tables: $e');
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
      //print('Error reading hasLocation: $e');
      return false;
    }
  }

  Future<void> setHasLocation(bool value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': 'hasLocation', 'value': value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('Saved hasLocation: $value');
    } catch (e) {
      //print('Error saving hasLocation: $e');
    }
  }

  // For app user's metadata (e.g., location)
  Future<void> cacheUserMetadata(String userId, Map<String, dynamic> metadata) async {
    try {
      final db = await database;
      await db.insert(
        'profile_metadata',
        {'user_id': userId, 'metadata': jsonEncode(metadata)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      //print('Cached profile metadata for user: $userId');
    } catch (e) {
      //print('Error caching profile metadata: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserMetadata(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'profile_metadata',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        return jsonDecode(result.first['metadata'] as String);
      }
      return null;
    } catch (e) {
      //print('Error reading profile metadata: $e');
      return null;
    }
  }

  Future<void> cacheAllOtherUserProfiles(List<Map<dynamic, dynamic>> profiles) async {  // Batch cache allprofiles recieved from firestore 
    try {
      final db = await database;
      final batch = db.batch();
      for (var profile in profiles) {
        batch.insert(
          'other_user_profiles',
          {
            'name': profile['name'],
            'profile_data': jsonEncode(profile),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      //print('Cached ${profiles.length} profiles in other_user_profiles');
    } catch (e) {
      //print('Error caching all other user profiles: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile(String name, String tag) async {  // This will be the search and filter function
    try {
      final db = await database;
      final result = await db.query(
        'other_user_profiles',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (result.isNotEmpty) {
        return jsonDecode(result.first['profile_data'] as String);
      }
      return null;
    } catch (e) {
      //print('Error reading other user profile: $e');
      return null;
    }
  }

  Future<List<Map<dynamic, dynamic>>> getAllOtherUserProfiles() async {
    try {
      final db = await database;
      final result = await db.query('other_user_profiles');
      if (result.isEmpty) {
        //print('other_user_profiles table is empty');
        return [];
      }
      return result.map((row) => jsonDecode(row['profile_data'] as String) as Map<dynamic, dynamic>).toList();
    } catch (e) {
      //print('Error reading all other user profiles: $e');
      return [];
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} */