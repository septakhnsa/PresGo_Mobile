import '../models/jadwal_model.dart';
import '../models/presensi_model.dart';

class JadwalService {
  // Singleton instance
  static final JadwalService instance = JadwalService._internal();

  // List riwayat persisten
  final List<PresensiModel> presensiHistory = [];

  // List notifikasi dinamis
  final List<Map<String, dynamic>> notifications = [];

  JadwalService._internal() {
    updateNotifications(DateTime.now());
  }

  void updateNotifications(DateTime now) {
    // 1. Ambil jadwal hari ini (termasuk bypass)
    String hariIni = _getHariString(now.weekday);
    if (now.weekday == 6 || now.weekday == 7 || now.weekday == 4) {
      hariIni = 'Senin';
    }
    
    final todaysJadwal = allJadwal.where((j) => j.hari == hariIni).toList();

    // 2. Filter notifikasi: Simpan hanya notifikasi "Berhasil" (yang permanen)
    // dan hapus pengingat otomatis agar bisa diupdate
    final successNotifs = notifications.where((n) => n['headerText'] == 'Presensi Berhasil').toList();
    notifications.clear();
    notifications.addAll(successNotifs);

    // 3. Cek setiap jadwal untuk hari ini
    for (var jadwal in todaysJadwal) {
      if (jadwal.status == 'Sudah Absen') continue;

      // Parse jam mulai dan selesai
      final partsMulai = jadwal.jamMulai.split(':');
      final partsSelesai = jadwal.jamSelesai.split(':');
      if (partsMulai.length != 2 || partsSelesai.length != 2) continue;
      
      final hourMulai = int.parse(partsMulai[0]);
      final minuteMulai = int.parse(partsMulai[1]);
      final hourSelesai = int.parse(partsSelesai[0]);
      final minuteSelesai = int.parse(partsSelesai[1]);
      
      // Buat DateTime untuk jadwal hari ini
      final startTime = DateTime(now.year, now.month, now.day, hourMulai, minuteMulai);
      final endTime = DateTime(now.year, now.month, now.day, hourSelesai, minuteSelesai);
      final notificationTime = startTime.subtract(const Duration(minutes: 15));

      // Jika waktu sekarang sudah masuk jendela 15 menit sebelum DAN belum lewat jam selesai
      if (now.isAfter(notificationTime) && now.isBefore(endTime)) {
        // Cek apakah sudah ada pengingat untuk matkul ini
        bool alreadyExists = notifications.any((n) => n['subjectName'] == jadwal.mataKuliah && n['isActionable'] == true);
        
        if (!alreadyExists) {
          // Tentukan teks waktu dan body yang lebih akurat
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

  // Data Jadwal Statis sesuai gambar (A6.1 - Smt 6)
  final List<JadwalModel> allJadwal = [
    JadwalModel(id: '1', mataKuliah: 'Metopen', dosen: 'Bu Lutvi', ruangan: 'K.B. R2.1', hari: 'Senin', jamMulai: '08:30', jamSelesai: '09:30', status: 'Belum Absen'),
    JadwalModel(id: '2', mataKuliah: 'Komputasi Awan', dosen: 'Pak Joko', ruangan: 'K.B. R2.1', hari: 'Senin', jamMulai: '11:00', jamSelesai: '13:00', status: 'Belum Absen'),
    JadwalModel(id: '3', mataKuliah: 'RPL', dosen: 'Bu Rini', ruangan: 'K.S. R1.2', hari: 'Selasa', jamMulai: '08:30', jamSelesai: '10:00', status: 'Belum Absen'),
    JadwalModel(id: '4', mataKuliah: 'Mobile Programming', dosen: 'Pak Aryo', ruangan: 'K.B. R2.3', hari: 'Rabu', jamMulai: '10:00', jamSelesai: '12:00', status: 'Belum Absen'),
    // Kamis Free
    JadwalModel(id: '5', mataKuliah: 'WebPro Lanjut', dosen: 'Pak Bayu', ruangan: 'K.B. Lab 2', hari: 'Jumat', jamMulai: '09:30', jamSelesai: '11:30', status: 'Belum Absen'),
  ];


  // Ambil jadwal hari ini berdasarkan dayOfWeek (1=Senin, ..., 7=Minggu)
  List<JadwalModel> getJadwalHariIni() {
    int weekday = DateTime.now().weekday;
    String hariIni = _getHariString(weekday);
    
    // BYPASS: Jika hari Sabtu/Minggu atau Kamis (Free), default ke Senin agar presentasi tetap ada datanya.
    if (weekday == 6 || weekday == 7 || weekday == 4) {
      hariIni = 'Senin';
    }

    return allJadwal.where((j) => j.hari == hariIni).toList();
  }

  // Fungsi menandai hadir
  void markHadir(String jadwalId, String fotoPath) {
    // 1. Update status jadwal
    int index = allJadwal.indexWhere((j) => j.id == jadwalId);
    if (index != -1) {
      final old = allJadwal[index];
      allJadwal[index] = JadwalModel(
        id: old.id,
        mataKuliah: old.mataKuliah,
        dosen: old.dosen,
        ruangan: old.ruangan,
        hari: old.hari,
        jamMulai: old.jamMulai,
        jamSelesai: old.jamSelesai,
        status: 'Sudah Absen',
      );

      // 2. Tambah ke history
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${_getHariString(now.weekday)}, ${now.day} ${_getBulanString(now.month)} ${now.year}";

      presensiHistory.insert(0, PresensiModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jadwalId: old.id,
        mataKuliah: old.mataKuliah,
        tanggal: dateStr,
        jamAbsen: timeStr,
        status: 'Hadir',
        method: 'Face & GPS',
        foto: fotoPath,
      ));

      // 3. Update notifikasi
      // Hapus pengingat untuk matkul ini jika ada
      notifications.removeWhere((n) => n['subjectName'] == old.mataKuliah && n['isActionable'] == true);
      
      // Tambah notifikasi berhasil
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
  }

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
