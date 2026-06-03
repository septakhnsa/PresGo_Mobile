import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'presensi_screen.dart';
import 'history_screen.dart';
import 'dashboard_presensi_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/jadwal_service.dart';
import '../models/jadwal_model.dart';

/// Returns e.g. "Rabu, 27 April 2026"
String _formatDateId(DateTime d) {
  const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
  const months = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember'
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  String _activeTab = "Home"; // "Profile", "Home", "History"
  bool _showWelcomeModal = true;
  bool _showNotificationPage = false;

  // Koordinat Kampus STMIK Widya Utama - Jl. Sunan Kalijaga, Berkoh, Purwokerto Selatan
  static const double _campusLat = -7.4390;
  static const double _campusLng = 109.2655;

  // Real-time GPS Telemetry State (menggunakan Geolocator)
  StreamSubscription<Position>? _positionStreamSubscription;
  double _liveLat = -7.4372; // Default awal (kampus) sebelum GPS didapat
  double _liveLng = 109.2645;
  late MapController _mapController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Hitung jarak Haversine antara 2 koordinat (hasil dalam meter)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // radius bumi dalam meter
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String get _distanceText {
    final dist = _calculateDistance(_liveLat, _liveLng, _campusLat, _campusLng);
    if (dist < 1000) return "${dist.toStringAsFixed(0)} m";
    return "${(dist / 1000).toStringAsFixed(2)} km";
  }

  // Female student profile avatar image
  final String _profileAvatarUrl = "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLocationTracking();
    
    // Initial notification update
    JadwalService.instance.updateNotifications(_now);
    
    // Timer for real-time clock updates every minute
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          // Update notifications every minute
          JadwalService.instance.updateNotifications(_now);
        });
      }
    });
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Dapatkan lokasi awal dengan segera
    try {
      Position initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _liveLat = initialPos.latitude;
          _liveLng = initialPos.longitude;
        });
      }
    } catch (e) {
      // Abaikan jika gagal
    }

    // Dengarkan perubahan lokasi secara realtime (distanceFilter = 0 agar selalu update)
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _liveLat = position.latitude;
          _liveLng = position.longitude;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light off-white background matching Figma
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Dynamic Figma Header Block (hidden only on Notification page)
            if (!_showNotificationPage) _buildFigmaHeader(),

            // 2. Main Page Content
            Expanded(
              child: Stack(
                children: [
                  _buildActiveScreen(),

                  // Welcome Modal Card Overlay (Visible on Home Map tab and if not dismissed)
                  if (_activeTab == "Home" && _showWelcomeModal) _buildWelcomeModal(),

                  // Floating Camera Button — bottom offset respects system nav bar
                  if (!_showNotificationPage)
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildFloatingActionButton(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIGMA TOP HEADER: Deep Green Block with tabs
  Widget _buildFigmaHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.tosca, // Deep Green (0xFF14532D)
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Septa Khoerun Nisa",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "STI202303888",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Notification Bell Icon
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showNotificationPage = true;
                  });
                },
                child: Icon(Icons.notifications_rounded, color: Colors.white.withOpacity(0.9), size: 26),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Sub-Tabs Row
          Row(
            children: [
              Expanded(child: _buildFigmaTab("Profile")),
              Expanded(child: _buildFigmaTab("Home")),
              Expanded(child: _buildFigmaTab("History")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaTab(String tabName) {
    final bool isSelected = _activeTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
          // Hide notification subpage when changing tabs
          _showNotificationPage = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.goldAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          tabName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // SCREEN SELECTOR
  Widget _buildActiveScreen() {
    if (_showNotificationPage) {
      return _buildNotificationPage();
    }

    switch (_activeTab) {
      case "Profile":
        return const ProfileScreen();
      case "History":
        return const HistoryScreen();
      case "Home":
      default:
        return _buildMapHomeScreen();
    }
  }

  // HOME SCREEN: Live Interactive Map View dengan Flutter Map (OpenStreetMap tile nyata)
  Widget _buildMapHomeScreen() {
    final userLatLng = LatLng(_liveLat, _liveLng);
    final campusLatLng = LatLng(_campusLat, _campusLng);

    return Stack(
      children: [
        // 1. Real Map dengan OpenStreetMap tile
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: campusLatLng,
            initialZoom: 15.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Tile layer OSM — peta nyata
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile_presensi',
            ),

            // Lingkaran geofence visual di sekitar kampus (hijau transparan, hanya indikator)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: campusLatLng,
                  radius: 150, // 150 meter radius visual
                  useRadiusInMeter: true,
                  color: AppColors.tosca.withOpacity(0.12),
                  borderColor: AppColors.tosca.withOpacity(0.5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Marker Layer: 2 titik (user + kampus)
            MarkerLayer(
              markers: [
                // 🏫 Marker Kampus
                Marker(
                  point: campusLatLng,
                  width: 140,
                  height: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tosca,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Text(
                          "STMIK Widya Utama",
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Icon(Icons.location_on_rounded, color: AppColors.tosca, size: 30),
                    ],
                  ),
                ),

                // 📍 Marker Lokasi User (biru, dengan animasi pulse via RadarSweepWidget)
                Marker(
                  point: userLatLng,
                  width: 110,
                  height: 65,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 139, 5, 165),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Text(
                          "Lokasi Kamu",
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.my_location_rounded, color: Colors.blue.shade600, size: 28),
                    ],
                  ),
                ),
              ],
            ),

            // Garis penghubung antara user dan kampus
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [userLatLng, campusLatLng],
                  color: Colors.purpleAccent,
                  gradientColors: const [Colors.purpleAccent, Colors.greenAccent],
                  strokeWidth: 3.5,
                ),
              ],
            ),
          ],
        ),

        // 2. Real-time GPS Telemetry HUD Overlay
        _buildGpsTelemetryHUD(),

        // 4. Top Floating Status Card (Dynamic)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Builder(
            builder: (context) {
              final todaysJadwal = JadwalService.instance.getJadwalHariIni();
              final now = _now;
              
              JadwalModel? activeJadwal;
              bool isNext = false;

              // 1. Find currently active class (not yet attended)
              try {
                activeJadwal = todaysJadwal.firstWhere((j) {
                  final start = DateTime(now.year, now.month, now.day, int.parse(j.jamMulai.split(':')[0]), int.parse(j.jamMulai.split(':')[1]));
                  final end = DateTime(now.year, now.month, now.day, int.parse(j.jamSelesai.split(':')[0]), int.parse(j.jamSelesai.split(':')[1]));
                  return now.isAfter(start) && now.isBefore(end) && j.status != 'Sudah Absen';
                });
                isNext = false;
              } catch (_) {
                // 2. If no active, find next upcoming class (not yet attended)
                try {
                  activeJadwal = todaysJadwal.firstWhere((j) {
                    final start = DateTime(now.year, now.month, now.day, int.parse(j.jamMulai.split(':')[0]), int.parse(j.jamMulai.split(':')[1]));
                    return now.isBefore(start) && j.status != 'Sudah Absen';
                  });
                  isNext = true;
                } catch (_) {
                  activeJadwal = null;
                }
              }

              if (activeJadwal == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isNext ? const Color(0xFFFEF9C3) : const Color(0xFFDCFCE7), // Yellow if next, Green if current
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isNext ? Colors.red.shade300 : Colors.green.shade300, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isNext ? "Jadwal Berikutnya" : "Sedang Berlangsung",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: isNext ? Colors.red : Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeJadwal.mataKuliah,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            "${activeJadwal.jamMulai} - ${activeJadwal.jamSelesai} @ ${activeJadwal.ruangan}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardPresensiScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: isNext ? const Color(0xFFFEF08A) : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isNext ? Colors.red : Colors.green, width: 1),
                        ),
                        child: Text(
                          "Detail",
                          style: TextStyle(
                            color: isNext ? Colors.red : Colors.green.shade900,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),

        // 4. Tombol recenter ke kampus
        Positioned(
          bottom: 115,
          right: 16,
          child: GestureDetector(
            onTap: () {
              _mapController.move(campusLatLng, 15.5);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.tosca, size: 22),
            ),
          ),
        ),
      ],
    );
  }



  // Floating live GPS status telemetry HUD
  Widget _buildGpsTelemetryHUD() {
    return Positioned(
      bottom: 115,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.80),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.goldAccent.withOpacity(0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent),
                ),
                const SizedBox(width: 6),
                const Text(
                  "GPS LIVE RADAR",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "LAT: ${_liveLat.toStringAsFixed(6)}",
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              "LNG: ${_liveLng.toStringAsFixed(6)}",
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              "ACCURACY: 2.8 meters (LIVE)",
              style: TextStyle(color: Colors.white70, fontSize: 8.5),
            ),
            const SizedBox(height: 4),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.goldAccent, size: 10),
                const SizedBox(width: 4),
                Text(
                  "JARAK KE KAMPUS: $_distanceText",
                  style: const TextStyle(color: AppColors.goldAccent, fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENT: Welcome Modal Overlay Card — scrollable so it never overflows on small screens
  Widget _buildWelcomeModal() {
    final String greeting = () {
      final h = _now.hour;
      if (h < 11) return 'Selamat Pagi!';
      if (h < 15) return 'Selamat Siang!';
      if (h < 18) return 'Selamat Sore!';
      return 'Selamat Malam!';
    }();

    return Container(
      color: Colors.black.withOpacity(0.45),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header row: date + badge ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDateId(_now),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Belum absen",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.black12, thickness: 0.8),
                const SizedBox(height: 8),

                // ── Greeting ──
                Text(
                  greeting,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tosca,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Profile photo ──
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldAccent, width: 2.5),
                    image: DecorationImage(
                      image: NetworkImage(_profileAvatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── NIM + Name ──
                const Text(
                  "STI202303888",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Septa Khoerun Nisa",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Affiliation ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Mahasiswa Semester 6 Program Studi Teknik Informatika, STMIK Widya Utama",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Sekolah Tinggi Manajemen Informatika\ndan Teknologi Widya Utama",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.black12, thickness: 0.8, height: 1),

                // ── Dismiss button ──
                GestureDetector(
                  onTap: () => setState(() => _showWelcomeModal = false),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      "Dismiss",
                      style: TextStyle(
                        color: AppColors.tosca,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
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

  // NOTIFICATION PAGE: Figma Column 4
  Widget _buildNotificationPage() {
    return Container(
      color: const Color(0xFFF8FAFC), // Off-white exactly like Figma
      child: Column(
        children: [
          // Custom green Notification header banner
          Container(
            width: double.infinity,
            color: AppColors.tosca,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: const Text(
              "Notifikasi 🔔",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  _formatDateId(_now).toLowerCase(),
                  style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Dynamic notification list from JadwalService
                ...JadwalService.instance.notifications.map((notif) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildNotificationCard(
                      isActionable: notif['isActionable'] ?? false,
                      title: notif['title'] ?? 'PresGo',
                      timeText: notif['timeText'] ?? 'Baru saja',
                      headerText: notif['headerText'] ?? 'Notifikasi',
                      bodyText: notif['bodyText'] ?? '',
                      subjectName: notif['subjectName'],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Bottom circular exit back button (red with gold border)
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showNotificationPage = false;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required bool isActionable,
    required String title,
    required String timeText,
    required String headerText,
    required String bodyText,
    String? subjectName,
  }) {
    return GestureDetector(
      onTap: () {
        if (isActionable) {
          _navigateToCamera(subject: subjectName);
        } else {
          setState(() {
            _showNotificationPage = false;
            _activeTab = "History";
          });
        }
      },
      child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mini White Circle with green P inside
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tosca.withOpacity(0.15), width: 1),
                ),
                child: const Center(
                  child: Text(
                    "P",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: AppColors.tosca,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.tosca,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(color: Colors.black26),
              ),
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.black26,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  headerText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bodyText,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (isActionable) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // "Abaikan" link
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notifikasi diabaikan.")),
                    );
                  },
                  child: const Text(
                    "Abaikan",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // "Presensi Sekarang" green button
                ElevatedButton(
                  onPressed: () => _navigateToCamera(subject: subjectName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tosca,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Presensi Sekarang",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    ),
  );
}

  // FLOATING ACTION BUTTON: Camera on Home, Logout on others
  Widget _buildFloatingActionButton() {
    if (_activeTab == "Home") {
      return GestureDetector(
        onTap: () => _navigateToCamera(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.tosca,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3), // White border matching Figma
            boxShadow: [
              BoxShadow(
                color: AppColors.tosca.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              // Gold outer ring shadow effect
              BoxShadow(
                color: AppColors.goldAccent.withOpacity(0.6),
                blurRadius: 1,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
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
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3), // White border matching Figma
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      );
    }
  }

  void _navigateToCamera({String? subject}) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PresensiScreen(initialSubject: subject),
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

    if (result != null && result is Map && result['status'] == 'success') {
      // Get subject from result if present
      final className = result['className'] ?? subject ?? "Mobile Programming";
      
      // Update data via service
      // We need to find the id for this subject
      final allJadwal = JadwalService.instance.allJadwal;
      final jadwal = allJadwal.firstWhere(
        (j) => j.mataKuliah.toLowerCase().contains(className.toLowerCase()),
        orElse: () => allJadwal.first,
      );

      setState(() {
        JadwalService.instance.markHadir(jadwal.id, result['photoPath']);
        // Refresh UI
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Presensi $className Berhasil!"),
            backgroundColor: AppColors.greenHadir,
          ),
        );
      }
    }
  }
}


