class UserModel {
  final String id;
  final String nama;
  final String nim;
  final String email;
  final String prodi;
  final String? fotoProfil;

  UserModel({
    required this.id,
    required this.nama,
    required this.nim,
    required this.email,
    required this.prodi,
    this.fotoProfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
      email: json['email'] ?? '',
      prodi: json['prodi'] ?? '',
      fotoProfil: json['foto_profil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'nim': nim,
      'email': email,
      'prodi': prodi,
      'foto_profil': fotoProfil,
    };
  }
}
