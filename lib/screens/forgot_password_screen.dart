import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

// TODO: Ganti URL ini dengan base URL backend temanmu nanti
const String BASE_URL = "https://api-backend-temanmu.com/api";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Forgot, 1: OTP, 2: Reset, 3: Success
  bool _isLoading = false; // State untuk loading indicator

  // Step 1 Controllers
  final TextEditingController _emailController = TextEditingController();

  // Step 2 OTP Fields
  final List<TextEditingController> _otpControllers = List.generate(
    5,
    (i) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(5, (i) => FocusNode());

  // Step 3 Reset Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill "5" and "9" in the first two OTP boxes exactly like Figma
    _otpControllers[0].text = "5";
    _otpControllers[1].text = "9";
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ✅ FUNGSI VALIDASI EMAIL (BARU!)
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ==========================================
  // BACKEND LOGIC: API REQUESTS
  // ==========================================

  // 1. Request OTP (Step 1 -> Step 2)
  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear pre-filled OTP biar user bisa masukin OTP beneran dari email
        for (var c in _otpControllers) c.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kode OTP berhasil dikirim ke email!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        _nextStep();
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Gagal mengirim OTP"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Verify OTP (Step 2 -> Step 3)
  Future<void> _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP harus 5 digit!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim(), 'otp': otp}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP berhasil diverifikasi!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        _nextStep();
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Kode OTP salah"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Reset Password (Step 3 -> Step 4)
  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpControllers.map((c) => c.text).join(),
          'new_password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password berhasil diperbarui!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        _nextStep();
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Gagal memperbarui password"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.tosca,
            size: 20,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          _currentStep == 0
              ? "Forgot Password"
              : _currentStep == 1
              ? "OTP Verification"
              : _currentStep == 2
              ? "Confirm New Password"
              : "Password Verify",
          style: const TextStyle(
            color: AppColors.tosca,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Build appropriate UI depending on current step
              if (_currentStep == 0) _buildForgotStep(),
              if (_currentStep == 1) _buildOTPStep(),
              if (_currentStep == 2) _buildResetStep(),
              if (_currentStep == 3) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1: Lupa Password? (Request Email)
  Widget _buildForgotStep() {
    return Column(
      children: [
        // Green Lock Icon Circle
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Light green tint
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tosca.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: const Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.tosca,
                  size: 46,
                ),
                Positioned(
                  top: 32,
                  child: Text(
                    "?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Text Titles
        const Text(
          "Lupa Password?",
          style: TextStyle(
            color: AppColors.tosca,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Masukkan email aktif Anda.\nAkan kami kirimkan kode OTP untuk verifikasi.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),

        // Input Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Email",
            style: TextStyle(
              color: AppColors.textDark.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1.2),
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              hintText: "email@mhs.kampus.ac.id",
              hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Submit Button - ✅ UDAH ADA VALIDASI EMAIL
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  final email = _emailController.text.trim();

                  // Validasi 1: Cek kosong
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email tidak boleh kosong!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validasi 2: Cek format email (BARU!)
                  if (!_isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Format email tidak valid!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  _requestOtp();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tosca, // Green button
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 1.5,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Kirim Kode OTP",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }

  // STEP 2: Verifikasi OTP
  Widget _buildOTPStep() {
    return Column(
      children: [
        // Green Mail Circle Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tosca.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.tosca,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Titles
        const Text(
          "Verifikasi OTP",
          style: TextStyle(
            color: AppColors.tosca,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text:
                    "Silakan Cek Email Anda.\nKode OTP 5 digit telah dikirim ke\n",
              ),
              TextSpan(
                text: _emailController.text.isNotEmpty
                    ? _emailController.text
                    : "sta***@mhs.kampus.ac.id",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // 5 OTP Boxes Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            return SizedBox(
              width: 50,
              height: 60,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.tosca,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: "",
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.black26,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.tosca,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 4) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 48),

        // Action Button: Kirim Kode OTP (Verifikasi)
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tosca, // Green button
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 1.5,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Kirim Kode OTP", // Teks dibiarkan sama sesuai desain asli
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Resend Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Belum terima kode? ",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : _requestOtp, // Panggil lagi API request OTP
              child: const Text(
                "Kirim ulang",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: Perbarui Password
  Widget _buildResetStep() {
    return Column(
      children: [
        // Green Reset Circle Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tosca.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.vpn_key_outlined,
              color: AppColors.tosca,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Titles
        const Text(
          "Perbarui Password",
          style: TextStyle(
            color: AppColors.tosca,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Password minimal 8 karakter",
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 32),

        // Password Baru Form
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Password Baru",
            style: TextStyle(
              color: AppColors.textDark.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1.2),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword1,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: "Password Baru",
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword1 = !_obscurePassword1;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Konfirmasi Password Form
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Konfirmasi Password",
            style: TextStyle(
              color: AppColors.textDark.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1.2),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword2,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: "Konfirmasi Password",
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword2 = !_obscurePassword2;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Strength / Waiting segments indicator matching Figma screen exactly!
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Gold segment
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            // Green segment
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greenHadir,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            // Grey segment
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // "waiting.." status label
            const Text(
              "waiting..",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Action Button: Simpan Password Baru
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_passwordController.text.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password minimal harus 8 karakter!"),
                      ),
                    );
                    return;
                  }
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Konfirmasi password tidak cocok!"),
                      ),
                    );
                    return;
                  }
                  _resetPassword();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tosca, // Green button
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 1.5,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Simpan Password Baru",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }

  // STEP 4: Password Diperbarui! (Success Screen)
  Widget _buildSuccessStep() {
    return Column(
      children: [
        // Green Success Circle Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tosca.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.tosca,
              size: 54,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Titles
        const Text(
          "Password Diperbarui!",
          style: TextStyle(
            color: AppColors.tosca,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Password anda telah berhasil diperbarui.\nSilahkan login dengan password baru.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),

        // Light Green Announcement Card Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Soft green background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greenHadir.withOpacity(0.2)),
          ),
          child: const Text(
            "Notifikasi Perubahan Password telah dikirim ke email anda",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.tosca,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Action Button: Kembali ke Login
        ElevatedButton(
          onPressed: () {
            // Pop back to the Login screen
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(
              255,
              10,
              128,
              57,
            ), // Green button
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 1.5,
          ),
          child: const Text(
            "Kembali ke Login",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
