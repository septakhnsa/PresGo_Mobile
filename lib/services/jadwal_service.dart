import '../models/jadwal_model.dart';
import '../models/presensi_model.dart';

class JadwalService {
  // Singleton instance
  static final JadwalService instance = JadwalService._internal();

  JadwalService._internal();

  // Data Jadwal Statis sesuai gambar (A6.1 - Smt 6)
  final List<JadwalModel> allJadwal = [
    JadwalModel(id: '1', mataKuliah: 'Metopen', dosen: 'Bu Lutvi', ruangan: 'K.B. R2.1', hari: 'Senin', jamMulai: '08:30', jamSelesai: '09:30', status: 'Belum Absen'),
    JadwalModel(id: '2', mataKuliah: 'Komputasi Awan', dosen: 'Pak Joko', ruangan: 'K.B. R2.1', hari: 'Senin', jamMulai: '11:00', jamSelesai: '13:00', status: 'Belum Absen'),
    JadwalModel(id: '3', mataKuliah: 'RPL', dosen: 'Bu Rini', ruangan: 'K.S. R1.2', hari: 'Selasa', jamMulai: '08:30', jamSelesai: '10:00', status: 'Belum Absen'),
    JadwalModel(id: '4', mataKuliah: 'MobPro Lanjut', dosen: 'Pak Aryo', ruangan: 'K.B. R2.3', hari: 'Rabu', jamMulai: '10:00', jamSelesai: '12:00', status: 'Belum Absen'),
    // Kamis Free
    JadwalModel(id: '5', mataKuliah: 'WebPro Lanjut', dosen: 'Pak Bayu', ruangan: 'K.B. Lab 2', hari: 'Jumat', jamMulai: '09:30', jamSelesai: '11:30', status: 'Belum Absen'),
  ];

  // List riwayat persisten
  final List<PresensiModel> presensiHistory = [];

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
