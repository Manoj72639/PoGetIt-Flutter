import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not signed in');
    }
    return user.uid;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> saveProfile({
    required String name,
    required List<String> interests,
    required String goals,
    required String activityLevel,
    required int preferredMinutes,
    required int weeklyTarget,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not signed in');
    }

    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'phone': user.phoneNumber,
      'interests': interests,
      'goals': goals.trim(),
      'activityLevel': activityLevel,
      'preferredMinutes': preferredMinutes,
      'weeklyTarget': weeklyTarget,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
