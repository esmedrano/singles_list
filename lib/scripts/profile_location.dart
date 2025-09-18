import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class ProfileLocation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double distanceThreshold = 20.0; // Miles

  static Future<List<double>?> getLocation(BuildContext context, VoidCallback settingsButton) async {
    final user = FirebaseAuth.instance.currentUser;
    final geoHasher = GeoHasher();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return null;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    print(permission);

    // const maxAttempts = 5;
    // int attempts = 0;
    // while (permission == LocationPermission.denied && attempts < maxAttempts) {
    //   await Future.delayed(const Duration(milliseconds: 500));
    //   permission = await Geolocator.checkPermission();
    //   attempts++;
    // }

    if (permission == LocationPermission.denied) {
      print('denied');
      permission = await Geolocator.requestPermission();
      //permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        settingsButton();
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      settingsButton();
      return null;
    }

    // Get current position
    Position position;
    try {
      print('attemtping location');
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error getting current position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
      return null;
    }

    final newLat = position.latitude;
    final newLon = position.longitude;

    print('$newLat, $newLon');

    // Get central location from SQLite
    final dbHelper = sqlite.DatabaseHelper.instance;
    final centralLocation = await dbHelper.getUserLocation('central_location');
    print('Central location: $centralLocation');
    bool shouldUpdate = false;
    double centralLat = 0.0;
    double centralLon = 0.0;

    if (centralLocation != null) {
      // centralLat = centralLocation['latitude'] as double; //? ?? 0.0;
      // centralLon = centralLocation['longitude'] as double; //? ?? 0.0;

      // Safely parse latitude and longitude
      final latValue = centralLocation['latitude'];
      final lonValue = centralLocation['longitude'];

      print(latValue);
      print(lonValue);
      
      // Handle null or non-double values
      centralLat = latValue is num ? latValue.toDouble() : (double.tryParse(latValue?.toString() ?? '') ?? 0.0);
      centralLon = lonValue is num ? lonValue.toDouble() : (double.tryParse(lonValue?.toString() ?? '') ?? 0.0);

      final distance = Geolocator.distanceBetween(centralLat, centralLon, newLat, newLon) * 0.000621371; // Meters to miles
      shouldUpdate = distance >= distanceThreshold;
      print('Distance from central location: $distance miles');
      
      if (shouldUpdate) {
        print('Distance ($distance) is greater than $distanceThreshold. Updating central location.');
      }
    } else {
      shouldUpdate = true; // No central location, update with current
      print('No central location found, using current location');
    }

    // Update Firebase and SQLite if needed
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
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    try {
      final String userDocTitle = await sqlite.DatabaseHelper.instance.getUserDocTitle();
      final geohash = geoHasher.encode(lon, lat);
      final userDocRef = _firestore.collection('user_ids').doc(userDocTitle);
      final userDoc = await userDocRef.get();

      // Update Firebase
      await userDocRef.set({
        //'uid': user.uid,
        //'phone': user.phoneNumber,
        'latitude': lat,
        'longitude': lon,
        'geohash': geohash,
        'created_at': userDoc.exists ? userDoc['created_at'] : DateTime.now().toUtc().toString(),
      }, SetOptions(merge: true));

      // Update SQLite cache for central location
      final dbHelper = sqlite.DatabaseHelper.instance;
      await dbHelper.cacheUserLocation('central_location', {
        'latitude': lat,
        'longitude': lon,
        'geohash': geohash,
      });
      await dbHelper.setHasLocation(true);

      print('Updated central location in Firebase and SQLite: $lat, $lon');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated')),
      );
    } catch (e) {
      print('Error updating location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }
}