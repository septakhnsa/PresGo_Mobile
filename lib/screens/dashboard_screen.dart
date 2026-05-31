import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/attendance_card.dart';
import '../widgets/schedule_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulated class schedules per day
  final Map<String, List<Map<String, String>>> _schedules = {
    "Senin": [
      {
        "title": "Pemrograman Perangkat Bergerak",
        "time": "08:00 - 10:30 WIB",
        "room": "Lab Komputer 3",
        "lecturer": "Bpk. Rahmat Siregar, M.T.",
        "status": "Sudah Absen"
      },
      {
        "title": "Kecerdasan Buatan",
        "time": "13:00 - 15:30 WIB",
        "room": "Ruang H.3.2",
        "lecturer": "Ibu Novita Sari, M.Cs.",
        "status": "Belum Absen"
      }
    ],
    "Selasa": [
      {
        "title": "Keamanan Jaringan",
        "time": "10:00 - 12:30 WIB",
        "room": "Lab Jaringan",
        "lecturer": "Bpk. Dian Pratama, M.Kom.",
        "status": "Mulai"
      },
      {
        "title": "Etika Profesi IT",
        "time": "14:00 - 16:00 WIB",
        "room": "Ruang H.1.5",
        "lecturer": "Ibu Ratna Dewi, M.Si.",
        "status": "Belum Absen"
      }
    ],
    "Rabu": [
      {
        "title": "Desain Antarmuka Pengguna (UI/UX)",
        "time": "08:00 - 10:30 WIB",
        "room": "Lab Multimedia",
        "lecturer": "Ibu Shinta Bella, M.Ds.",
        "status": "Sudah Absen"
      },
      {
        "title": "Metodologi Penelitian",
        "time": "10:40 - 12:10 WIB",
        "room": "Ruang H.2.1",
        "lecturer": "Dr. Eng. H. Kurniawan",
        "status": "Sudah Absen"
      }
    ],
    "Kamis": [
      {
        "title": "Sistem Terdistribusi",
        "time": "08:00 - 10:30 WIB",
        "room": "Lab Komputer 1",
        "lecturer": "Bpk. Hendra Wijaya, Ph.D.",
        "status": "Belum Absen"
      }
    ],
    "Jumat": [
      {
        "title": "Kewirausahaan Teknologi",
        "time": "09:00 - 11:30 WIB",
        "room": "Aula Lantai 2",
        "lecturer": "Dr. Ir. Budi Santoso, M.B.A.",
        "status": "Belum Absen"
      }
    ]
  };

  final List<String> _days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Wave Header
            ClipPath(
              clipper: HeaderCurveClipper(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 50.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.toscaDark, AppColors.tosca],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Top Bar (Profile summary)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Text(
                                  "S",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Halo, Septa!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "NIM: 2209106041 • Informatika",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE2F1E8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Notification Badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Badge(
                            alignment: AlignmentDirectional.topEnd,
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Welcome announcement card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.campaign_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Pengumuman Akademik",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Presensi Ujian Tengah Semester (UTS) dibuka sesuai jadwal kuliah masing-masing.",
                                  style: TextStyle(
                                    color: Color(0xFFE2F1E8),
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section - Statistics
                  const Text(
                    "Ringkasan Kehadiran",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Statistics Cards Grid (4 items)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    children: const [
                      AttendanceCard(
                        label: "Hadir",
                        value: "18",
                        icon: Icons.check_circle_rounded,
                        color: AppColors.greenHadir,
                      ),
                      AttendanceCard(
                        label: "Sakit",
                        value: "2",
                        icon: Icons.medical_services_rounded,
                        color: AppColors.blueSakit,
                      ),
                      AttendanceCard(
                        label: "Izin",
                        value: "1",
                        icon: Icons.assignment_turned_in_rounded,
                        color: AppColors.orangeIzin,
                      ),
                      AttendanceCard(
                        label: "Alpa",
                        value: "0",
                        icon: Icons.cancel_rounded,
                        color: AppColors.redAlpa,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Banner Check-in Quick Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F4F1), Color(0xFFCBEAE4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: AppColors.tosca.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Presensi Sekarang",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.toscaDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Gunakan Face & GPS Check-in",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.tosca,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Jadwal Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Jadwal Kelas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        "Semester 6",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tosca,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Day Tabs
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      indicator: BoxDecoration(
                        color: AppColors.tosca,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tabs: _days.map((day) => Tab(text: day)).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tab View List
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabController,
                      children: _days.map((day) {
                        final subjects = _schedules[day] ?? [];
                        if (subjects.isEmpty) {
                          return const Center(
                            child: Text(
                              "Tidak ada jadwal kuliah hari ini.",
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: subjects.length,
                          itemBuilder: (context, idx) {
                            final item = subjects[idx];
                            return ScheduleCard(
                              title: item["title"]!,
                              time: item["time"]!,
                              room: item["room"]!,
                              lecturer: item["lecturer"]!,
                              status: item["status"]!,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 80), // Padding below content to avoid being blocked by floating bottom navigation bar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Clipper for curved wave header
class HeaderCurveClipper extends CustomClipper<Path> {
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
