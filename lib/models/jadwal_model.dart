class JadwalModel {
  final String id;
  final String mataKuliah;
  final String dosen;
  final String ruangan;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String status; // "Sudah Absen", "Belum Absen", "Mulai"

  JadwalModel({
    required this.id,
    required this.mataKuliah,
    required this.dosen,
    required this.ruangan,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.status,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      id: json['id'].toString(),
      mataKuliah: json['mata_kuliah'] ?? '',
      dosen: json['dosen'] ?? '',
      ruangan: json['ruangan'] ?? '',
      hari: json['hari'] ?? '',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      status: json['status'] ?? 'Belum Absen',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mata_kuliah': mataKuliah,
      'dosen': dosen,
      'ruangan': ruangan,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'status': status,
    };
  }
}
