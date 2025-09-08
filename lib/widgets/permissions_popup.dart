import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PermissionPopup {
  static void show(BuildContext context, VoidCallback onRetry, VoidCallback onLogout) {
    showDialog(
      context: context,
      barrierDismissible: false, // Non-dismissible
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please enable location permissions to use this app.'),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              //Navigator.pop(context); // Close popup
              //onRetry(); // Re-check permissions
            },
            child: const Text('Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close popup
              onRetry(); // Retry permissions
            },
            child: const Text('Retry Location'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context); // Close popup
              onLogout(); // Update state after logout
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}