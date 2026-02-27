import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. ล็อกอินด้วย Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Email Login Error: $e");
      rethrow;
    }
  }

  // 2. สมัครสมาชิกด้วย Email & Password
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // สร้างบัญชีใหม่
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // บันทึกชื่อที่กรอก
      await credential.user?.updateDisplayName(displayName);

      // reload เพื่อให้ currentUser อัปเดตทันที
      await credential.user?.reload();

      return credential;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow; // ส่ง Error ไปจัดการที่หน้า UI
    }
  }

  // 3. ล็อกอินด้วย Google (Web Popup)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    } catch (e) {
      print("Google Login Error: $e");
      return null;
    }
  }

  // 4. ล็อกอินด้วย GitHub (Web Popup)
  Future<UserCredential?> signInWithGitHub() async {
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      return await _auth.signInWithPopup(githubProvider);
    } catch (e) {
      print("GitHub Login Error: $e");
      return null;
    }
  }

  // 5. ล็อกอินด้วย Microsoft (Web Popup)
  Future<UserCredential?> signInWithMicrosoft() async {
    try {
      MicrosoftAuthProvider microsoftProvider = MicrosoftAuthProvider();
      microsoftProvider.setCustomParameters({'prompt': 'select_account'});
      return await _auth.signInWithPopup(microsoftProvider);
    } catch (e) {
      print("Microsoft Login Error: $e");
      return null;
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
