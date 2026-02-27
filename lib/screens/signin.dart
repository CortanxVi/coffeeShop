// ==========================================
// lib/screens/signin.dart
// ==========================================
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

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLoginSuccess(dynamic user) {
    if (user != null) {
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
      if (!mounted) return; // ← เพิ่มตรงนี้
      _handleLoginSuccess(user);
    } catch (e) {
      if (!mounted) return; // ← เพิ่มตรงนี้
      String msg = 'เข้าสู่ระบบไม่สำเร็จ';
      if (e.toString().contains('user-not-found')) msg = 'ไม่พบบัญชีนี้ในระบบ';
      if (e.toString().contains('wrong-password')) msg = 'รหัสผ่านไม่ถูกต้อง';
      if (e.toString().contains('invalid-email'))
        msg = 'รูปแบบ Email ไม่ถูกต้อง';
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
    setState(() {});
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
    final photoUrl = user.photoURL;
    final displayName = user.displayName ?? 'ไม่ระบุชื่อ';
    final email = user.email ?? '-';

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
        // Avatar
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
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
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
              _infoRow(
                user.emailVerified
                    ? Icons.verified
                    : Icons.warning_amber_outlined,
                'Email',
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

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: AppTheme.inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 14),

        // Password
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

        // ปุ่มเข้าสู่ระบบ
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

        // ปุ่มสมัครสมาชิก
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
              setState(() {}); // refresh หลังกลับมา
            },
          ),
        ),

        const SizedBox(height: 24),
        AppTheme.orDivider(),
        const SizedBox(height: 20),

        // Social buttons
        AppTheme.socialButton(
          label: 'Google',
          icon: Icons.g_mobiledata,
          color: Colors.red,
          onPressed: () async {
            final user = await _authService.signInWithGoogle();
            if (!mounted) return; // ← เพิ่มตรงนี้
            _handleLoginSuccess(user);
          },
        ),
        const SizedBox(height: 10),
        AppTheme.socialButton(
          label: 'GitHub',
          icon: Icons.code,
          color: Colors.black87,
          onPressed: () async {
            final user = await _authService.signInWithGitHub();
            _handleLoginSuccess(user);
          },
        ),
        const SizedBox(height: 10),
        AppTheme.socialButton(
          label: 'Microsoft',
          icon: Icons.window,
          color: Colors.blue.shade700,
          onPressed: () async {
            final user = await _authService.signInWithMicrosoft();
            _handleLoginSuccess(user);
          },
        ),
      ],
    );
  }
}
