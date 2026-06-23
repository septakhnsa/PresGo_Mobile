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
        Uri.parse('${AuthService.baseUrl}/jadwal/my'),
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
        
        final now = DateTime.now();
        final todayStr = "${_getHariString(now.weekday)}, ${now.day} ${_getBulanString(now.month)} ${now.year}";

        String formatServerDate(String? dateStr) {
          if (dateStr == null) return todayStr;
          try {
            final parsed = DateTime.parse(dateStr);
            return "${_getHariString(parsed.weekday)}, ${parsed.day} ${_getBulanString(parsed.month)} ${parsed.year}";
          } catch (_) {
            return dateStr;
          }
        }

        for (var j in allJadwal) {
          print('   📋 ${j.mataKuliah} (id:${j.id}) → status: "${j.status}"');
          if (j.status == 'Sudah Absen') {
            final formattedDate = formatServerDate(j.tanggalAbsen);

            // 1. (Dihapus) Logika penambahan ke presensiHistory sekarang ditangani oleh fetchHistoryFromApi()

            // 2. Remove actionable reminder
            notifications.removeWhere((n) => n['subjectName'] == j.mataKuliah && n['isActionable'] == true);

            // 3. Add to success notifications if not exists
            bool notifExists = notifications.any((n) => n['subjectName'] == j.mataKuliah && n['headerText'] == 'Presensi Berhasil');
            if (!notifExists) {
              notifications.insert(0, {
                'id': 'notif_success_api_${j.id}',
                'isActionable': false,
                'title': 'PresGo',
                'timeText': j.jamAbsen ?? j.jamMulai,
                'headerText': 'Presensi Berhasil',
                'bodyText': 'Presensi Berhasil!\n${j.mataKuliah} tercatat hadir.',
                'subjectName': j.mataKuliah,
              });
            }
          }
        }
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

  /// Jumlah matkul hari ini yang sudah hadir (untuk badge greeting card)
  int get hadirHariIni =>
      getJadwalHariIni().where((j) => j.status == 'Sudah Absen').length;

  /// Total matkul hari ini (untuk badge greeting card)
  int get totalJadwalHariIni => getJadwalHariIni().length;

  // ── SUBMIT PRESENSI KE API ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitPresensiApi({
    required String jadwalId,
    required String photoPath,
    required double? latitude,
    required double? longitude,
  }) async {
    final token = AuthService.authToken;
    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan. Silakan login kembali.'};
    }

    try {
      final uri = Uri.parse('${AuthService.baseUrl}/presensi/submit');
      final request = http.MultipartRequest('POST', uri);

      // Add Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add Fields
      request.fields['jadwal_id'] = jadwalId;
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      // Add File
      final file = await http.MultipartFile.fromPath(
        'photo',
        photoPath,
      );
      request.files.add(file);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Presensi Submit Status Code: ${response.statusCode}');
      print('Presensi Submit Response Body: ${response.body}');

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': resData['message'] ?? 'Presensi berhasil dicatat!',
          'data': resData['data']
        };
      } else {
        return {
          'success': false,
          'message': resData['message'] ?? 'Gagal melakukan presensi. Silakan coba lagi.'
        };
      }
    } catch (e) {
      print('Error submitPresensiApi: $e');
      return {
        'success': false,
        'message': 'Koneksi gagal: $e'
      };
    }
  }

  //baru
  Future<Map<String, dynamic>> fetchRekapKehadiran({int? bulan, int? tahun}) async {
  final token = AuthService.authToken;
  if (token == null) return {'hadir': 0, 'absen': 0, 'persentase': 0};

  final now = DateTime.now();
  final b = bulan ?? now.month;
  final t = tahun ?? now.year;

  try {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/presensi/rekap?bulan=$b&tahun=$t'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    print('Error fetchRekap: $e');
  }
  return {'hadir': 0, 'absen': 0, 'persentase': 0};
}

  Future<void> fetchHistoryFromApi() async {
    final token = AuthService.authToken;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/presensi/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> historyList = data['data'];

        presensiHistory.clear();

        for (var h in historyList) {
          final rawDate = h['tanggal']; // Y-m-d
          final parsed = DateTime.parse(rawDate);
          final formattedDate = "${_getHariString(parsed.weekday)}, ${parsed.day} ${_getBulanString(parsed.month)} ${parsed.year}";

          presensiHistory.add(PresensiModel(
            id: h['id'],
            jadwalId: h['jadwal_id'],
            kode: h['kode'],
            mataKuliah: h['mataKuliah'],
            dosen: h['dosen'],
            ruangan: h['ruangan'],
            jamMulai: h['jamMulai'],
            jamSelesai: h['jamSelesai'],
            tanggal: formattedDate,
            jamAbsen: h['jam_masuk'],
            status: 'Hadir',
            method: 'Face & GPS',
            foto: h['foto'],
          ));
        }
      }
    } catch (e) {
      print('Error fetchHistory: $e');
    }
  }

  // ── MARK HADIR ─────────────────────────────────────────────────────────────
  void markHadir(String jadwalId, String fotoPath) {
    int index = allJadwal.indexWhere((j) => j.id == jadwalId);
    if (index != -1) {
      final old = allJadwal[index];
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${_getHariString(now.weekday)}, ${now.day} ${_getBulanString(now.month)} ${now.year}";

      // Update model with status + foto so photo icon works immediately
      allJadwal[index] = old.copyWith(
        status: 'Sudah Absen',
        foto: fotoPath,
        jamAbsen: timeStr,
        tanggalAbsen: dateStr,
      );

      // Add to persisted history
      bool historyExists = presensiHistory.any((h) => h.jadwalId == jadwalId);
      if (!historyExists) {
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
      }

      notifications.removeWhere((n) => n['subjectName'] == old.mataKuliah && n['isActionable'] == true);
      
      bool notifExists = notifications.any((n) => n['subjectName'] == old.mataKuliah && n['headerText'] == 'Presensi Berhasil');
      if (!notifExists) {
        notifications.insert(0, {
          'id': 'notif_success_${DateTime.now().millisecondsSinceEpoch}',
          'isActionable': false,
          'title': 'PresGo',
          'timeText': timeStr,
          'headerText': 'Presensi Berhasil',
          'bodyText': 'Presensi Berhasil!\n${old.mataKuliah} tercatat hadir.',
          'subjectName': old.mataKuliah,
        });
      }

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


