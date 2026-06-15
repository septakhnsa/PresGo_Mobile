class JadwalModel {
  final String id;
  final String kode;       // e.g. "#2", "#5"
  final String mataKuliah;
  final String dosen;
  final String ruangan;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String status; // "Sudah Absen", "Belum Absen"

  JadwalModel({
    required this.id,
    this.kode = '-',
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
      kode: json['kode'] ?? '-',
      mataKuliah: json['mataKuliah'] ?? json['mata_kuliah'] ?? '',
      dosen: json['dosen'] ?? '-',
      ruangan: json['ruangan'] ?? '-',
      hari: json['hari'] ?? '',
      jamMulai: json['jamMulai'] ?? json['jam_mulai'] ?? '',
      jamSelesai: json['jamSelesai'] ?? json['jam_selesai'] ?? '',
      status: json['status'] ?? 'Belum Absen',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode': kode,
      'mataKuliah': mataKuliah,
      'dosen': dosen,
      'ruangan': ruangan,
      'hari': hari,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'status': status,
    };
  }

  JadwalModel copyWith({String? status}) {
    return JadwalModel(
      id: id,
      kode: kode,
      mataKuliah: mataKuliah,
      dosen: dosen,
      ruangan: ruangan,
      hari: hari,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      status: status ?? this.status,
    );
  }
}

