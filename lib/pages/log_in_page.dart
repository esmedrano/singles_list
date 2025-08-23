import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Custom TextInputFormatter for phone number formatting
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitsLength = digitsOnly.length;

    String newText = '';
    if (digitsLength > 0) {
      newText += '(${digitsOnly.substring(0, digitsLength >= 3 ? 3 : digitsLength)}';
      if (digitsLength > 3) {
        newText += ') ${digitsOnly.substring(3, digitsLength >= 6 ? 6 : digitsLength)}';
        if (digitsLength > 6) {
          newText += '-${digitsOnly.substring(6, digitsLength >= 10 ? 10 : digitsLength)}';
        }
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class LogIn extends StatefulWidget {
  final Function(int, [int?]) switchPage;
  final VoidCallback enterDemo;
  final VoidCallback createdAccount;
  final VoidCallback loggedInAccount;

  const LogIn({
    super.key, 
    required this.switchPage, 
    required this.enterDemo, 
    required this.createdAccount,
    required this.loggedInAccount
  });

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  @override
  void initState() {
    super.initState();
    // Connect to Firebase Emulator
    FirebaseAuth.instance.useAuthEmulator('192.168.1.153', 9099);
  }

  Future<void> _createAccount() async {
    // Prompt user to choose account creation method
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Account Creation Method', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'email_phone'),
              child: const Text('Email & Phone'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'google'),
              child: const Text('Google'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'apple'),
              child: const Text('Apple'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (method == null) return;

    switch (method) {
      case 'email_phone':
        await _createAccountWithEmailAndPhone();
        break;
      case 'google':
        await _createAccountWithGoogle();
        break;
      case 'apple':
        await _createAccountWithApple();
        break;
    }
  }

  Future<void> _createAccountWithEmailAndPhone() async {
    widget.createdAccount();
    try {
      // Step 1: Collect email, password, and password confirmation
      print('Collecting email and password');
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final confirmPasswordController = TextEditingController();

      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Account', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                } else if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                } else {
                  Navigator.pop(context, {'email': email, 'password': password});
                }
              },
              child: const Text('Next'),
            ),
          ],
        ),
      );

      if (credentials == null) {
        print('Email/password input cancelled');
        return; // Stay on login page
      }

      // Step 2: Create temporary user for email verification
      print('Creating temporary user for email verification');
      UserCredential? tempUserCredential;
      try {
        tempUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: credentials['email']!,
          password: credentials['password']!,
        );
        await tempUserCredential.user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
      } catch (e) {
        print('Failed to create temporary user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
        return; // Stay on login page
      }

      // Step 3: Prompt user to verify email and continue
      print('Showing email verification dialog');
      await Future.delayed(Duration.zero); // Yield to UI
      bool emailVerified = false;
      while (!emailVerified) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissal without action
          builder: (context) => AlertDialog(
            title: const Text('Verify Email', textAlign: TextAlign.center),
            content: const Text('Please verify your email by clicking the link sent to your inbox, then press Continue.'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await tempUserCredential!.user!.delete();
                    print('Temporary user deleted on cancel');
                  } catch (e) {
                    print('Failed to delete temporary user: $e');
                  }
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.currentUser!.reload();
                    Navigator.pop(context, FirebaseAuth.instance.currentUser!.emailVerified);
                  } catch (e) {
                    print('Error checking email verification: $e');
                    Navigator.pop(context, false);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (result == null || !result) {
          print('Email verification cancelled or failed');
          try {
            if (tempUserCredential!.user != null) {
              await tempUserCredential!.user!.delete();
              print('Temporary user deleted');
            }
          } catch (e) {
            print('Failed to delete temporary user: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verification not completed. Please try again.')),
          );
          return; // Stay on login page
        }
        emailVerified = result;
        print('Email verification check: $emailVerified');
      }
      print('Email verified');

      // Step 4: Delete temporary user
      try {
        await tempUserCredential!.user!.delete();
        print('Temporary user deleted');
      } catch (e) {
        print('Failed to delete temporary user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clean up temporary user: $e')),
        );
        return; // Stay on login page
      }

      // Step 5: Perform phone authentication
      print('Showing phone number dialog');
      await Future.delayed(Duration.zero); // Yield to UI
      final result = await _authWithPhone();
      if (result == null) {
        print('Phone verification cancelled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return; // Stay on login page
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;
      print('Phone authentication completed');

      // Step 6: Link email/password credential
      print('Linking email/password credential');
      final credential = EmailAuthProvider.credential(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      try {
        await user.linkWithCredential(credential);
        print('Email/password credential linked');
      } catch (e) {
        await user.delete(); // Clean up if linking fails
        print('Failed to link email: $e');
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This email is already linked to another account')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to link email: $e')),
          );
        }
        return; // Stay on login page
      }

      // Step 7: Store user data (Firestore rules enforce phone uniqueness)
      print('Storing user data');
      try {
        await _storeUserData(user, phone, credentials['email']!);
      } catch (e) {
        await user.delete(); // Clean up if Firestore write fails
        print('Failed to store user data: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to store user data: $e')),
          );
        }
        return; // Stay on login page
      }

      // Step 8: Navigate to main app
      print('Navigating to page 0');
      widget.switchPage(0);
    } catch (e) {
      print('Account creation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $e')),
      );
      await FirebaseAuth.instance.signOut(); // Clean up any auth state
      // Stay on login page
    }
  }

  Future<void> _createAccountWithGoogle() async {
    widget.createdAccount();
    try {
      // Step 1: Perform phone authentication
      final result = await _authWithPhone();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return;
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;

      // Step 2: Perform Google Sign-In
      await GoogleSignIn().signOut(); // Clear cached Google account
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled')),
        );
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, // Use only idToken for emulator
      );

      // Step 3: Link Google credential
      try {
        await user.linkWithCredential(credential);
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Google account is already linked to another account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 4: Store user data (Firestore rules enforce phone uniqueness)
      try {
        await _storeUserData(user, phone, googleUser.email ?? '');
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }
      // Step 5: Navigate to main app only after Google credential is linked
      widget.switchPage(0);
    } catch (e) {
      String errorMessage = 'Google account creation failed: $e';
      if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
        errorMessage = 'This Google account is already linked to another method. Please use a different Google account.';
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In failed due to a configuration error. Please ensure your Android/iOS Client IDs and SHA-1 fingerprints are correctly set.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      print(e);
    }
  }

  Future<void> _createAccountWithApple() async {
    widget.createdAccount();
    try {
      // Step 1: Perform phone authentication
      final result = await _authWithPhone();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return;
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;

      // Step 2: Perform Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Step 3: Link Apple credential
      try {
        await user.linkWithCredential(oauthCredential);
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Apple account is already linked to another account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 4: Store user data (Firestore rules enforce phone uniqueness)
      try {
        await _storeUserData(user, phone, appleCredential.email ?? '');
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }
      // Step 5: Navigate to main app only after Apple credential is linked
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple account creation failed: $e')),
      );
      print(e);
    }
  }

  Future<void> _signInWithEmail() async {
    widget.loggedInAccount();
    try {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign in with Email', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _resetPassword(emailController.text.trim()),
              child: const Text('Forgot Password'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  Navigator.pop(context, {'email': email, 'password': password});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both email and password')),
                  );
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      if (credentials == null) return;

      // Check if account exists with email
      try {
        final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(credentials['email']!);
        if (!signInMethods.contains('password')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found with this email. Please create an account.')),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking account: $e')),
        );
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Check if email provider is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to an email login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      // Verify phone number is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'phone')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to a phone number')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sign-in failed: $e')),
      );
      print(e);
    }
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }
    try {
      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (!signInMethods.contains('password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with this email')),
        );
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
      );
      print(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    widget.loggedInAccount();
    try {
      await GoogleSignIn().signOut(); // Clear cached account
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled

      // Check if account exists with Google
      final email = googleUser.email;
      try {
        final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (!signInMethods.contains('google.com')) {
          // Prompt to create account
          final shouldCreate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Account Found', textAlign: TextAlign.center),
              content: const Text('No account exists with this Google email. Would you like to create one?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          );
          if (shouldCreate != true) return;

          // Proceed to create account with Google
          await _createAccountWithGoogle();
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking account: $e')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, // Use only idToken for emulator
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Check if Google provider is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'google.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to a Google login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      // Verify phone number is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'phone')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to a phone number')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      String errorMessage = 'Google sign-in failed: $e';
      if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
        errorMessage = 'This Google account is not linked to this phone number. Please use the correct login method.';
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In failed due to a configuration error. Please ensure your Android/iOS Client IDs and SHA-1 fingerprints are correctly set.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      print(e);
    }
  }

  Future<void> _signInWithApple() async {
    widget.loggedInAccount();
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final email = appleCredential.email ?? '';
      if (email.isNotEmpty) {
        // Check if account exists with Apple
        try {
          final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
          if (!signInMethods.contains('apple.com')) {
            // Prompt to create account
            final shouldCreate = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('No Account Found', textAlign: TextAlign.center),
                content: const Text('No account exists with this Apple ID. Would you like to create one?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            );
            if (shouldCreate != true) return;

            // Proceed to create account with Apple
            await _createAccountWithApple();
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking account: $e')),
          );
          return;
        }
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      // Check if Apple provider is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'apple.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to an Apple login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      // Verify phone number is linked
      if (!userCredential.user!.providerData.any((info) => info.providerId == 'phone')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to a phone number')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: $e')),
      );
      print(e);
    }
  }

  Future<Map<String, dynamic>?> _authWithPhone() async {
    final phoneController = TextEditingController();

    final phone = await showDialog<String>(  // Get phone number entry from user
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number', textAlign: TextAlign.center,),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Allow only digits
            PhoneNumberFormatter(), // Apply phone number formatting
          ],
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '(000) 000-0000'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final input = phoneController.text.replaceAll(RegExp(r'\D'), '');
              // Validate US phone number: 10 digits
              if (RegExp(r'^\d{10}$').hasMatch(input)) {
                Navigator.pop(context, input);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 10-digit US phone number')),
                );
              }
            },
            child: const Text('Get OTP'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return null;

    // Auto-prepend +1 to convert to E.164 format
    final e164Phone = '+1$phone';

    final completer = Completer<Map<String, dynamic>?>(); // Allow nullable map

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164Phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-verification failed: $e')));
          completer.complete(null);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage = 'Invalid phone number format. Please use a 10-digit US number.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          case 'provider-not-enabled':
            errorMessage = 'Phone authentication is not enabled in Firebase Console.';
            break;
          default:
            errorMessage = 'Phone verification failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        completer.complete(null);
      },
      codeSent: (String verificationId, int? resendToken) async {
        final codeController = TextEditingController();
        final code = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter OTP'),
            content: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, codeController.text.trim()),
                child: const Text('Verify'),
              ),
            ],
          ),
        );

        if (code == null) {
          completer.complete(null);
          return;
        }

        final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);

        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
          completer.complete(null);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return await completer.future;
  }

  Future<void> _storeUserData(User user, String phone, String email) async {
    final firestore = FirebaseFirestore.instance;
    final data = {
      'created_at': Timestamp.now(),
      'uid': user.uid,
      'phone': phone,
      'email': email,
      'provider': user.providerData.isNotEmpty ? user.providerData.last.providerId : 'phone',
    };
    await firestore.collection('user_ids').doc(phone).set(data);
  }

  void _showDemoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
          content: const Text(
            'This is an app demo complete with fake accounts, '
            'so you can see what makes Integridate different '
            'from all the other dating apps '
            'without having to create an account.\n\n'
            'Would you like to enter the demo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.enterDemo();
              },
              child: const Text('Yes'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integridate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 90),
            TextButton(
              onPressed: _signInWithEmail,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign in with Email', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _signInWithGoogle,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _signInWithApple,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign in with Apple', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 90),
            TextButton(
              onPressed: _createAccount,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                //side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create Account', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _showDemoPopup,
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent),
              child: const Text('Try Demo'),
            ),
          ],
        ),
      ),
    );
  }
}

/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Custom TextInputFormatter for phone number formatting
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitsLength = digitsOnly.length;

    String newText = '';
    if (digitsLength > 0) {
      newText += '(${digitsOnly.substring(0, digitsLength >= 3 ? 3 : digitsLength)}';
      if (digitsLength > 3) {
        newText += ') ${digitsOnly.substring(3, digitsLength >= 6 ? 6 : digitsLength)}';
        if (digitsLength > 6) {
          newText += '-${digitsOnly.substring(6, digitsLength >= 10 ? 10 : digitsLength)}';
        }
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class LogIn extends StatefulWidget {
  final Function(int, [int?]) switchPage;
  final VoidCallback enterDemo;
  const LogIn({super.key, required this.switchPage, required this.enterDemo});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  @override
  void initState() {
    super.initState();
    // Connect to Firebase Emulator
    FirebaseAuth.instance.useAuthEmulator('192.168.1.153', 9099);
  }

  Future<void> _createAccount() async {
    // Prompt user to choose account creation method
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Account Creation Method', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'email_phone'),
              child: const Text('Email & Phone'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'google'),
              child: const Text('Google'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'apple'),
              child: const Text('Apple'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (method == null) return;

    switch (method) {
      case 'email_phone':
        await _createAccountWithEmailAndPhone();
        break;
      case 'google':
        await _createAccountWithGoogle();
        break;
      case 'apple':
        await _createAccountWithApple();
        break;
    }
  }

    Future<void> _createAccountWithEmailAndPhone() async {
    try {
      // Step 1: Collect email, password, and password confirmation
      print('Collecting email and password');
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final confirmPasswordController = TextEditingController();

      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Account', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                } else if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                } else {
                  Navigator.pop(context, {'email': email, 'password': password});
                }
              },
              child: const Text('Next'),
            ),
          ],
        ),
      );

      if (credentials == null) {
        print('Email/password input cancelled');
        return; // Stay on login page
      }

      // Step 2: Create temporary user for email verification
      print('Creating temporary user for email verification');
      UserCredential? tempUserCredential;
      try {
        tempUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: credentials['email']!,
          password: credentials['password']!,
        );
        await tempUserCredential.user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
      } catch (e) {
        print('Failed to create temporary user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
        return; // Stay on login page
      }

      // Step 3: Prompt user to verify email and continue
      print('Showing email verification dialog');
      await Future.delayed(Duration.zero); // Yield to UI
      bool emailVerified = false;
      while (!emailVerified) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissal without action
          builder: (context) => AlertDialog(
            title: const Text('Verify Email', textAlign: TextAlign.center),
            content: const Text('Please verify your email by clicking the link sent to your inbox, then press Continue or Retry.'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await tempUserCredential!.user!.delete();
                    print('Temporary user deleted on cancel');
                  } catch (e) {
                    print('Failed to delete temporary user: $e');
                  }
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.currentUser!.reload();
                    Navigator.pop(context, FirebaseAuth.instance.currentUser!.emailVerified);
                  } catch (e) {
                    print('Error checking email verification: $e');
                    Navigator.pop(context, false);
                  }
                },
                child: const Text('Continue'),
              ),
              // TextButton(
              //   onPressed: () async {
              //     try {
              //       await tempUserCredential!.user!.sendEmailVerification();
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Verification email resent. Please check your inbox.')),
              //       );
              //       Navigator.pop(context, false); // Stay in dialog to retry
              //     } catch (e) {
              //       print('Failed to resend verification email: $e');
              //       Navigator.pop(context, false);
              //     }
              //   },
              //   child: const Text('Retry'),
              // ),
            ],
          ),
        );

        if (result == null || !result) {
          print('Email verification cancelled or failed');
          try {
            if (tempUserCredential!.user != null) {
              await tempUserCredential!.user!.delete();
              print('Temporary user deleted');
            }
          } catch (e) {
            print('Failed to delete temporary user: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verification not completed. Please try again.')),
          );
          return; // Stay on login page
        }
        emailVerified = result;
        print('Email verification check: $emailVerified');
      }
      print('Email verified');

      // Step 4: Delete temporary user
      try {
        await tempUserCredential!.user!.delete();
        print('Temporary user deleted');
      } catch (e) {
        print('Failed to delete temporary user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clean up temporary user: $e')),
        );
        return; // Stay on login page
      }

      // Step 5: Perform phone authentication
      print('Showing phone number dialog');
      await Future.delayed(Duration.zero); // Yield to UI
      final result = await _authWithPhone();
      if (result == null) {
        print('Phone verification cancelled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return; // Stay on login page
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;
      print('Phone authentication completed');

      // Step 6: Link email/password credential
      print('Linking email/password credential');
      final credential = EmailAuthProvider.credential(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      try {
        await user.linkWithCredential(credential);
        print('Email/password credential linked');
      } catch (e) {
        await user.delete(); // Clean up if linking fails
        print('Failed to link email: $e');
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This email is already linked to another account')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to link email: $e')),
          );
        }
        return; // Stay on login page
      }

      // Step 7: Store user data (Firestore rules enforce phone uniqueness)
      print('Storing user data');
      try {
        await _storeUserData(user, phone, credentials['email']!);
      } catch (e) {
        await user.delete(); // Clean up if Firestore write fails
        print('Failed to store user data: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to store user data: $e')),
          );
        }
        return; // Stay on login page
      }

      // Step 8: Navigate to main app
      print('Navigating to page 0');
      widget.switchPage(0);
    } catch (e) {
      print('Account creation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $e')),
      );
      await FirebaseAuth.instance.signOut(); // Clean up any auth state
      // Stay on login page
    }
  }

  Future<void> _createAccountWithGoogle() async {
    try {
      // Step 1: Perform phone authentication
      final result = await _authWithPhone();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return;
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;

      // Step 2: Perform Google Sign-In
      await GoogleSignIn().signOut(); // Clear cached Google account
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled')),
        );
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, // Use only idToken for emulator
      );

      // Step 3: Link Google credential
      try {
        await user.linkWithCredential(credential) ;
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Google account is already linked to another account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 4: Store user data (Firestore rules enforce phone uniqueness)
      try {
        await _storeUserData(user, phone, googleUser.email ?? '');
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 5: Navigate to main app only after Google credential is linked
      widget.switchPage(0);
    } catch (e) {
      String errorMessage = 'Google account creation failed: $e';
      if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
        errorMessage = 'This Google account is already linked to another method. Please use a different Google account.';
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In failed due to a configuration error. Please ensure your Android/iOS Client IDs and SHA-1 fingerprints are correctly set.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      print(e);
    }
  }

  Future<void> _createAccountWithApple() async {
    try {
      // Step 1: Perform phone authentication
      final result = await _authWithPhone();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification cancelled')),
        );
        return;
      }
      final phone = result['phone'] as String;
      final user = result['user'] as User;

      // Step 2: Perform Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Step 3: Link Apple credential
      try {
        await user.linkWithCredential(oauthCredential);
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This Apple account is already linked to another account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 4: Store user data (Firestore rules enforce phone uniqueness)
      try {
        await _storeUserData(user, phone, appleCredential.email ?? '');
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already associated with an account')),
          );
          await user.delete();
          return;
        }
        throw e;
      }

      // Step 5: Navigate to main app only after Apple credential is linked
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple account creation failed: $e')),
      );
      print(e);
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      final credentials = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign in with Email', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  Navigator.pop(context, {'email': email, 'password': password});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both email and password')),
                  );
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      if (credentials == null) return;

      final credential = EmailAuthProvider.credential(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Check if email provider is linked
      if (!userCredential.user!.providerData
          .any((info) => info.providerId == 'password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to an email login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sign-in failed: $e')),
      );
      print(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut(); // Clear cached account
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, // Use only idToken for emulator
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Check if Google provider is linked
      if (!userCredential.user!.providerData
          .any((info) => info.providerId == 'google.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to a Google login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      String errorMessage = 'Google sign-in failed: $e';
      if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
        errorMessage = 'This Google account is not linked to this phone number. Please use the correct login method.';
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In failed due to a configuration error. Please ensure your Android/iOS Client IDs and SHA-1 fingerprints are correctly set.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      print(e);
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      // Check if Apple provider is linked
      if (!userCredential.user!.providerData
          .any((info) => info.providerId == 'apple.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not linked to an Apple login')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }
      widget.switchPage(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: $e')),
      );
      print(e);
    }
  }

  Future<Map<String, dynamic>?> _authWithPhone() async {
    final phoneController = TextEditingController();

    final phone = await showDialog<String>(  // Get phone number entry from user
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number', textAlign: TextAlign.center,),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Allow only digits
            PhoneNumberFormatter(), // Apply phone number formatting
          ],
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '(000) 000-0000'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final input = phoneController.text.replaceAll(RegExp(r'\D'), '');
              // Validate US phone number: 10 digits
              if (RegExp(r'^\d{10}$').hasMatch(input)) {
                Navigator.pop(context, input);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 10-digit US phone number')),
                );
              }
            },
            child: const Text('Get OTP'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return null;

    // Auto-prepend +1 to convert to E.164 format
    final e164Phone = '+1$phone';

    final completer = Completer<Map<String, dynamic>?>(); // Allow nullable map

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164Phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auto-verification failed: $e')));
          completer.complete(null);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage = 'Invalid phone number format. Please use a 10-digit US number.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          case 'provider-not-enabled':
            errorMessage = 'Phone authentication is not enabled in Firebase Console.';
            break;
          default:
            errorMessage = 'Phone verification failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        completer.complete(null);
      },
      codeSent: (String verificationId, int? resendToken) async {
        final codeController = TextEditingController();
        final code = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter OTP'),
            content: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, codeController.text.trim()),
                child: const Text('Verify'),
              ),
            ],
          ),
        );

        if (code == null) {
          completer.complete(null);
          return;
        }

        final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);

        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete({'user': userCredential.user, 'phone': e164Phone});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
          completer.complete(null);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return await completer.future;
  }

  Future<void> _storeUserData(User user, String phone, String email) async {
    final firestore = FirebaseFirestore.instance;
    final data = {
      'created_at': Timestamp.now(),
      'uid': user.uid,
      'phone': phone,
      'email': email,
      'provider': user.providerData.isNotEmpty ? user.providerData.last.providerId : 'phone',
    };
    await firestore.collection('user_ids').doc(phone).set(data);
  }

  void _showDemoPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Integridate!', textAlign: TextAlign.center),
          content: const Text(
            'This is an app demo complete with fake accounts, '
            'so you can see what makes Integridate different '
            'from all the other dating apps '
            'without having to create an account.\n\n'
            'Would you like to enter the demo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.enterDemo();
              },
              child: const Text('Yes'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integridate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _createAccount,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Create Account', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _signInWithEmail,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign in with Email', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _signInWithGoogle,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _signInWithApple,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Sign in with Apple', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _showDemoPopup,
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.transparent),
              child: const Text('Try Demo'),
            ),
          ],
        ),
      ),
    );
  }
} */