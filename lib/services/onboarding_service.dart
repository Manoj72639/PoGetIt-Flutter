import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/onboarding_answers.dart';

class OnboardingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveAnswers(User user, OnboardingAnswers answers) async {
    await _db.collection('users').doc(user.uid).set({
      ...answers.toMap(),
      'email': user.email,
      'phone': user.phoneNumber,
      'onboardingCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> hasCompletedOnboarding(User user) async {
    final document = await _db.collection('users').doc(user.uid).get();

    return document.exists && document.data()?['onboardingCompleted'] == true;
  }
}
