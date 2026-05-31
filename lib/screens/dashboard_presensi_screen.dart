import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/jadwal_model.dart';
import '../models/presensi_model.dart';
import '../services/jadwal_service.dart';
import 'presensi_screen.dart';

class DashboardPresensiScreen extends StatefulWidget {
  const DashboardPresensiScreen({super.key});

  @override
  State<DashboardPresensiScreen> createState() => _DashboardPresensiScreenState();
}

class _DashboardPresensiScreenState extends State<DashboardPresensiScreen> {
  final String _profileAvatarUrl = "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop";

  @override
  Widget build(BuildContext context) {
    final jadwalList = JadwalService.instance.getJadwalHariIni();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Off-white/grey background exactly like Figma
      appBar: AppBar(
        backgroundColor: AppColors.tosca,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Dashboard Presensi",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile header card inside Dashboard (Solid Deep Green Card)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.tosca, // Deep green (0xFF14532D)
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Septa",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Khoerun Nisa",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "STI202303888",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Rounded profile image in white border frame
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(_profileAvatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Ticker Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "PresGo",
                              style: TextStyle(
                                color: AppColors.tosca,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                            const Text(
                              " • Baru saja ",
                              style: TextStyle(color: Colors.black26, fontSize: 11.5),
                            ),
                            const Text(
                              "Pengingat Presensi",
                              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                            const Spacer(),
                            Icon(Icons.cancel_outlined, color: Colors.red.shade300, size: 14),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Mobile Programming tinggal 15 Menit Lagi >",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Rekap Kehadiran Bulan Ini (Black Text Title)
            const Text(
              "Rekap Kehadiran Bulan Ini",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRekapCard("84%", "Kehadiran", const Color(0xFFDCFCE7), AppColors.greenHadir),
                _buildRekapCard("17", "Hadir", const Color(0xFFDBEAFE), Colors.blue),
                _buildRekapCard("2", "Absen", const Color(0xFFFEE2E2), Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Jadwal Hari Ini (Black Text Title)
            const Text(
              "Jadwal Hari Ini",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Class Schedule Cards
            ...jadwalList.map((jadwal) {
              final isHadir = jadwal.status == 'Sudah Absen';
              
              // Cari foto jika sudah absen
              String? photoPath;
              if (isHadir) {
                try {
                  final hist = JadwalService.instance.presensiHistory.firstWhere((h) => h.jadwalId == jadwal.id);
                  photoPath = hist.foto;
                } catch (e) {
                  photoPath = null;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScheduleCard(
                  title: jadwal.mataKuliah,
                  time: "${jadwal.jamMulai} - ${jadwal.jamSelesai}",
                  room: jadwal.ruangan,
                  statusText: isHadir ? "Hadir" : "Absen Sekarang",
                  statusBgColor: isHadir ? const Color(0xFFDCFCE7) : const Color(0xFFFEF08A),
                  statusTextColor: isHadir ? AppColors.tosca : Colors.brown.shade800,
                  onTap: isHadir ? () => _showPhotoDialog(photoPath) : () => _navigateToCamera(jadwal),
                  showPhotoIcon: isHadir,
                ),
              );
            }),

            if (jadwalList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text("Tidak ada jadwal kelas untuk hari ini.", style: TextStyle(color: Colors.black54)),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRekapCard(String val, String label, Color bgColor, Color textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 68) / 3,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required String time,
    required String room,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    VoidCallback? onTap,
    bool showPhotoIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black26),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        room,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // Spacing between left column and right action
          // Status Badge and Photo Icon - wrapped in Flexible to prevent overflow
          Flexible(
            flex: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showPhotoIcon)
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.tosca.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.image_outlined, color: AppColors.tosca, size: 16),
                    ),
                  ),
                GestureDetector(
                  onTap: showPhotoIcon ? null : onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCamera(JadwalModel jadwal) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PresensiScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );

    if (result != null && result is Map) {
      if (result['status'] == 'success') {
        setState(() {
          JadwalService.instance.markHadir(jadwal.id, result['photoPath']);
        });
      }
    }
  }

  void _showPhotoDialog(String? imagePath) {
    if (imagePath == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppColors.tosca,
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: const Text(
                "Bukti Presensi",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
