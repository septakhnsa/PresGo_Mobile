import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_card.dart';
import '../widgets/fingerprint_dialog.dart';
import 'main_navigation.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
  if (_nimController.text.trim().isEmpty ||
      _passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text("NIM dan Password tidak boleh kosong!")),
          ],
        ),
        backgroundColor: AppColors.redAlpa,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  final result = await AuthService.login(
    _nimController.text.trim(),
    _passwordController.text.trim(),
  );

  setState(() => _isLoading = false);

  if (result['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text("Login Berhasil!")),
          ],
        ),
        backgroundColor: AppColors.greenHadir,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    if (result['user']['role'] == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message'] ?? 'Login gagal'),
      backgroundColor: Colors.red,
    ),
  );
}
  void _navigateToDashboard() {
   Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => const MainNavigation(),
    ),
  );
}
  void _showBiometricDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => FingerprintDialog(
      onSuccess: () {
        // Pre-fill simulated credential
        Navigator.of(dialogContext).pushReplacement(
          MaterialPageRoute(
            builder: (routeContext) => MainNavigation(),
          ),
        );
      },
    ),
  );
}

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tosca, // Deep green background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // 1. Logo Card
                const LogoCard(size: 85),
                const SizedBox(height: 16),

                // 2. Brand Headers
                const Text(
                  "Presensi Online",
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Akademika Mahasiswa",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // 3. NIM Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "NIM",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _nimController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: "ketik disini..",
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "ketik disini..",
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.black38,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ingat saya
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: AppColors.goldAccent,
                              checkColor: AppColors.tosca,
                              side: const BorderSide(color: Colors.white70, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Ingat saya",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Forgot password link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 6. Action Row: LOGIN Button + Fingerprint Button
                Row(
                  children: [
                    // Gold LOGIN button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: AppColors.tosca,
                          elevation: 2,
                          shadowColor: Colors.black26,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.tosca),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Fingerprint biometric button
                    GestureDetector(
                      onTap: _showBiometricDialog,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.tosca,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldAccent,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.goldAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 7. Footer: Navigation to Register screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun? ",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
