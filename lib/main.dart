import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/master_quest_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PoGetItApp());
}

class PoGetItApp extends StatelessWidget {
  const PoGetItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PoGetIt',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      // Named route for the Day 2 Master Quest Library.
      routes: {'/master-quests': (context) => const MasterQuestListScreen()},

      // Keep Firebase Authentication as the entry point.
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Handle authentication errors.
        if (authSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Authentication Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Authentication error: '
                  '${authSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // Wait for Firebase Authentication.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // User is not signed in.
        if (user == null) {
          return const WelcomeScreen();
        }

        // User is signed in.
        // Load the Firestore profile for this user.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(user.uid),
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            // Handle Firestore errors.
            if (profileSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Profile Error')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load profile: '
                      '${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            // Wait for the Firestore profile.
            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                !profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = profileSnapshot.data!.data();

            final onboardingCompleted = data?['onboardingCompleted'] == true;

            // Existing user with completed onboarding.
            if (onboardingCompleted) {
              return const HomeScreen();
            }

            // Signed in but onboarding is incomplete.
            return const OnboardingRequiredScreen();
          },
        );
      },
    );
  }
}

class OnboardingRequiredScreen extends StatelessWidget {
  const OnboardingRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Required')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 56,
                color: Colors.teal,
              ),

              const SizedBox(height: 16),

              const Text(
                'Onboarding Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your account is signed in, '
                'but onboarding is not complete.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
