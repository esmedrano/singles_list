import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';

//import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:integra_date/databases/sqlite_database.dart';

class ProfileLocation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double distanceThreshold = 20.0; // Miles

  static Future<List<double>?> getLocation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final geoHasher = GeoHasher();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in')),
      );
      return null;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return null;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final newLat = position.latitude;
    final newLon = position.longitude;

    // Cache current location locally
    final geohash = geoHasher.encode(newLon, newLat);

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.cacheUserMetadata({
      'latitude': newLat,
      'longitude': newLon,
      'geohash': geohash,
    });

    // Get central location from SQLite
    final centralLocation = await dbHelper.getUserMetadata('central_location_${user.uid}');
    bool shouldUpdate = false;
    double centralLat = 0.0;
    double centralLon = 0.0;

    if (centralLocation != null) {
      centralLat = centralLocation['latitude'] as double? ?? 0.0;
      centralLon = centralLocation['longitude'] as double? ?? 0.0;
      final distance = Geolocator.distanceBetween(centralLat, centralLon, newLat, newLon) * 0.000621371; // Meters to miles
      shouldUpdate = distance >= distanceThreshold;
      print('Distance from central location: $distance miles');
    } else {
      // No cached central location, fetch from Firebase
      final userDocRef = _firestore.collection('user_ids').doc(user.phoneNumber);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        centralLat = data?['latitude'] as double? ?? 0.0;
        centralLon = data?['longitude'] as double? ?? 0.0;
        await dbHelper.cacheUserMetadata({
          'latitude': centralLat,
          'longitude': centralLon,
          'geohash': geohash,
        });
      }
      shouldUpdate = true; // Update with new location if none exists
    }

    // Update Firebase and SQLite if moved 20 miles or no central location
    if (shouldUpdate) {
      await storeLocation(context, newLat, newLon);
    } else {
      print('Current location within 20 miles of central location');
    }

    return [newLat, newLon];
  }

  static Future<void> storeLocation(BuildContext context, double lat, double lon) async {
    final user = FirebaseAuth.instance.currentUser;
    final geoHasher = GeoHasher();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    try {
      // GeoFirePoint geoPoint = GeoFirePoint(GeoPoint(lat, lon));
      final geohash = geoHasher.encode(lon, lat);
      final userDocRef = _firestore.collection('user_ids').doc(user.phoneNumber);
      final userDoc = await userDocRef.get();

      // Update Firebase
      await userDocRef.set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'latitude': lat,
        'longitude': lon,
        'geohash': geohash, 
        'created_at': userDoc.exists ? userDoc['created_at'] : DateTime.now().toUtc().toString(),
      }, SetOptions(merge: true));

      // Update SQLite cache for central location
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.cacheUserMetadata({
        'latitude': lat,
        'longitude': lon,
        'geohash': geohash,
      });
      await dbHelper.setHasLocation(true);

      print('Updated central location in Firebase and SQLite: $lat, $lon');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location updated: $lat, $lon')),
      );
    } catch (e) {
      print('Error updating location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }
}

// grok says this is broken too
/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:integra_date/firebase/sqlite_database.dart';

class ProfileLocation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double distanceThreshold = 20.0; // Miles

  static Future<List<double>?> getLocation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in')),
      );
      return null;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return null;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final newLat = position.latitude;
    final newLon = position.longitude;

    // Cache current location locally
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.cacheProfileMetadata(user.uid, {
      'latitude': newLat,
      'longitude': newLon,
    });

    // Get central location from SQLite
    final centralLocation = await dbHelper.getProfileMetadata('central_location_${user.uid}');
    bool shouldUpdate = false;
    double centralLat = 0.0;
    double centralLon = 0.0;

    if (centralLocation != null) {
      centralLat = centralLocation['latitude'] as double? ?? 0.0;
      centralLon = centralLocation['longitude'] as double? ?? 0.0;
      final distance = Geolocator.distanceBetween(centralLat, centralLon, newLat, newLon) * 0.000621371; // Meters to miles
      shouldUpdate = distance >= distanceThreshold;
      print('Distance from central location: $distance miles');
    } else {
      // No cached central location, fetch from Firebase
      final userDocRef = FirebaseFirestore.instance.collection('user_ids').doc(user.phoneNumber);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        centralLat = data?['latitude'] as double? ?? 0.0;
        centralLon = data?['longitude'] as double? ?? 0.0;
        await dbHelper.cacheProfileMetadata('central_location_${user.uid}', {
          'latitude': centralLat,
          'longitude': centralLon,
        });
      }
      shouldUpdate = true; // Update with new location if none exists
    }

    // Update Firebase and SQLite if moved 20 miles or no central location
    if (shouldUpdate) {
      await storeLocation(context, newLat, newLon);
    } else {
      print('Current location within 20 miles of central location');
    }

    return [newLat, newLon];
  }

    // Store location in Firestore
  static Future<void> storeLocation(BuildContext context, double lat, double lon) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    GeoFirePoint geoPoint = GeoFirePoint(GeoPoint(lat, lon));
    await _firestore
        .collection('user_ids')
        .doc(user.phoneNumber ?? user.uid)
        .set({
          'position': geoPoint.data,
          'latitude': lat,
          'longitude': lon,
          'geohash': geoPoint.geohash,
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location sent to firebase: $lat, $lon')),
    );
  }
} */

// this is very broken
/* import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:integra_date/firebase/sqlite_database.dart';

class ProfileLocation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double distanceThreshold = 20.0; // 20 miles

  // Get current location and check if it needs updating
  static Future<List<double>?> getLocation(BuildContext context) async {  // This runs every time the app is opened 
    final user = FirebaseAuth.instance.currentUser;
    bool? shouldUpdate;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return null;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return null;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final newLat = position.latitude;
    final newLon = position.longitude;

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.cacheProfileMetadata('user_location', {
        'latitude': newLat,
        'longitude': newLon,
      });
    
    // Load last known location from SQLite
    final lastLocation = await dbHelper.getProfileMetadata('last_user_location');

    if (lastLocation != null) {
      print('last location not null')
      final lastLat = lastLocation['latitude'] ?? 0.0;
      final lastLon = lastLocation['longitude'] ?? 0.0;
      final distance = Geolocator.distanceBetween(lastLat, lastLon, newLat, newLon) * 0.000621371; // Meters to miles
      shouldUpdate = distance >= distanceThreshold;
    }

    // Store location locally if moved 20 miles
    if (shouldUpdate != null && shouldUpdate == true) {
      print('last location is >20 miles from last location');
      await storeLocation(context, newLat, newLon);
      await dbHelper.setHasLocation(true);
      print('profile_location.dart updated location: $newLat, $newLon');

      await dbHelper.cacheProfileMetadata('last_user_location', {  // only store the last location if the new location moved 20 miles, not every time the app is opened
      'latitude': newLat,
      'longitude': newLon,
    });
    } else {
      print('last location was not >20 miles from last location')
    }

    return [newLat, newLon]; 
  }

  // Store location in Firestore
  static Future<void> storeLocation(BuildContext context, double lat, double lon) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    GeoFirePoint geoPoint = GeoFirePoint(GeoPoint(lat, lon));
    await _firestore
        .collection('user_ids')
        .doc(user.phoneNumber ?? user.uid)
        .set({
          'position': geoPoint.data,
          'latitude': lat,
          'longitude': lon,
          'geohash': geoPoint.geohash,
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location sent to firebase: $lat, $lon')),
    );
  }
} */