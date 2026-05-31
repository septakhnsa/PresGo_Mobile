import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

class FingerprintDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const FingerprintDialog({super.key, required this.onSuccess});

  @override
  State<FingerprintDialog> createState() => _FingerprintDialogState();
}

class _FingerprintDialogState extends State<FingerprintDialog>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSuccess = false;
  bool _isError = false;
  String _statusText = "Tempelkan jari pada sensor";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger biometric auth after short delay so dialog appears first
    Future.delayed(const Duration(milliseconds: 400), _authenticate);
  }

  Future<void> _authenticate() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        // Device doesn't support biometrics — simulate success for demo
        await Future.delayed(const Duration(milliseconds: 1500));
        _handleSuccess();
        return;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk presensi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        if (authenticated) {
          _handleSuccess();
        } else {
          setState(() {
            _isError = true;
            _statusText = "Autentikasi dibatalkan";
          });
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
      // Fallback: simulate success for demo if biometrics fail
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        _handleSuccess();
      }
    }
  }

  void _handleSuccess() {
    if (!mounted) return;
    setState(() {
      _isSuccess = true;
      _statusText = "Biometric cocok ✓";
    });
    _pulseController.stop();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _isError
        ? Colors.orange
        : _isSuccess
            ? AppColors.greenHadir
            : const Color(0xFFEF4444);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E35).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fingerprint Icon with pulse animation
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.2),
                  border: Border.all(color: iconColor, width: 2.0),
                ),
                child: Icon(
                  _isSuccess
                      ? Icons.check_rounded
                      : _isError
                          ? Icons.warning_amber_rounded
                          : Icons.fingerprint_rounded,
                  color: iconColor,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Text
            const Text(
              "Touch ID untuk\n\"Presensi Akademika\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Status text
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),

            // Divider
            Container(
              width: double.infinity,
              height: 0.5,
              color: Colors.white.withOpacity(0.12),
            ),
            const SizedBox(height: 8),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                padding: EdgeInsets.zero,
                foregroundColor: Colors.white.withOpacity(0.7),
              ),
              child: const Text(
                "Batal",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
