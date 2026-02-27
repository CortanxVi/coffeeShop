import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ฟังก์ชันช่วยจัดการเมื่อล็อกอินสำเร็จ
  void _handleLoginSuccess(var user) {
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ยินดีต้อนรับ: ${user.user?.email}")),
      );
      // Navigator.pushReplacementNamed(context, '/home'); // ไปหน้าหลัก
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เข้าสู่ระบบ")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // จำกัดความกว้างหน้าเว็บ
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // ช่องกรอก Email
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // ช่องกรอก Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // ปุ่มล็อกอินปกติ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        var user = await _authService.signInWithEmail(
                          _emailController.text,
                          _passwordController.text,
                        );
                        _handleLoginSuccess(user);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Login Failed: ${e.toString()}"),
                          ),
                        );
                      }
                    },
                    child: const Text("เข้าสู่ระบบ"),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(), // เส้นคั่น
                ),

                // ปุ่ม Social Login
                _socialButton(
                  "Google",
                  Colors.red,
                  _authService.signInWithGoogle,
                ),
                const SizedBox(height: 10),
                _socialButton(
                  "GitHub",
                  Colors.black,
                  _authService.signInWithGitHub,
                ),
                const SizedBox(height: 10),
                _socialButton(
                  "Microsoft",
                  Colors.blue.shade700,
                  _authService.signInWithMicrosoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ตัวช่วยสร้างปุ่มโซเชียล
  Widget _socialButton(String label, Color color, Future Function() loginFunc) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
        onPressed: () async {
          var user = await loginFunc();
          _handleLoginSuccess(user);
        },
        child: Text("Sign in with $label", style: TextStyle(color: color)),
      ),
    );
  }
}
