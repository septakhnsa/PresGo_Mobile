class NotifikasiModel {
  final String id;
  final String judul;
  final String pesan;
  final String tanggal;
  final bool sudahDibaca;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tanggal,
    required this.sudahDibaca,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'].toString(),
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      tanggal: json['tanggal'] ?? '',
      sudahDibaca: json['sudah_dibaca'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'pesan': pesan,
      'tanggal': tanggal,
      'sudah_dibaca': sudahDibaca,
    };
  }
}
