// In settings_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:integra_date/databases/sqlite_database.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.switchPage});

  final Function(int, int?) switchPage;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool accountInfoExpanded = false;
  String currentSubscription = 'none';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(15.0),
        children: [
          // Back to profile button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => widget.switchPage(3, null),
            ),
          ),
          
          const SizedBox(height: 40),

          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LogoutButton(switchPage: widget.switchPage),
              DeleteAccountButton(switchPage: widget.switchPage),
            ],
          ),
        
          // AccountInfo(emailController: _emailController, passwordController: _passwordController, switchPage: widget.switchPage),
      
          const SizedBox(height: 40),
      
          Subscription(currentSubscription: currentSubscription),

          const SizedBox(height: 40),

          Preferences(),
          
          const SizedBox(height: 40),

          Privacy(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class Subscription extends StatefulWidget {
  const Subscription({
    super.key,
    required this.currentSubscription,
  });

  final String currentSubscription;

  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  bool subscriptionExpanded = false;

  void onSubscriptionToggle() {
    setState(() {
      subscriptionExpanded = !subscriptionExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Subscription',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onSubscriptionToggle,
                isSelected: subscriptionExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (subscriptionExpanded)
            Column(
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        // Add subscription logic here
                      },
                      child: Container(
                        width: (MediaQuery.sizeOf(context).width - 15 * 3) / 2,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Verified User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(height: 15),
                            Text('All features', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('Bot Free', style: TextStyle(color: Colors.white)),
                            Text('Experience', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('10 Likes', style: TextStyle(color: Colors.white)),
                            Text('every 24 hours', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('10 messages', style: TextStyle(color: Colors.white)),
                            Text('every 24 hours', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Add subscription logic here
                      },
                      child: Container(
                        width: (MediaQuery.sizeOf(context).width - 15 * 3) / 2,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Verified Plus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(height: 15),
                            Text('All features', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('Bot Free', style: TextStyle(color: Colors.white)),
                            Text('Experience', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('50 likes', style: TextStyle(color: Colors.white)),
                            Text('every hour', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('50 messages', style: TextStyle(color: Colors.white)),
                            Text('every hour', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '5 \$/month',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '10 \$/month',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'current subscription:',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      widget.currentSubscription,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width / 1.5,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add change subscription logic here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('change subscription'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  _PreferencesState createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  bool preferencesExpanded = false;
  bool isDarkMode = true; // Default to dark mode (assuming current theme)
  bool notificationsEnabled = true; // Default to enabled

  void onPreferencesToggle() {
    setState(() {
      preferencesExpanded = !preferencesExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Preferences',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onPreferencesToggle,
                isSelected: preferencesExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (preferencesExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: isDarkMode,
                      onChanged: (bool value) {
                        setState(() {
                          isDarkMode = value;
                          // Add logic to change app theme here (e.g., using Provider or ThemeMode)
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          notificationsEnabled = value;
                          // Add logic to enable/disable notifications here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  _PrivacyState createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  bool privacyExpanded = false;
  bool locationServicesEnabled = true; // Default to enabled
  bool profileVisibility = true; // Default to visible
  bool appearInSearches = true; // Default to visible

  void onPrivacyToggle() {
    setState(() {
      privacyExpanded = !privacyExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Privacy',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onPrivacyToggle,
                isSelected: privacyExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (privacyExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location Services',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: locationServicesEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          locationServicesEnabled = value;
                          // Add logic to manage location permissions here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Visibility',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: profileVisibility,
                      onChanged: (bool value) {
                        setState(() {
                          profileVisibility = value;
                          // Add logic to toggle profile visibility here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appear in Searches',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: appearInSearches,
                      onChanged: (bool value) {
                        setState(() {
                          appearInSearches = value;
                          // Add logic to toggle appear in searches here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final Function(int, int?) switchPage;

  const LogoutButton({super.key, required this.switchPage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.5,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await FirebaseAuth.instance.signOut();
                      switchPage(5, null);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                    }
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Colors.white),
          foregroundColor: Colors.white,
        ),
        child: const Text('Log out'),
      ),
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final Function(int, int?) switchPage;

  const DeleteAccountButton({super.key, required this.switchPage});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.5,
      child: ElevatedButton(
        onPressed: () => _confirmDelete(context, switchPage),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
        ),
        child: const Text('Delete Account'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Function(int, int?) switchPage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? \n\nThis action cannot be undone, and you will need to wait 2 days before creating another one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, switchPage);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, Function(int, int?) switchPage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user signed in at ${DateTime.now()}');
      return;
    }

    try {
      // Configure emulator if in debug mode
      // if (kDebugMode) {
      //   FirebaseStorage.instance.useStorageEmulator('192.168.1.153', 9199);
      //   debugPrint('Storage emulator configured: 192.168.1.153:9199 at ${DateTime.now()}');
      // }

      // Fetch and delete profile images from Firebase Storage
      if (user.phoneNumber != null) {
        final docRef = FirebaseFirestore.instance.collection('user_ids').doc(user.phoneNumber);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data();
          final imageUrls = List<String>.from(data?['imageUrls'] ?? []);
          debugPrint('Found imageUrls for deletion: $imageUrls at ${DateTime.now()}');
          for (final url in imageUrls) {
            if (url.isNotEmpty) {
              try {
                debugPrint('Deleting image from Firebase Storage: $url at ${DateTime.now()}');
               final storageRef = FirebaseStorage.instance.ref().child(Uri.parse(url).path.split('/o/').last.split('?').first);        
                await storageRef.delete();
                debugPrint('Image deleted successfully from Firebase Storage at ${DateTime.now()}');
              } catch (e) {
                debugPrint('Error deleting image from Firebase Storage: $e for URL: $url at ${DateTime.now()}');
                // Continue with deletion even if an image fails
              }
            }
          }
          // Delete user profile from user_ids collection
          debugPrint('Deleting profile from user_ids for user ${user.uid} with phone number ${user.phoneNumber} at ${DateTime.now()}');
          await docRef.delete();
        }
      }

      // Delete user profile from profiles collection (if it exists) 
      // debugPrint('Deleting profile from profiles for user ${user.uid} at ${DateTime.now()}');  DONT DO THIS AGAIN bc it is done one line above this one already
      // await FirebaseFirestore.instance.collection('profiles').doc(user.uid).delete();

      // Clear all settings in SQLite
      debugPrint('Clearing SQLite settings for user ${user.uid} at ${DateTime.now()}');
      await DatabaseHelper.instance.clearAllSettings();

      // Delete Firebase Auth user
      debugPrint('Deleting Firebase Auth user ${user.uid} at ${DateTime.now()}');
      await user.delete();

      // Sign out and navigate to login page
      await FirebaseAuth.instance.signOut();
      debugPrint('User signed out and navigating to login page at ${DateTime.now()}');
      switchPage(5, null);
    } catch (e) {
      debugPrint('Error deleting account: $e at ${DateTime.now()}');
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        await FirebaseAuth.instance.signOut();
        switchPage(0, null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }
}

// Kept this j bc
/* import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:integra_date/firebase/sqlite_database.dart';
import 'package:firebase_storage/firebase_storage.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.switchPage});

  final Function(int, int?) switchPage;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool accountInfoExpanded = false;
  String currentSubscription = 'none';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(15.0),
        children: [
          // Back to profile button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => widget.switchPage(3, null),
            ),
          ),
          
          const SizedBox(height: 40),

          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            LogoutButton(switchPage: widget.switchPage),
            DeleteAccountButton(switchPage: widget.switchPage),
            ],
          ),
        
          // AccountInfo(emailController: _emailController, passwordController: _passwordController, switchPage: widget.switchPage),
      
          const SizedBox(height: 40),
      
          Subscription(currentSubscription: currentSubscription),

          const SizedBox(height: 40),

          Preferences(),
          
          const SizedBox(height: 40),

          Privacy(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/* class AccountInfo extends StatefulWidget {
  const AccountInfo({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.switchPage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(int, int?) switchPage;

  @override
  _AccountInfoState createState() => _AccountInfoState();
} */

/* class _AccountInfoState extends State<AccountInfo> {
  bool obscurePassword = true;
  bool accountInfoExpanded = false;

  void onAccountInfoToggle() {
    setState(() {
      accountInfoExpanded = !accountInfoExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Account Info',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onAccountInfoToggle,
                isSelected: accountInfoExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (accountInfoExpanded)
            Column(
              children: [
                const SizedBox(height: 15),
                TextField(
                  controller: widget.emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Bottom action buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LogoutButton(switchPage: widget.switchPage),
                    DeleteAccountButton(switchPage: widget.switchPage),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
} */

class Subscription extends StatefulWidget {
  const Subscription({
    super.key,
    required this.currentSubscription,
  });

  final String currentSubscription;

  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  bool subscriptionExpanded = false;

  void onSubscriptionToggle() {
    setState(() {
      subscriptionExpanded = !subscriptionExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Subscription',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onSubscriptionToggle,
                isSelected: subscriptionExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (subscriptionExpanded)
            Column(
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        // Add subscription logic here
                      },
                      child: Container(
                        width: (MediaQuery.sizeOf(context).width - 15 * 3) / 2,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Verified User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(height: 15),
                            Text('All features', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('Bot Free', style: TextStyle(color: Colors.white)),
                            Text('Experience', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('10 Likes', style: TextStyle(color: Colors.white)),
                            Text('every 24 hours', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('10 messages', style: TextStyle(color: Colors.white)),
                            Text('every 24 hours', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Add subscription logic here
                      },
                      child: Container(
                        width: (MediaQuery.sizeOf(context).width - 15 * 3) / 2,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Verified Plus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(height: 15),
                            Text('All features', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('Bot Free', style: TextStyle(color: Colors.white)),
                            Text('Experience', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('50 likes', style: TextStyle(color: Colors.white)),
                            Text('every hour', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('50 messages', style: TextStyle(color: Colors.white)),
                            Text('every hour', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '5 \$/month',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '10 \$/month',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'current subscription:',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      widget.currentSubscription,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width / 1.5,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add change subscription logic here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('change subscription'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  _PreferencesState createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  bool preferencesExpanded = false;
  bool isDarkMode = true; // Default to dark mode (assuming current theme)
  bool notificationsEnabled = true; // Default to enabled

  void onPreferencesToggle() {
    setState(() {
      preferencesExpanded = !preferencesExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Preferences',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onPreferencesToggle,
                isSelected: preferencesExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (preferencesExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: isDarkMode,
                      onChanged: (bool value) {
                        setState(() {
                          isDarkMode = value;
                          // Add logic to change app theme here (e.g., using Provider or ThemeMode)
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          notificationsEnabled = value;
                          // Add logic to enable/disable notifications here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  _PrivacyState createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  bool privacyExpanded = false;
  bool locationServicesEnabled = true; // Default to enabled
  bool profileVisibility = true; // Default to visible
  bool appearInSearches = true; // Default to visible

  void onPrivacyToggle() {
    setState(() {
      privacyExpanded = !privacyExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
      decoration: BoxDecoration(
        color: Color(0x50FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Privacy',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onPrivacyToggle,
                isSelected: privacyExpanded,
                selectedIcon: const Icon(Icons.keyboard_arrow_up),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (privacyExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location Services',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: locationServicesEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          locationServicesEnabled = value;
                          // Add logic to manage location permissions here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Visibility',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: profileVisibility,
                      onChanged: (bool value) {
                        setState(() {
                          profileVisibility = value;
                          // Add logic to toggle profile visibility here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appear in Searches',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: appearInSearches,
                      onChanged: (bool value) {
                        setState(() {
                          appearInSearches = value;
                          // Add logic to toggle appear in searches here
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final Function(int, int?) switchPage;

  const LogoutButton({super.key, required this.switchPage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.5,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await FirebaseAuth.instance.signOut();
                      switchPage(5, null);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                    }
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Colors.white),
          foregroundColor: Colors.white,
        ),
        child: const Text('Log out'),
      ),
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final Function(int, int?) switchPage;

  const DeleteAccountButton({super.key, required this.switchPage});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // Only display delete button if the user is logged in
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.5,
      child: ElevatedButton(
        onPressed: () => _confirmDelete(context, switchPage),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
        ),
        child: const Text('Delete Account'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Function(int, int?) switchPage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? \n\nThis action cannot be undone, and you will need to wait 2 days before creating another one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, switchPage);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Future<void> _deleteAccount(BuildContext context, Function(int, int?) switchPage) async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     return;
  //   }

  //   try {
  //     // Delete user profile
  //     await FirebaseFirestore.instance
  //         .collection('profiles')
  //         .doc(user.uid)
  //         .delete();

  //     // Delete user ID and phone number
  //     final phone = user.phoneNumber;
  //     if (phone != null) {
  //       await FirebaseFirestore.instance.collection('user_ids').doc(phone).delete();
  //     } else {
  //       return;
  //     }

  //     // Clear all settings in SQLite
  //     await DatabaseHelper.instance.clearAllSettings();

  //     // Delete Firebase Auth user
  //     await user.delete();

  //     // Sign out and navigate to login page
  //     await FirebaseAuth.instance.signOut();
  //     switchPage(5, null);
  //   } catch (e) {
  //     // Handle re-authentication required error
  //     if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
  //       await FirebaseAuth.instance.signOut();
  //       switchPage(0, null);
  //     }
  //   }
  // }
  Future<void> _deleteAccount(BuildContext context, Function(int, int?) switchPage) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('No user signed in at ${DateTime.now()}');
    return;
  }

  try {
    // Fetch and delete profile images from Firebase Storage
    if (user.phoneNumber != null) {
      final docRef = FirebaseFirestore.instance.collection('user_ids').doc(user.phoneNumber);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data();
        final imageUrls = List<String>.from(data?['imageUrls'] ?? []);
        for (final url in imageUrls) {
          if (url.isNotEmpty) {
            try {
              debugPrint('Deleting image from Firebase Storage: $url at ${DateTime.now()}');
              final storageRef = FirebaseStorage.instance.refFromURL(url);
              await storageRef.delete();
              debugPrint('Image deleted successfully from Firebase Storage at ${DateTime.now()}');
            } catch (e) {
              debugPrint('Error deleting image from Firebase Storage: $e at ${DateTime.now()}');
              // Continue with deletion even if an image fails to delete
            }
          }
        }
        // Delete user profile from user_ids collection
        debugPrint('Deleting profile from user_ids for user ${user.uid} with phone number ${user.phoneNumber} at ${DateTime.now()}');
        await docRef.delete();
      }
    }

    // Delete user profile from profiles collection (if it exists)
    debugPrint('Deleting profile from profiles for user ${user.uid} at ${DateTime.now()}');
    await FirebaseFirestore.instance.collection('profiles').doc(user.uid).delete();

    // Clear all settings in SQLite
    debugPrint('Clearing SQLite settings for user ${user.uid} at ${DateTime.now()}');
    await DatabaseHelper.instance.clearAllSettings();

    // Delete Firebase Auth user
    debugPrint('Deleting Firebase Auth user ${user.uid} at ${DateTime.now()}');
    await user.delete();

    // Sign out and navigate to login page
    await FirebaseAuth.instance.signOut();
    debugPrint('User signed out and navigating to login page at ${DateTime.now()}');
    switchPage(5, null);
  } catch (e) {
    debugPrint('Error deleting account: $e at ${DateTime.now()}');
    if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
      await FirebaseAuth.instance.signOut();
      switchPage(0, null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }
}
} */