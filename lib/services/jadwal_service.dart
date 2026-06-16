import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jadwal_model.dart';
import '../models/presensi_model.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class JadwalService {
  // Singleton instance
  static final JadwalService instance = JadwalService._internal();

  // List riwayat persisten
  final List<PresensiModel> presensiHistory = [];

  // List notifikasi dinamis
  final List<Map<String, dynamic>> notifications = [];

  // Apakah jadwal sudah berhasil diambil dari API
  bool isLoadedFromApi = false;

  JadwalService._internal() {
    updateNotifications(DateTime.now());
  }

  // ── DATA JADWAL ──────────────────────────────────────────────────────────
  // Data statis sebagai fallback jika API tidak tersedia
  final List<JadwalModel> _staticJadwal = [
    JadwalModel(id: '1', kode: '#2', mataKuliah: 'Metodologi Penelitian',  dosen: 'Lutvi Riyandari, S.Pd, M.Si',       ruangan: 'K.B. R2.1',  hari: 'Senin',  jamMulai: '08:30', jamSelesai: '09:30', status: 'Belum Absen'),
    JadwalModel(id: '2', kode: '#5', mataKuliah: 'Komputasi Awan',         dosen: 'Joko Purnomo, M.Kom',               ruangan: 'K.B. R2.1',  hari: 'Senin',  jamMulai: '11:00', jamSelesai: '13:00', status: 'Belum Absen'),
    JadwalModel(id: '3', kode: '#67', mataKuliah: 'Rekayasa Perangkat Lunak', dosen: 'Eldas Puspita Rini, M.Kom',      ruangan: 'K.S. R1.2',  hari: 'Selasa', jamMulai: '08:30', jamSelesai: '10:00', status: 'Belum Absen'),
    JadwalModel(id: '4', kode: '#29', mataKuliah: 'Mobile Programming Lanjut', dosen: 'Sunaryono, M.Kom',              ruangan: 'K.B. R2.3',  hari: 'Rabu',   jamMulai: '10:00', jamSelesai: '12:00', status: 'Belum Absen'),
    JadwalModel(id: '6', kode: '#51', mataKuliah: 'Web Programming Lanjut', dosen: 'Bayu Rizkya Pratama, S.Kom., M.Pd', ruangan: 'K.B. Lab 2', hari: 'Jumat',  jamMulai: '09:30', jamSelesai: '11:30', status: 'Belum Absen'),
  ];

  // Jadwal aktif — diisi dari API atau fallback ke statis
  List<JadwalModel> allJadwal = [];

  // ── FETCH DARI API ────────────────────────────────────────────────────────
  Future<void> fetchJadwalFromApi() async {
    final token = AuthService.authToken;
    if (token == null) {
      // Belum login, pakai data statis
      _loadStaticJadwal();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/jadwal'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> jadwalList = data['data'];
        
        allJadwal = jadwalList
            .map((j) => JadwalModel.fromJson(j))
            .toList();
        
        isLoadedFromApi = true;
        print('✅ Jadwal berhasil diambil dari API: ${allJadwal.length} jadwal');
        NotificationService.instance.scheduleClassReminders(allJadwal);
      } else {
        print('⚠️ API jadwal gagal (${response.statusCode}), pakai data statis');
        _loadStaticJadwal();
      }
    } catch (e) {
      print('⚠️ Error fetch jadwal: $e, pakai data statis');
      _loadStaticJadwal();
    }
  }

  void _loadStaticJadwal() {
    allJadwal = List.from(_staticJadwal);
    isLoadedFromApi = false;
    NotificationService.instance.scheduleClassReminders(allJadwal);
  }

  // ── NOTIFIKASI ─────────────────────────────────────────────────────────────
  void updateNotifications(DateTime now) {
    if (allJadwal.isEmpty) return;

    String hariIni = _getHariString(now.weekday);
    if (now.weekday == 6 || now.weekday == 7 || now.weekday == 4) {
      hariIni = 'Senin';
    }
    
    final todaysJadwal = allJadwal.where((j) => j.hari == hariIni).toList();

    final successNotifs = notifications.where((n) => n['headerText'] == 'Presensi Berhasil').toList();
    notifications.clear();
    notifications.addAll(successNotifs);

    for (var jadwal in todaysJadwal) {
      if (jadwal.status == 'Sudah Absen') continue;

      final partsMulai = jadwal.jamMulai.split(':');
      final partsSelesai = jadwal.jamSelesai.split(':');
      if (partsMulai.length != 2 || partsSelesai.length != 2) continue;
      
      final hourMulai = int.parse(partsMulai[0]);
      final minuteMulai = int.parse(partsMulai[1]);
      final hourSelesai = int.parse(partsSelesai[0]);
      final minuteSelesai = int.parse(partsSelesai[1]);
      
      final startTime = DateTime(now.year, now.month, now.day, hourMulai, minuteMulai);
      final endTime = DateTime(now.year, now.month, now.day, hourSelesai, minuteSelesai);
      final notificationTime = startTime.subtract(const Duration(minutes: 15));

      if (now.isAfter(notificationTime) && now.isBefore(endTime)) {
        bool alreadyExists = notifications.any((n) => n['subjectName'] == jadwal.mataKuliah && n['isActionable'] == true);
        
        if (!alreadyExists) {
          String timeDisplay = 'Baru saja';
          String bodyDisplay = 'Kelas ${jadwal.mataKuliah} dimulai 15 Menit lagi.';
          
          if (now.isAfter(startTime)) {
            timeDisplay = 'Sedang Berlangsung';
            bodyDisplay = 'Kelas ${jadwal.mataKuliah} sedang berlangsung. Silakan lakukan presensi sekarang.';
          } else {
            final diffMinutes = startTime.difference(now).inMinutes;
            final diffSeconds = startTime.difference(now).inSeconds;
            
            if (diffSeconds <= 60) {
              timeDisplay = 'Segera Dimulai';
              bodyDisplay = 'Kelas ${jadwal.mataKuliah} akan segera dimulai dalam beberapa detik.';
            } else {
              timeDisplay = '$diffMinutes menit lagi';
              bodyDisplay = 'Kelas ${jadwal.mataKuliah} dimulai $diffMinutes menit lagi.';
            }
          }

          notifications.insert(0, {
            'id': 'notif_rem_${jadwal.id}',
            'isActionable': true,
            'title': 'PresGo',
            'timeText': timeDisplay,
            'headerText': 'Pengingat Presensi',
            'bodyText': bodyDisplay,
            'subjectName': jadwal.mataKuliah,
          });
        }
      }
    }
  }

  // ── JADWAL HARI INI ────────────────────────────────────────────────────────
  List<JadwalModel> getJadwalHariIni() {
    if (allJadwal.isEmpty) _loadStaticJadwal();
    
    int weekday = DateTime.now().weekday;
    String hariIni = _getHariString(weekday);
    
    // BYPASS: Jika hari Sabtu/Minggu atau Kamis (Free), default ke Senin agar presentasi tetap ada datanya.
    if (weekday == 6 || weekday == 7 || weekday == 4) {
      hariIni = 'Senin';
    }

    return allJadwal.where((j) => j.hari == hariIni).toList();
  }

  // ── MARK HADIR ─────────────────────────────────────────────────────────────
  void markHadir(String jadwalId, String fotoPath) {
    int index = allJadwal.indexWhere((j) => j.id == jadwalId);
    if (index != -1) {
      final old = allJadwal[index];
      allJadwal[index] = old.copyWith(status: 'Sudah Absen');

      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${_getHariString(now.weekday)}, ${now.day} ${_getBulanString(now.month)} ${now.year}";

      presensiHistory.insert(0, PresensiModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jadwalId: old.id,
        kode: old.kode,
        mataKuliah: old.mataKuliah,
        dosen: old.dosen,
        ruangan: old.ruangan,
        jamMulai: old.jamMulai,
        jamSelesai: old.jamSelesai,
        tanggal: dateStr,
        jamAbsen: timeStr,
        status: 'Hadir',
        method: 'Face & GPS',
        foto: fotoPath,
      ));

      notifications.removeWhere((n) => n['subjectName'] == old.mataKuliah && n['isActionable'] == true);
      
      notifications.insert(0, {
        'id': 'notif_success_${DateTime.now().millisecondsSinceEpoch}',
        'isActionable': false,
        'title': 'PresGo',
        'timeText': timeStr,
        'headerText': 'Presensi Berhasil',
        'bodyText': 'Presensi Berhasil!\n${old.mataKuliah} tercatat hadir.',
        'subjectName': old.mataKuliah,
      });

      NotificationService.instance.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Presensi Berhasil',
        body: '${old.mataKuliah} tercatat hadir.',
      );
    }
  }

  // ── CLEAR DATA (logout) ───────────────────────────────────────────────────
  void clearData() {
    presensiHistory.clear();
    notifications.clear();
    isLoadedFromApi = false;
    _loadStaticJadwal(); // Reset ke jadwal statis
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
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

  String _getBulanString(int month) {
    const bulan = ["", "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    return bulan[month];
  }
}


