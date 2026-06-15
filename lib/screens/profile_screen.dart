import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../services/jadwal_service.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  final String _profileAvatarUrl =
      "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop";
  
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        title: const Text("Konfirmasi Keluar"),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari aplikasi PresGo?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redAlpa,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              JadwalService.instance.clearData();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Clear entire screen stack
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
    print("PROFILE USER = $user");
    
    return Scaffold(
      backgroundColor: Colors.white, // Standard white background
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Curved Yellow Header
                ClipPath(
                  clipper: ProfileHeaderClipper(),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFACC15), // Yellow color from Figma
                    padding: const EdgeInsets.only(top: 20, bottom: 60),
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: DecorationImage(
                              image: NetworkImage(_profileAvatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name
                        Text(
                          user['name'] ?? '-',
                          style: TextStyle(
                            color: AppColors.toscaDark,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // NIM
                        Text(
                          user['nim'] ?? '-',
                          style: TextStyle(
                            color: AppColors.toscaDark.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Program Studi Affiliation
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            "Mahasiswa Program Studi S1 Teknik\nInformatika STMIK Widya Utama",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.toscaDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      // Data Mahasiswa Section
                      const Text(
                        "Data Mahasiswa",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Instansi", "STMIK Widya Utama Purwokerto"),
                      _buildInfoRow("Prodi", "S1 Teknik Informatika"),
                      _buildInfoRow("Angkatan", "2023"),
                      _buildInfoRow("Kelas", "Reguler Pagi A 6.1"),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 2),
                      const SizedBox(height: 16),
                      
                      // Pusat Bantuan Section
                      const Text(
                        "Pusat Bantuan",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Bantuan", "", showAction: false),
                      _buildInfoRow("Laporkan Masalah", "", showAction: false),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 2),
                      const SizedBox(height: 16),
                      
                      // Pengaturan Section
                      const Text(
                        "Pengaturan",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageRow(),
                      _buildInfoRow("Atur Ulang Kata Sandi", "**********"),
                      _buildInfoRow("App Version", "v.2.3.0"),
                      
                      const SizedBox(height: 100), // Padding for logout button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool showAction = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multiline
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showAction) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Bahasa",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Indonesia",
                  style: TextStyle(
                    color: AppColors.greenHadir, // Highlighted language
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "English",
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for curved yellow profile header
class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    // Smooth quadratic curve from bottom left to bottom right with center dip
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
