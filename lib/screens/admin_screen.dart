import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import 'login_screen.dart';
import 'mata_kuliah_screen.dart';
import 'mahasiswa_screen.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const AdminScreen({super.key, this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  // ── Tab controller ────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Dashboard state ───────────────────────────────────────────────────────
  Map<String, dynamic>? _dashboardData;
  bool _dashboardLoading = true;
  String? _dashboardError;

  // ── Jadwal state ──────────────────────────────────────────────────────────
  List<dynamic> _jadwalList = [];
  bool _jadwalLoading = true;
  String? _jadwalError;

  // ── Presensi state ────────────────────────────────────────────────────────
  // Jadwal yang sedang dipilih untuk dilihat presensinya
  Map<String, dynamic>? _selectedJadwal;
  List<dynamic> _presensiList = [];
  bool _presensiLoading = false;
  String? _presensiError;
  int? _totalHadir;

  // ── Helpers ───────────────────────────────────────────────────────────────
  final String _baseUrl = "http://192.168.18.66:8000";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
    _loadDashboard();
    _loadJadwal();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loaders ──────────────────────────────────────────────────────────
  Future<void> _loadDashboard() async {
    setState(() {
      _dashboardLoading = true;
      _dashboardError = null;
    });
    final result = await AdminService.getDashboard();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _dashboardData = result['data'];
        _dashboardLoading = false;
      });
    } else {
      setState(() {
        _dashboardError = result['message'] ?? 'Gagal memuat data';
        _dashboardLoading = false;
      });
    }
  }

  Future<void> _loadJadwal() async {
  setState(() {
    _jadwalLoading = true;
    _jadwalError = null;
  });

  final result = await AdminService.getJadwal();

  print("HASIL JADWAL:");
  print(result);

  if (!mounted) return;

  if (result['success'] == true) {
    setState(() {
      _jadwalList = result['data'] ?? [];
      _jadwalLoading = false;
    });

    print("JUMLAH JADWAL: ${_jadwalList.length}");
  } else {
    setState(() {
      _jadwalError = result['message'] ?? 'Gagal memuat jadwal';
      _jadwalLoading = false;
    });
  }
}

  Future<void> _loadPresensi(Map<String, dynamic> jadwal) async {
    setState(() {
      _selectedJadwal = jadwal;
      _presensiLoading = true;
      _presensiError = null;
      _presensiList = [];
      _totalHadir = null;
    });
    // Switch ke tab Riwayat
    _tabController.animateTo(2);

    final result = await AdminService.getPresensi(jadwal['id']);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _presensiList = data['presensis'] ?? [];
        _totalHadir = data['total_hadir'] ?? 0;
        _presensiLoading = false;
      });
    } else {
      setState(() {
        _presensiError = result['message'] ?? 'Gagal memuat presensi';
        _presensiLoading = false;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.tosca,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari panel admin?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tosca,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final adminName = widget.user?['name'] ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Green Header ─────────────────────────────────────────────
            _buildHeader(adminName),

            // ── Tab Bar ──────────────────────────────────────────────────
            _buildTabBar(),

            // ── Tab Content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildJadwalTab(),
                  _buildRiwayatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String adminName) {
    return Container(
      width: double.infinity,
      color: AppColors.tosca,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Admin info
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldAccent.withOpacity(0.2),
                  border: Border.all(color: AppColors.goldAccent, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.goldAccent,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adminName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Administrator',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Logout button
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.tosca,
      padding: const EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Jadwal'),
          Tab(text: 'Riwayat'),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1 — DASHBOARD
  // =========================================================================
  Widget _buildDashboardTab() {
    if (_dashboardLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tosca),
      );
    }
    if (_dashboardError != null) {
      return _buildErrorState(_dashboardError!, _loadDashboard);
    }

    final data = _dashboardData!;
    final int totalMhs = data['total_mahasiswa'] ?? 0;
    final int totalMk = data['total_mata_kuliah'] ?? 0;
    final int totalPres = data['total_presensi_hari_ini'] ?? 0;
    final List jadwalAktif = data['jadwal_aktif'] ?? [];

    return RefreshIndicator(
      color: AppColors.tosca,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat Cards ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.book_rounded,
                    label: 'Mata Kuliah',
                    value: '$totalMk', 
                    color: AppColors.tosca,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MataKuliahScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people_rounded,
                    label: 'Mahasiswa',
                    value: '$totalMhs', 
                    color: const Color(0xFF1D6FB8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MahasiswaScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Presensi Hari Ini',
                    value: '$totalPres', 
                    color: AppColors.greenHadir,
                    onTap: () {
                      // Kosongkan atau sesuaikan jika ada halaman presensi
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // ── Jadwal Aktif Hari Ini ─────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  color: AppColors.tosca,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Jadwal Aktif Hari Ini',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tosca.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${jadwalAktif.length} kelas',
                    style: const TextStyle(
                      color: AppColors.tosca,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (jadwalAktif.isEmpty)
              _buildEmptyCard(
                icon: Icons.event_busy_rounded,
                message: 'Tidak ada jadwal aktif hari ini',
              )
            else
              ...jadwalAktif.map(
                (j) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildJadwalCard(j, showPresensiButton: true),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────────────────
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon bagian atas kartu
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            // Angka Total (Value)
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Label Nama Kartu (Mata Kuliah / Mahasiswa)
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2 — JADWAL
  // =========================================================================
  Widget _buildJadwalTab() {
    if (_jadwalLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tosca),
      );
    }
    if (_jadwalError != null) {
      return _buildErrorState(_jadwalError!, _loadJadwal);
    }

    // Group jadwal by hari
    final Map<String, List<dynamic>> grouped = {};
    const hariOrder = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    for (final j in _jadwalList) {
      final hari = j['hari'] ?? 'Lainnya';
      grouped.putIfAbsent(hari, () => []).add(j);
    }

    return RefreshIndicator(
      color: AppColors.tosca,
      onRefresh: _loadJadwal,
      child: _jadwalList.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: _buildEmptyCard(
                  icon: Icons.calendar_today_rounded,
                  message: 'Belum ada data jadwal kuliah',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                for (final hari in hariOrder)
                  if (grouped.containsKey(hari)) ...[
                    _buildHariHeader(hari),
                    const SizedBox(height: 10),
                    ...grouped[hari]!.map(
                      (j) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildJadwalCard(j, showPresensiButton: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
    );
  }

  Widget _buildHariHeader(String hari) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.goldAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hari,
          style: const TextStyle(
            color: AppColors.tosca,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.tosca.withOpacity(0.2))),
      ],
    );
  }

  // ── Shared Jadwal Card ────────────────────────────────────────────────────
  Widget _buildJadwalCard(
    Map<String, dynamic> jadwal, {
    bool showPresensiButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.tosca,
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(-5, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MK name + SKS badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  jadwal['nama_mk'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${jadwal['sks'] ?? 0} SKS',
                  style: const TextStyle(
                    color: AppColors.tosca,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            jadwal['kode_mk'] ?? '-',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Info row
          Wrap(
            spacing: 6,    // Jarak horizontal antar chip info
            runSpacing: 6, // Jarak vertikal (otomatis turun ke bawah kalau layar sempit)
            children: [
              _buildInfoChip(
                Icons.schedule_rounded,
                '${jadwal['jam_mulai'] ?? '-'} – ${jadwal['jam_selesai'] ?? '-'}',
              ),
              _buildInfoChip(
                Icons.meeting_room_rounded,
                jadwal['ruangan'] ?? '-',
              ),
              if (jadwal.containsKey('hari') && jadwal['hari'] != null)
                _buildInfoChip(Icons.calendar_today_rounded, jadwal['hari']),
            ],
          ),
          if (showPresensiButton) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _loadPresensi(jadwal),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_reg_rounded,
                    color: AppColors.tosca,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Lihat Riwayat Kehadiran',
                    style: TextStyle(
                      color: AppColors.tosca,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.tosca,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.mintBackground,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.toscaLight,
          size: 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.tosca,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  // =========================================================================
  // TAB 3 — RIWAYAT KEHADIRAN
  // =========================================================================
  Widget _buildRiwayatTab() {
    // Belum pilih jadwal
    if (_selectedJadwal == null && !_presensiLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.tosca.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.tosca,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Jadwal Terlebih Dahulu',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Buka tab Jadwal atau Dashboard, lalu tekan\n"Lihat Riwayat Kehadiran" pada jadwal yang diinginkan.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Ke Tab Jadwal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tosca,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_presensiLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tosca),
      );
    }

    if (_presensiError != null) {
      return _buildErrorState(
        _presensiError!,
        () => _loadPresensi(_selectedJadwal!),
      );
    }

    final jadwal = _selectedJadwal!;

    return RefreshIndicator(
      color: AppColors.tosca,
      onRefresh: () => _loadPresensi(jadwal),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Jadwal Info Header Card ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jadwal info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.tosca,
                          AppColors.toscaLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.toscaDark,
                          blurRadius: 0,
                          offset: Offset(-5, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jadwal['nama_mk'] ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${jadwal['kode_mk'] ?? ''} • ${jadwal['sks'] ?? 0} SKS',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildWhiteChip(
                              Icons.schedule_rounded,
                              '${jadwal['jam_mulai'] ?? '-'} – ${jadwal['jam_selesai'] ?? '-'}',
                            ),
                            const SizedBox(width: 8),
                            _buildWhiteChip(
                              Icons.meeting_room_rounded,
                              jadwal['ruangan'] ?? '-',
                            ),
                            if (jadwal['hari'] != null) ...[
                              const SizedBox(width: 8),
                              _buildWhiteChip(
                                Icons.today_rounded,
                                jadwal['hari'],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total hadir badge
                  Row(
                    children: [
                      const Icon(
                        Icons.how_to_reg_rounded,
                        color: AppColors.tosca,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Hadir: ${_totalHadir ?? 0} mahasiswa',
                        style: const TextStyle(
                          color: AppColors.tosca,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── List Presensi ───────────────────────────────────────────────
          if (_presensiList.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyCard(
                icon: Icons.person_off_rounded,
                message: 'Belum ada presensi untuk jadwal ini',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = _presensiList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPresensiCard(p, index),
                    );
                  },
                  childCount: _presensiList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWhiteChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Presensi Card ─────────────────────────────────────────────────────────
  Widget _buildPresensiCard(Map<String, dynamic> p, int index) {
    final String fotoWajah = p['foto_wajah'] ?? '';
    final String statusWajah = p['status_wajah'] ?? '-';
    final bool faceVerified =
        statusWajah.toLowerCase().contains('verified') ||
        statusWajah.toLowerCase().contains('match') ||
        statusWajah.toLowerCase().contains('terverifikasi') ||
        statusWajah.toLowerCase() == 'success';
    final Color statusColor = faceVerified
        ? AppColors.greenHadir
        : AppColors.orangeIzin;
    final Color statusBg = faceVerified
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);

    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.tosca,
            blurRadius: 0,
            offset: Offset(-4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Foto Wajah ───────────────────────────────────────────
                GestureDetector(
                  onTap:
                      fotoWajah.isNotEmpty
                          ? () => _showFotoDialog(fotoWajah, p['nama_mahasiswa'])
                          : null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.mintBackground,
                      border: Border.all(
                        color: faceVerified
                            ? AppColors.greenHadir
                            : Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: fotoWajah.isNotEmpty
                        ? _buildFotoWajah(fotoWajah)
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info Mahasiswa ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nama_mahasiswa'] ?? '-',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['nim'] ?? '-',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Jam masuk
                          _buildInfoChip(
                            Icons.login_rounded,
                            p['jam_masuk'] ?? '-',
                          ),
                          const SizedBox(width: 6),
                          // Tanggal
                          if (p['tanggal'] != null)
                            _buildInfoChip(
                              Icons.calendar_today_rounded,
                              p['tanggal'],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Status Wajah ──────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            faceVerified
                                ? Icons.face_retouching_natural
                                : Icons.face_outlined,
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            faceVerified ? 'Terverifikasi' : statusWajah,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fotoWajah.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Tap foto →',
                          style: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Koordinat GPS ─────────────────────────────────────────────
          if (p['latitude'] != null && p['longitude'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.toscaLight,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lat: ${p['latitude']}, Lng: ${p['longitude']}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Foto Wajah Widget ─────────────────────────────────────────────────────
  Widget _buildFotoWajah(String fotoWajah) {
    // Jika URL lengkap
    if (fotoWajah.startsWith('http://') || fotoWajah.startsWith('https://')) {
      return Image.network(
        fotoWajah,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          color: AppColors.textMuted,
          size: 28,
        ),
      );
    }
    // Jika path relatif dari server
    if (fotoWajah.isNotEmpty) {
      final url = '$_baseUrl/storage/$fotoWajah';
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          color: AppColors.textMuted,
          size: 28,
        ),
      );
    }
    return const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 28);
  }

  // ── Dialog Foto Wajah ─────────────────────────────────────────────────────
  void _showFotoDialog(String fotoWajah, String? namaMhs) {
    String imageUrl = fotoWajah;
    if (!fotoWajah.startsWith('http')) {
      imageUrl = '$_baseUrl/storage/$fotoWajah';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: AppColors.tosca,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      namaMhs ?? 'Foto Wajah',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
            // Foto
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.tosca),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 60,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: AppColors.tosca,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared: Error State ───────────────────────────────────────────────────
  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.redAlpa.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.redAlpa,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tosca,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared: Empty State ───────────────────────────────────────────────────
  Widget _buildEmptyCard({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.tosca.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.tosca, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}