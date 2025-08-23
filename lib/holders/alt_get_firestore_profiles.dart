// client side distance with emulator profiles
/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // For distance calculation
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

Future<List<Map<dynamic, dynamic>>> fetchInitialEntries() async {
  try {
    // Simulate a 2-second delay for consistency with the original
    await Future.delayed(const Duration(seconds: 2));

    print('Fetching profiles from FIRESTORE user_ids collection...');
    final user = FirebaseAuth.instance.currentUser;
    final querySnapshot = await FirebaseFirestore.instance.collection('user_ids').where('uid', isNotEqualTo: user!.uid).get();
    print('FIRESTORE query returned ${querySnapshot.docs.length} documents');

    if (querySnapshot.docs.isEmpty) {
      print('No documents found in user_ids collection');
      return [];
    }

    final userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final userLat = userPosition.latitude;
    final userLon = userPosition.longitude;

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      //print('Processing document with uid: ${doc.id}, data: $data');

      // Calculate distance using Haversine formula
      double calculateDistance(lat1, lon1, lat2, lon2) {
        const double earthRadius = 3958.8; // Miles
        final latRad1 = lat1 * math.pi / 180;
        final latRad2 = lat2 * math.pi / 180;
        final deltaLat = (lat2 - lat1) * math.pi / 180;
        final deltaLon = (lon2 - lon1) * math.pi / 180;
        final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
            math.cos(latRad1) * math.cos(latRad2) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
        final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        return earthRadius * c;
      }

      final distance = calculateDistance(userLat, userLon, data['latitude'], data['longitude']).toStringAsFixed(1);
      final createdAt = data['created_at'] is Timestamp ? data['created_at'].millisecondsSinceEpoch : data['created_at'] ?? '';
      final updatedAt = data['updated_at'] is Timestamp ? data['updated_at'].millisecondsSinceEpoch : data['updated_at'] ?? 0;

      final profile = {
        'profilePic': 'assets/profile_image.jpg',
        //'images': (data['imageUrls'] as List?)?.where((url) => url.isNotEmpty).toList() ?? [],
        'images': ['assets/profile_image.jpg', 'assets/profile_image.jpg', 'assets/profile_image.jpg', 'assets/profile_image.jpg', 'assets/profile_image.jpg', 'assets/profile_image.jpg'],
        'name': data['uid']?.toString().replaceFirst('testUser', '') ?? 'Unknown',
        'age': 'N/A', // Could derive from data if available
        'height': data['height'] ?? 'N/A',
        'location': 'Euless, TX', // Placeholder, could derive from geohash or coordinates
        'distance': '$distance mi',
        'intro': data['intro'] ?? '',
        // Include seeded fields with Timestamp conversion
        'children': data['children'] ?? '',
        'created_at': createdAt, // Converted to milliseconds or string
        'email': data['email'] ?? '',
        'geohash': data['geohash'] ?? '',
        'latitude': data['latitude'] ?? 0.0,
        'longitude': data['longitude'] ?? 0.0,
        'personality': data['personality'] ?? '',
        'phone': data['phone'] ?? '',
        'position': {
          'geohash': data['position']?['geohash'] ?? '',
          'geopoint': data['position']?['geopoint']?.latitude ?? 0.0,
          'longitude': data['position']?['geopoint']?.longitude ?? 0.0,
        },
        'provider': data['provider'] ?? '',
        'relationship_intent': (data['relationship_intent'] as List?)?.map((e) => e.toString()).toList() ?? [],
        'tags': (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        'uid': data['uid'] ?? '',
        'updated_at': updatedAt, // Converted to milliseconds
        'verified': data['verified'] ?? false,
      };
      //print('Mapped profile for uid ${doc.id}: $profile');
      return profile;
    }).toList();
  } catch (e) {
    print('Error fetching initial entries: $e');
    return [];
  }
} */

// hardcoded demo profiles
/* Future<List<Map<dynamic, dynamic>>> fetchInitialEntries() async {  // Load first profiles from firebase user database

  await Future.delayed(Duration(seconds: 2));
  
  List<Map<dynamic, dynamic>> profileData = [  // Replace with actual database call
  {'profilePic':'assets/test_photos/IMG_0197.jpeg', 
    'images':
    ['assets/test_photos/IMG_0164.jpeg', 
    'assets/test_photos/IMG_0167.jpeg', 
    'assets/test_photos/IMG_0168.jpeg', 
    'assets/test_photos/IMG_0197.jpeg',
    'assets/test_photos/IMG_0206.jpeg',
    'assets/test_photos/IMG_0219.jpeg',
    ], 
    'name':'Elijah', 
    'age':'24', 
    'height':'5\'10"', 
    'location':'Euless, TX', 
    'distance':'1 mi',
    'intro':'Hello world! My name is Elijah Medrano and I like to code. I also like to play video games. /n test'
  }, 
  {'profilePic':'assets/test_photos/IMG_0164.jpeg', 
    'images':[
    'assets/test_photos/IMG_0164.jpeg', 
    'assets/test_photos/IMG_0167.jpeg', 
    'assets/test_photos/IMG_0168.jpeg', 
    'assets/test_photos/IMG_0197.jpeg',
    'assets/test_photos/IMG_0206.jpeg', 
    ],
    'name':'Elijah Medrano', 
    'age':'24', 
    'height':'5\'10"', 
    'location':'Euless, TX', 
    'distance':'10 mi'}, 
  {'profilePic':'assets/test_photos/IMG_0310.jpeg', 
    'images':[
    'assets/test_photos/IMG_0164.jpeg', 
    'assets/test_photos/IMG_0167.jpeg', 
    'assets/test_photos/IMG_0168.jpeg', 
    'assets/test_photos/IMG_0197.jpeg',
    'assets/test_photos/IMG_0206.jpeg', 
    ],
    'name':'Elijah Medrano', 
    'age':'24', 
    'height':'5\'10"', 
    'location':'Euless, TX', 
    'distance':'1 mi'}];

  return profileData;
} */