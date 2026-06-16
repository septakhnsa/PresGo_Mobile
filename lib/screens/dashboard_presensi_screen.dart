import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/jadwal_model.dart';
import '../models/presensi_model.dart';
import '../services/jadwal_service.dart';
import '../services/auth_service.dart';
import 'presensi_screen.dart';

class DashboardPresensiScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardPresensiScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardPresensiScreen> createState() =>
      _DashboardPresensiScreenState();
}

class _DashboardPresensiScreenState extends State<DashboardPresensiScreen> {
  final String _profileAvatarUrl =
      "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop";

  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    _refreshJadwalStatus();
  }

  Future<void> _refreshJadwalStatus() async {
    setState(() => _isRefreshing = true);
    await JadwalService.instance.fetchJadwalFromApi();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jadwalList = JadwalService.instance.getJadwalHariIni();

    return Scaffold(
      backgroundColor: const Color(0xFF14532D),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshJadwalStatus,
          color: const Color(0xFF14532D),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 1. App Bar and Profile Header (Dark Green Area)
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24.0, top: 8.0, bottom: 40.0),
                child: Column(
                  children: [
                    // App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Dashboard Presensi",
                          style:
                              TextStyle(color: Colors.transparent, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz,
                              color: Colors.white),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerRight,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Profile Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user['name'] ?? '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.user['nim'] ?? '-',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(_profileAvatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Sage Green Card Body
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E9D68),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification Card (hanya tampil jika ada notifikasi actionable)
                      if (JadwalService.instance.notifications
                          .any((n) => n['isActionable'] == true))
                        Builder(
                          builder: (context) {
                            final activeNotif = JadwalService
                                .instance.notifications
                                .firstWhere((n) => n['isActionable'] == true);
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _navigateToCamera(
                                    JadwalService.instance.allJadwal.firstWhere(
                                        (j) =>
                                            j.mataKuliah ==
                                            activeNotif['subjectName']),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        left: 6, right: 6, bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF14532D),
                                          blurRadius: 0,
                                          spreadRadius: 0,
                                          offset: Offset(-6, 6),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "PresGo",
                                              style: TextStyle(
                                                color: Color(0xFF14532D),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Text(
                                              " • Baru saja ",
                                              style: TextStyle(
                                                  color: Colors.black45,
                                                  fontSize: 12),
                                            ),
                                            Flexible(
                                              child: Text(
                                                activeNotif['headerText'],
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                                Icons.cancel_outlined,
                                                color: Colors.red,
                                                size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${activeNotif['bodyText']} >",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),

                      // Rekap Kehadiran Bulan Ini Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF14532D),
                              blurRadius: 0,
                              spreadRadius: 0,
                              offset: Offset(-6, 6),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Rekap Kehadiran Bulan ini",
                              style: TextStyle(
                                color: Color(0xFF14532D),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRekapCard("84%", "Kehadiran",
                                    Colors.white, const Color(0xFF14532D)),
                                _buildRekapCard("17", "Hadir", Colors.white,
                                    Colors.blue.shade800),
                                _buildRekapCard("2", "Absen", Colors.white,
                                    Colors.red.shade800),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Jadwal Hari Ini Title
                      const Text(
                        "Jadwal Hari Ini",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Class Schedule Cards
                      ...jadwalList.map((jadwal) {
                        final isHadir = jadwal.status == 'Sudah Absen';

                        // Use foto directly from model (synced from API or current session)
                        final String? photoPath = isHadir ? jadwal.foto : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildScheduleCard(
                            kode: jadwal.kode,
                            title: jadwal.mataKuliah,
                            dosen: jadwal.dosen,
                            time: "${jadwal.jamMulai} - ${jadwal.jamSelesai}",
                            room: jadwal.ruangan,
                            statusText: isHadir ? "Hadir" : "Belum",
                            statusBgColor: isHadir
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            statusTextColor: isHadir
                                ? const Color(0xFF14532D)
                                : Colors.orange.shade800,
                            onTap: isHadir
                                ? () => _showPhotoDialog(photoPath)
                                : () => _navigateToCamera(jadwal),
                            showPhotoIcon: isHadir,
                          ),
                        );
                      }),

                      if (jadwalList.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text(
                              "Tidak ada jadwal kelas untuk hari ini.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRekapCard(
      String val, String label, Color bgColor, Color textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48 - 40 - 24) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String kode,
    required String title,
    required String dosen,
    required String time,
    required String room,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    VoidCallback? onTap,
    bool showPhotoIcon = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF14532D),
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(-6, 6),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Title
          // Kode and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14532D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kode,
                  style: const TextStyle(
                    color: Color(0xFF14532D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Dosen
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dosen,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Time and Room
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF14532D),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 4, color: Colors.black45),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            room,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPhotoIcon)
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14532D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image_outlined,
                            color: Color(0xFF14532D), size: 16),
                      ),
                    ),
                  GestureDetector(
                    onTap: showPhotoIcon ? null : onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCamera(JadwalModel jadwal) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PresensiScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );

    if (result != null && result is Map) {
      if (result['status'] == 'success') {
        if (!mounted) return;
        
        // Tampilkan dialog loading pengiriman presensi
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14532D)),
                    ),
                    SizedBox(width: 20),
                    Text(
                      "Mengirim presensi...",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Kirim presensi ke server API Laravel
        final submitResult = await JadwalService.instance.submitPresensiApi(
          jadwalId: jadwal.id,
          photoPath: result['photoPath'],
          latitude: result['latitude'],
          longitude: result['longitude'],
        );

        // Tutup dialog loading
        if (mounted) {
          Navigator.pop(context);
        }

        if (submitResult['success'] == true) {
          setState(() {
            JadwalService.instance.markHadir(jadwal.id, result['photoPath']);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(submitResult['message'] ?? 'Presensi berhasil dicatat!'),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(submitResult['message'] ?? 'Gagal melakukan presensi.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  void _showPhotoDialog(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return;

    // Determine if path is a server path (from API) or a local file path
    Widget imageWidget;
    if (imagePath.startsWith('/') || imagePath.startsWith('file://') ||
        (imagePath.length > 2 && imagePath[1] == ':')) {
      // Local file path (from current session photo)
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        errorBuilder: (ctx, err, stack) => const Padding(
          padding: EdgeInsets.all(32),
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    } else {
      // Server relative path (from API: e.g. "presensi_photos/xxx.jpg")
      final storageUrl = AuthService.baseUrl.replaceAll('/api', '/storage/$imagePath');
      imageWidget = Image.network(
        storageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14532D)),
            )),
          );
        },
        errorBuilder: (ctx, err, stack) => const Padding(
          padding: EdgeInsets.all(32),
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFF14532D),
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: const Text(
                "Bukti Presensi",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            imageWidget,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup",
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
