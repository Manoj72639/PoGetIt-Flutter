import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'screens/welcome_screen.dart';
import 'screens/master_quest_list_screen.dart';
import 'screens/pogetit_dashboard_screen.dart';
import 'theme/pogetit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      // Black and white theme.
      theme: PoGetItTheme.light,
      themeMode: ThemeMode.light,

      // Preserve the existing Master Quest Library route.
      routes: {'/master-quests': (context) => const MasterQuestListScreen()},

      // Firebase Authentication remains the entry point.
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
        if (authSnapshot.hasError) {
          return _ErrorScreen(
            title: 'Authentication Error',
            message: 'Authentication error: ${authSnapshot.error}',
          );
        }

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        // User has not signed in.
        if (user == null) {
          return const WelcomeScreen();
        }

        // User is authenticated.
        // Check onboarding completion in Firestore.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(user.uid),
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _ErrorScreen(
                title: 'Profile Error',
                message:
                    'Unable to load profile: '
                    '${profileSnapshot.error}',
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                !profileSnapshot.hasData) {
              return const _LoadingScreen();
            }

            final data = profileSnapshot.data!.data();

            final onboardingCompleted = data?['onboardingCompleted'] == true;

            if (onboardingCompleted) {
              // New dashboard:
              // Today | Explore | Journey | Profile
              return const PoGetItDashboardScreen();
            }

            return const OnboardingRequiredScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
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
                color: Colors.black,
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
