class PresensiModel {
  final String id;
  final String jadwalId;
  final String kode;
  final String mataKuliah;
  final String dosen;
  final String ruangan;
  final String jamMulai;
  final String jamSelesai;
  final String tanggal;
  final String jamAbsen;
  final String status; // "Hadir", "Izin", "Sakit", "Alpha"
  final String? keterangan;
  final String? foto;
  final String? method; // "Face & GPS", "Surat Dokter", etc.

  PresensiModel({
    required this.id,
    required this.jadwalId,
    this.kode = '-',
    required this.mataKuliah,
    this.dosen = '-',
    this.ruangan = '-',
    this.jamMulai = '-',
    this.jamSelesai = '-',
    required this.tanggal,
    required this.jamAbsen,
    required this.status,
    this.keterangan,
    this.foto,
    this.method,
  });

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id'].toString(),
      jadwalId: json['jadwal_id'].toString(),
      kode: json['kode'] ?? '-',
      mataKuliah: json['mata_kuliah'] ?? '',
      dosen: json['dosen'] ?? '-',
      ruangan: json['ruangan'] ?? '-',
      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',
      tanggal: json['tanggal'] ?? '',
      jamAbsen: json['jam_absen'] ?? '',
      status: json['status'] ?? 'Alpha',
      keterangan: json['keterangan'],
      foto: json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jadwal_id': jadwalId,
      'kode': kode,
      'mata_kuliah': mataKuliah,
      'dosen': dosen,
      'ruangan': ruangan,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'tanggal': tanggal,
      'jam_absen': jamAbsen,
      'status': status,
      'keterangan': keterangan,
      'foto': foto,
    };
  }
}
