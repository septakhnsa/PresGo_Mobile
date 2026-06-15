import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/jadwal_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedMonth = "Juni 2026";
  final List<String> _months = [
    "Januari 2026", "Februari 2026", "Maret 2026", "April 2026",
    "Mei 2026", "Juni 2026", "Juli 2026", "Agustus 2026",
    "September 2026", "Oktober 2026", "November 2026", "Desember 2026"
  ];
  
  String _getHariString(int weekday) {
    switch (weekday) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return 'Senin';
    }
  }

  int _getMonthInt(String monthName) {
    switch (monthName.split(' ')[0].toLowerCase()) {
      case 'januari': return 1;
      case 'februari': return 2;
      case 'maret': return 3;
      case 'april': return 4;
      case 'mei': return 5;
      case 'juni': return 6;
      case 'juli': return 7;
      case 'agustus': return 8;
      case 'september': return 9;
      case 'oktober': return 10;
      case 'november': return 11;
      case 'desember': return 12;
      default: return 1;
    }
  }

  List<Map<String, String>> _generateDummyDataForMonth(String monthStr) {
    int month = _getMonthInt(monthStr);
    int year = int.parse(monthStr.split(' ')[1]);
    List<Map<String, String>> dummyLogs = [];
    
    int daysInMonth = DateTime(year, month + 1, 0).day;
    DateTime now = DateTime.now();
    
    for (int day = daysInMonth; day >= 1; day--) {
      DateTime date = DateTime(year, month, day);
      
      // Stop generating if the date is in the future
      if (date.isAfter(now)) continue;
      
      String hariStr = _getHariString(date.weekday);
      
      // Get jadwal for this hari
      var jadwalHariIni = JadwalService.instance.allJadwal.where((j) => j.hari == hariStr).toList();
      
      for (var jadwal in jadwalHariIni) {
        // Deterministic pseudo-random status
        int seed = year * 10000 + month * 100 + day + jadwal.mataKuliah.length;
        bool isHadir = (seed % 10) < 8; // 80% hadir
        
        String status = isHadir ? "Berhasil mengambil absen" : "Absen Terlewat";
        String statusColor = isHadir ? "green" : "red";
        
        String waktuHadir = "00:00:00";
        String waktuPulang = "00:00:00";
        
        if (isHadir) {
           var parts = jadwal.jamMulai.split(':');
           int h = int.parse(parts[0]);
           int m = int.parse(parts[1]);
           int mHadir = m - (seed % 15); // random 0-14 mins before
           int hHadir = h;
           if (mHadir < 0) {
             mHadir += 60;
             hHadir -= 1;
           }
           waktuHadir = "${hHadir.toString().padLeft(2, '0')}:${mHadir.toString().padLeft(2, '0')}:12";
           
           var partsPulang = jadwal.jamSelesai.split(':');
           waktuPulang = "${partsPulang[0]}:${partsPulang[1]}:34";
        }
        
        String dateFormatted = "$hariStr, ${day.toString().padLeft(2, '0')} ${monthStr.split(' ')[0]} $year";
        
        dummyLogs.add({
          "date": dateFormatted,
          "kode": jadwal.kode,
          "subject": jadwal.mataKuliah,
          "dosen": jadwal.dosen,
          "ruangan": jadwal.ruangan,
          "jamMulai": jadwal.jamMulai,
          "jamSelesai": jadwal.jamSelesai,
          "status": status,
          "waktuHadir": waktuHadir,
          "terlambat": "00:00:00",
          "waktuPulang": waktuPulang,
          "cepatPulang": "00:00:00",
          "statusColor": statusColor
        });
      }
    }
    
    return dummyLogs;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> combinedLogs = [];

    if (_selectedMonth == "Juni 2026") {
      // Combine dynamic history from JadwalService
      final realHistory = JadwalService.instance.presensiHistory.map((model) {
        return {
          "date": model.tanggal,
          "kode": model.kode,
          "subject": model.mataKuliah,
          "dosen": model.dosen,
          "ruangan": model.ruangan,
          "jamMulai": model.jamMulai,
          "jamSelesai": model.jamSelesai,
          "status": model.status == 'Hadir' ? "Berhasil mengambil absen" : model.status,
          "waktuHadir": "${model.jamAbsen}:00",
          "terlambat": "00:00:00",
          "waktuPulang": "--:--:--",
          "cepatPulang": "00:00:00",
          "statusColor": model.status == 'Hadir' ? "green" : "red"
        };
      }).toList();
      combinedLogs = [...realHistory];
    } else {
      // Generate dummy data based on schedule for past months
      combinedLogs = _generateDummyDataForMonth(_selectedMonth);
    }

    // Group logs by date
    Map<String, List<Map<String, String>>> groupedLogs = {};
    for (var log in combinedLogs) {
      String date = log['date']!;
      if (!groupedLogs.containsKey(date)) {
        groupedLogs[date] = [];
      }
      groupedLogs[date]!.add(log);
    }

    return Container(
      color: const Color(0xFFE5E5E5), // Background color matching the design
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  items: _months.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // History Cards grouped by Date Folders
          Expanded(
            child: groupedLogs.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada data presensi",
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: groupedLogs.length,
                    itemBuilder: (context, index) {
                      String dateKey = groupedLogs.keys.elementAt(index);
                      List<Map<String, String>> dateLogs = groupedLogs[dateKey]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent, // Remove ExpansionTile borders
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: index == 0,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.tosca),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dateKey,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(left: 28.0, top: 4.0),
                              child: Text(
                                "${dateLogs.length} Mata Kuliah",
                                style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                            ),
                            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            children: dateLogs.map((log) {
                              final isGreen = log["statusColor"] == "green";
                              final Color statusColor = isGreen ? Colors.green.shade600 : Colors.red.shade600;

                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6), // light grey inside card
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Left colored stripe
                                      Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                          ),
                                        ),
                                      ),
                                      // Main Content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Kode and Subject
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      log["kode"] ?? "-",
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      log["subject"] ?? "Mata Kuliah",
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              // Dosen
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 12, color: Colors.black54),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      log["dosen"] ?? "-",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              // Ruangan and Jam
                                              Row(
                                                children: [
                                                  const Icon(Icons.room_outlined, size: 12, color: Colors.black54),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    log["ruangan"] ?? "-",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.access_time, size: 12, color: Colors.black54),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${log["jamMulai"] ?? "-"} - ${log["jamSelesai"] ?? "-"}",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Status
                                              Text(
                                                log["status"]!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: statusColor,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Info Row
                                              Row(
                                                children: [
                                                  // Left column
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        _buildInfoText("Waktu Hadir", log['waktuHadir']!),
                                                        const SizedBox(height: 4),
                                                        _buildInfoText("Terlambat", log['terlambat']!),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Right column
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        _buildInfoText("Waktu Pulang", log['waktuPulang']!),
                                                        const SizedBox(height: 4),
                                                        _buildInfoText(
                                                          "Cepat Pulang",
                                                          log['cepatPulang']!,
                                                          isWarning: log['cepatPulang'] != "00:00:00",
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Bottom green bar area (to match the bottom shape in Figma)
          Container(
            height: 60,
            width: double.infinity,
            color: AppColors.tosca,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value, {bool isWarning = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Roboto', // Make sure it falls back nicely
        ),
        children: [
          TextSpan(text: "$label : "),
          TextSpan(
            text: value,
            style: TextStyle(
              color: isWarning ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
