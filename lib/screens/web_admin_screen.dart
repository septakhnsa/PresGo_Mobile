import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class WebAdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const WebAdminScreen({
    super.key,
    required this.user,
  });

  @override
  State<WebAdminScreen> createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Base URL Laravel API
    final String baseUrl = AuthService.baseUrl.replaceAll('/api', '');
    final String token = AuthService.authToken ?? '';
    
    // Auto-login URL dengan melampirkan token sanctum sebagai query parameter
    // Laravel akan membaca token ini dan mengautentikasi session web admin.
    final String adminUrl = "$baseUrl/admin/auto-login?token=$token";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) async {
            final String url = request.url;
            debugPrint("WebView navigating to: $url");
            
            // Periksa jika URL mengarah ke Google Maps atau memiliki skema intent/non-http
            if (url.contains('google.com/maps') || 
                url.contains('maps.google.com') || 
                url.startsWith('intent://') || 
                url.startsWith('intent:') || 
                !url.startsWith('http')) {
              
              String launchUrlString = url;
              if (url.startsWith('intent://')) {
                // Konversi skema intent ke https agar bisa dibuka oleh aplikasi eksternal
                launchUrlString = url.replaceAll('intent://', 'https://');
                if (launchUrlString.contains('#Intent;')) {
                  launchUrlString = launchUrlString.split('#Intent;')[0];
                }
              }

              try {
                final Uri uri = Uri.parse(launchUrlString);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              } catch (e) {
                debugPrint("Gagal meluncurkan URL eksternal: $e");
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(adminUrl));
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        title: const Text(
          "Konfirmasi Keluar",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tosca),
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari panel admin dan aplikasi PresGo?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              AuthService.authToken = null; // Clear token
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Keluar",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String adminName = widget.user['name'] ?? 'Admin';
    final String adminNim = widget.user['nim'] ?? 'NIDN/NIM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: Container(
          color: AppColors.tosca,
          padding: const EdgeInsets.only(left: 20, right: 16, top: 12),
          child: SafeArea(
            child: Row(
              children: [
                // Avatar Admin
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldAccent.withOpacity(0.2),
                    border: Border.all(color: AppColors.goldAccent, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Data Admin
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Panel Admin ($adminNim)",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => _controller.reload(),
                ),
                // Exit / Logout Button
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  onPressed: _showLogoutConfirmation,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // The actual webview
          WebViewWidget(controller: _controller),
          
          // Progress bar at the top of the body
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                minHeight: 3.5,
              ),
            ),
        ],
      ),
    );
  }
}
