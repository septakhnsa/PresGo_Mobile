import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/jadwal_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedMonth = "Mei 2026";
  final List<String> _months = [
    "Mei 2026",
    "April 2026",
    "Maret 2026",
    "Februari 2026"
  ];

  // Mock list of historic attendance items per month
  final Map<String, List<Map<String, String>>> _monthlyLogs = {
    "Mei 2026": [
      {
        "date": "Selasa, 19 Mei 2026",
        "subject": "Pemrograman Perangkat Bergerak",
        "time": "08:02 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Senin, 18 Mei 2026",
        "subject": "Kecerdasan Buatan",
        "time": "13:05 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Kamis, 14 Mei 2026",
        "subject": "Sistem Terdistribusi",
        "time": "08:15 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Rabu, 13 Mei 2026",
        "subject": "Desain Antarmuka Pengguna (UI/UX)",
        "time": "--:-- WIB",
        "status": "Sakit",
        "method": "Surat Dokter"
      },
      {
        "date": "Selasa, 12 Mei 2026",
        "subject": "Keamanan Jaringan",
        "time": "10:10 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Rabu, 06 Mei 2026",
        "subject": "Metodologi Penelitian",
        "time": "--:-- WIB",
        "status": "Izin",
        "method": "Form Izin Kemahasiswaan"
      },
      {
        "date": "Senin, 04 Mei 2026",
        "subject": "Kecerdasan Buatan",
        "time": "13:01 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      }
    ],
    "April 2026": [
      {
        "date": "Kamis, 23 April 2026",
        "subject": "Pemrograman Web Lanjut",
        "time": "09:30 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Rabu, 15 April 2026",
        "subject": "Rekayasa Perangkat Lunak",
        "time": "08:30 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Selasa, 14 April 2026",
        "subject": "Komputasi Awan",
        "time": "--:-- WIB",
        "status": "Alpha",
        "method": "Tanpa Keterangan"
      }
    ],
    "Maret 2026": [
      {
        "date": "Senin, 30 Maret 2026",
        "subject": "Metodologi Penelitian",
        "time": "08:25 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Selasa, 24 Maret 2026",
        "subject": "Sistem Operasi",
        "time": "--:-- WIB",
        "status": "Sakit",
        "method": "Surat Dokter"
      }
    ],
    "Februari 2026": [
      {
        "date": "Kamis, 26 Februari 2026",
        "subject": "Basis Data Lanjut",
        "time": "13:05 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      },
      {
        "date": "Rabu, 18 Februari 2026",
        "subject": "Mobile Programming",
        "time": "10:15 WIB",
        "status": "Hadir",
        "method": "Face & GPS"
      }
    ]
  };

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> currentMonthLogs = _monthlyLogs[_selectedMonth] ?? [];
    List<Map<String, String>> combinedLogs = [];

    if (_selectedMonth == "Mei 2026") {
      // Gabungkan history presensi yang baru hanya untuk bulan Mei 2026
      final realHistory = JadwalService.instance.presensiHistory.map((model) {
        return {
          "date": model.tanggal,
          "subject": model.mataKuliah,
          "time": "${model.jamAbsen} WIB",
          "status": model.status,
          "method": "Face & GPS",
        };
      }).toList();
      combinedLogs = [...realHistory, ...currentMonthLogs];
    } else {
      combinedLogs = [...currentMonthLogs];
    }

    // Hitung statistik secara dinamis berdasarkan data log yang sedang ditampilkan
    int hadirCount = combinedLogs.where((log) => log['status'] == 'Hadir').length;
    int sakitCount = combinedLogs.where((log) => log['status'] == 'Sakit').length;
    int izinCount = combinedLogs.where((log) => log['status'] == 'Izin').length;
    int alphaCount = combinedLogs.where((log) => log['status'] == 'Alpha').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Riwayat Presensi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selection Horizontal Scroller
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _months.length,
              itemBuilder: (context, idx) {
                final month = _months[idx];
                final isSelected = month == _selectedMonth;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = month;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tosca : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.tosca : AppColors.tosca.withOpacity(0.15),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.tosca.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Small Statistics Box for Selected Month
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat("Hadir", hadirCount.toString(), AppColors.greenHadir),
                  _buildMiniStat("Sakit", sakitCount.toString(), AppColors.blueSakit),
                  _buildMiniStat("Izin", izinCount.toString(), AppColors.orangeIzin),
                  _buildMiniStat("Alpa", alphaCount.toString(), AppColors.redAlpa),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // History logs List title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Log Presensi Harian",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // History Scroll list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: combinedLogs.length,
              itemBuilder: (context, idx) {
                final log = combinedLogs[idx];
                final String status = log["status"]!;
                
                Color statusColor;
                Color statusBgColor;
                switch (status) {
                  case "Hadir":
                    statusColor = AppColors.greenHadir;
                    statusBgColor = AppColors.greenHadir.withOpacity(0.12);
                    break;
                  case "Sakit":
                    statusColor = AppColors.blueSakit;
                    statusBgColor = AppColors.blueSakit.withOpacity(0.12);
                    break;
                  default: // Izin
                    statusColor = AppColors.orangeIzin;
                    statusBgColor = AppColors.orangeIzin.withOpacity(0.12);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
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
                            // Date
                            Text(
                              log["date"]!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Course Name
                            Text(
                              log["subject"]!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.toscaDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Details (Time + Method)
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      log["time"]!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          log["method"]!,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80), // Padding above bottom nav bar
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
