import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    return credential;
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      final UserCredential result = await _auth.signInWithPopup(googleProvider);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGitHub() async {
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');

      final UserCredential result = await _auth.signInWithPopup(githubProvider);

      final user = result.user;
      if (user == null) return null;

      final additionalInfo = result.additionalUserInfo;
      final profile = additionalInfo?.profile;

      // ดึงชื่อ: name → login (username) → displayName → fallback
      final githubName =
          profile?['name'] as String? ??
          profile?['login'] as String? ??
          user.displayName ??
          'GitHub User';

      // ดึง email: profile email → firebase email → fallback
      final githubEmail = profile?['email'] as String? ?? user.email ?? '';

      // ดึงรูป avatar จาก GitHub profile
      final githubPhoto =
          profile?['avatar_url'] as String? ?? user.photoURL ?? '';

      // อัปเดต displayName ใน Firebase Auth
      if (user.displayName == null ||
          user.displayName!.isEmpty ||
          user.displayName == 'GitHub User') {
        await user.updateDisplayName(githubName);
      }

      // บันทึกลง Firestore เพื่อเก็บ email กรณีที่ GitHub email เป็น private
      await _saveUserProfile(
        uid: user.uid,
        name: githubName,
        email: githubEmail,
        photoUrl: githubPhoto,
        provider: 'github',
      );

      // reload ให้ displayName มีผลทันที
      await user.reload();
      return _auth.currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithMicrosoft() async {
    try {
      final MicrosoftAuthProvider microsoftProvider = MicrosoftAuthProvider();
      microsoftProvider.addScope('email');
      microsoftProvider.addScope('openid');
      microsoftProvider.addScope('profile');
      final UserCredential result = await _auth.signInWithPopup(
        microsoftProvider,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String photoUrl,
    required String provider,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': name,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
