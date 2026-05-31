class PresensiModel {
  final String id;
  final String jadwalId;
  final String mataKuliah;
  final String tanggal;
  final String jamAbsen;
  final String status; // "Hadir", "Izin", "Sakit", "Alpha"
  final String? keterangan;
  final String? foto;
  final String? method; // "Face & GPS", "Surat Dokter", etc.

  PresensiModel({
    required this.id,
    required this.jadwalId,
    required this.mataKuliah,
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
      mataKuliah: json['mata_kuliah'] ?? '',
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
      'mata_kuliah': mataKuliah,
      'tanggal': tanggal,
      'jam_absen': jamAbsen,
      'status': status,
      'keterangan': keterangan,
      'foto': foto,
    };
  }
}
