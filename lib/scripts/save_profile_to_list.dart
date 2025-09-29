import 'package:flutter/material.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

class ProfileListManager {
  // Load profiles from a specified list (e.g., 'saved')
  static Future<List<Map<dynamic, dynamic>>> loadProfilesInList(String listName) async {
    final profiles = await sqlite.DatabaseHelper.instance.getProfilesInList(listName);
    return profiles;
  }

  // Check if a profile is in the specified list
  static Future<bool> isProfileSaved(String listName, String profileHashedId) async {
    final profiles = await loadProfilesInList(listName);
    return profiles.any((p) => p['hashedId'] == profileHashedId);
  }

  // Toggle a profile in/out of the specified list
  static Future<void> toggleProfileInList({
    required String listName,
    required String profileHashedId,
    required Map<dynamic, dynamic> profileData,
    required bool isCurrentlySaved,
    required BuildContext context,
    required Function setStateCallback,
  }) async {
    try {
      if (isCurrentlySaved) {
        await sqlite.DatabaseHelper.instance.removeProfileFromList(listName, profileHashedId);
      } else {
        await sqlite.DatabaseHelper.instance.addProfileToList(listName, profileHashedId, profileData);
        
        // If the profile was already disliked and the like button is pressed, it should be removed from disliked and vice versa
        // If the profile is not in the oposite list, no exception is thrown
        if (listName == 'liked') {
          print('removing dislike');
          await sqlite.DatabaseHelper.instance.removeProfileFromList('disliked', profileHashedId);
        }
        if (listName == 'disliked') {
          print('removing like');
          await sqlite.DatabaseHelper.instance.removeProfileFromList('liked', profileHashedId);
        }
      }
      // Reload profiles and update state
      final profiles = await loadProfilesInList(listName);
      setStateCallback({
        'profilesInList': profiles,
        'profileSaved': profiles.any((p) => p['hashedId'] == profileHashedId),
      });
    } catch (e) {
      print('Error toggling profile in list: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}