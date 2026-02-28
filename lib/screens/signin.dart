import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth_service.dart';
import '../theme/appTheme.dart';
import 'signup.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ── เพิ่มตรงนี้: เก็บ GitHub profile จาก Firestore ──
  Map<String, dynamic>? _githubProfile;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // ── เพิ่มตรงนี้: โหลด profile เมื่อ widget สร้าง ──
  @override
  void initState() {
    super.initState();
    _loadExtraProfile();
  }

  // โหลดข้อมูล GitHub จาก Firestore
  // (กรณี email เป็น private หรือ displayName ไม่ได้ตั้งใน GitHub)
  Future<void> _loadExtraProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isGitHub = user.providerData.any((p) => p.providerId == 'github.com');
    if (!isGitHub) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _githubProfile = doc.data());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _parseSocialError(String error) {
    if (error.contains('popup-closed-by-user')) return 'ยกเลิกการเข้าสู่ระบบ';
    if (error.contains('account-exists-with-different-credential')) {
      return 'Email นี้ถูกใช้กับวิธีล็อกอินอื่นแล้ว';
    }
    if (error.contains('network-request-failed')) {
      return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
    }
    if (error.contains('cancelled-popup-request')) {
      return 'มี popup เปิดอยู่แล้ว กรุณารอสักครู่';
    }
    if (error.contains('unauthorized-domain')) {
      return 'Domain นี้ยังไม่ได้รับอนุญาต กรุณาตั้งค่าใน Firebase Console';
    }
    if (error.contains('Configuration not found')) {
      return 'GitHub Login ยังไม่ได้ตั้งค่าใน Firebase Console';
    }
    return 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่';
  }

  void _handleLoginSuccess(dynamic user) async {
    if (user != null) {
      // โหลด GitHub profile หลัง login สำเร็จด้วย
      await _loadExtraProfile();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยินดีต้อนรับ ${_currentUser?.displayName ?? _currentUser?.email ?? ''}',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอก Email และรหัสผ่าน'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      _handleLoginSuccess(user);
    } catch (e) {
      if (!mounted) return;
      String msg = 'เข้าสู่ระบบไม่สำเร็จ';
      if (e.toString().contains('user-not-found')) msg = 'ไม่พบบัญชีนี้ในระบบ';
      if (e.toString().contains('wrong-password')) msg = 'รหัสผ่านไม่ถูกต้อง';
      if (e.toString().contains('invalid-email')) {
        msg = 'รูปแบบ Email ไม่ถูกต้อง';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    // เคลียร์ GitHub profile ตอน logout ด้วย
    setState(() => _githubProfile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('บัญชีผู้ใช้')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: _currentUser != null
                ? _buildProfileCard(_currentUser!)
                : _buildSignInForm(),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // PROFILE CARD
  // ──────────────────────────────────────────
  Widget _buildProfileCard(User user) {
    // ── ดึง photoUrl: Firebase → providerData → Firestore (GitHub) ──
    String? photoUrl = user.photoURL;

    if (photoUrl == null || photoUrl.isEmpty) {
      for (final p in user.providerData) {
        if (p.photoURL != null && p.photoURL!.isNotEmpty) {
          photoUrl = p.photoURL;
          break;
        }
      }
    }

    // GitHub fallback จาก Firestore
    if ((photoUrl == null || photoUrl.isEmpty) && _githubProfile != null) {
      photoUrl = _githubProfile!['photoUrl'] as String?;
    }

    // ── ดึง displayName: Firebase → Firestore (GitHub) ──
    final displayName =
        (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : (_githubProfile?['displayName'] as String? ?? 'ไม่ระบุชื่อ');

    // ── ดึง email: Firebase → Firestore (GitHub private email) ──
    final email = (user.email != null && user.email!.isNotEmpty)
        ? user.email!
        : (_githubProfile?['email'] as String? ?? 'ไม่พบ Email');

    // ── ระบุ provider ──
    String provider = 'Email / Password';
    Color providerColor = AppTheme.textMedium;
    IconData providerIcon = Icons.email_outlined;

    for (final p in user.providerData) {
      if (p.providerId == 'google.com') {
        provider = 'Google';
        providerColor = Colors.red;
        providerIcon = Icons.g_mobiledata;
      } else if (p.providerId == 'github.com') {
        provider = 'GitHub';
        providerColor = Colors.black87;
        providerIcon = Icons.code;
      } else if (p.providerId == 'microsoft.com') {
        provider = 'Microsoft';
        providerColor = Colors.blue.shade700;
        providerIcon = Icons.window;
      }
    }

    return Column(
      children: [
        const SizedBox(height: 8),

        // ── Avatar ──
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.accentLight,
                child: _buildAvatar(photoUrl, displayName, radius: 52),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(displayName, style: AppTheme.headingMedium),
        const SizedBox(height: 4),
        Text(email, style: AppTheme.bodyMedium),
        const SizedBox(height: 10),

        // Provider badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: providerColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: providerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(providerIcon, size: 14, color: providerColor),
              const SizedBox(width: 6),
              Text(
                'เข้าสู่ระบบด้วย $provider',
                style: TextStyle(
                  color: providerColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info Card
        Container(
          width: double.infinity,
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoRow(Icons.badge_outlined, 'UID', user.uid),
              const Divider(height: 20),
              // ── แสดง email จากตัวแปรที่รวม Firestore แล้ว ──
              _infoRow(Icons.email_outlined, 'Email', email),
              const Divider(height: 20),
              _infoRow(
                user.emailVerified
                    ? Icons.verified
                    : Icons.warning_amber_outlined,
                'Email verified',
                user.emailVerified ? 'ยืนยันแล้ว ✓' : 'ยังไม่ยืนยัน',
                valueColor: user.emailVerified
                    ? AppTheme.success
                    : AppTheme.error,
              ),
              const Divider(height: 20),
              _infoRow(Icons.login_outlined, 'วิธีเข้าสู่ระบบ', provider),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: AppTheme.outlineButton(AppTheme.error),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('ออกจากระบบ'),
            onPressed: _signOut,
          ),
        ),
      ],
    );
  }

  // ── Avatar Widget ──
  Widget _buildAvatar(
    String? photoUrl,
    String displayName, {
    required double radius,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              _avatarFallback(displayName, radius),
        ),
      );
    }
    return _avatarFallback(displayName, radius);
  }

  Widget _avatarFallback(String displayName, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: AppTheme.accentLight,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryLight),
        const SizedBox(width: 10),
        Text('$label: ', style: AppTheme.labelStyle),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // SIGN IN FORM
  // ──────────────────────────────────────────
  Widget _buildSignInForm() {
    return Column(
      children: [
        AppTheme.cafeHeader(subtitle: 'ยินดีต้อนรับครับนายท่าน ☕'),
        const SizedBox(height: 32),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: AppTheme.inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: AppTheme.inputDecoration(
            label: 'รหัสผ่าน',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textLight,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('เข้าสู่ระบบ'),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: AppTheme.outlineButton(AppTheme.primary),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('สมัครสมาชิกใหม่'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 24),
        AppTheme.orDivider(),
        const SizedBox(height: 20),

        AppTheme.socialButton(
          label: 'Google',
          icon: Icons.g_mobiledata,
          color: Colors.red,
          onPressed: () async {
            try {
              final user = await _authService.signInWithGoogle();
              if (!mounted) return;
              _handleLoginSuccess(user);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_parseSocialError(e.toString())),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        AppTheme.socialButton(
          label: 'GitHub',
          icon: Icons.code,
          color: Colors.black87,
          onPressed: () async {
            try {
              final user = await _authService.signInWithGitHub();
              if (!mounted) return;
              _handleLoginSuccess(user);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_parseSocialError(e.toString())),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        AppTheme.socialButton(
          label: 'Microsoft',
          icon: Icons.window,
          color: Colors.blue.shade700,
          onPressed: () async {
            try {
              final user = await _authService.signInWithMicrosoft();
              if (!mounted) return;
              _handleLoginSuccess(user);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_parseSocialError(e.toString())),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
