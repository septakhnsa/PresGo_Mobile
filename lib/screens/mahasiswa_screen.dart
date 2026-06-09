import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MahasiswaScreen extends StatefulWidget {
  const MahasiswaScreen({super.key});

  @override
  State<MahasiswaScreen> createState() => _MahasiswaScreenState();
}

class _MahasiswaScreenState extends State<MahasiswaScreen> {
  final List<Map<String, String>> _daftarMahasiswa = [
    {
      'nama': 'Anissa Balqis',
      'nim': 'STI202303519',
      'email': 'annisabalqisbalqis79@gmail.com'
    },
    {
      'nama': 'Aina Nuratia',
      'nim': 'STI202303520',
      'email': 'ainanuratia@gmail.com'
    },
    {
      'nama': 'Dela Nur Asia',
      'nim': 'STI202303524',
      'email': 'Nadela283@gmail.com'
    },
    {
      'nama': 'Septa Khoerun Nisa',
      'nim': 'STI202303520',
      'email': 'septakhnsa@gmail.com'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Daftar Profil Mahasiswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.tosca,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _daftarMahasiswa.length,
        itemBuilder: (context, index) {
          final mhs = _daftarMahasiswa[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.tosca,
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: Offset(-5, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        AppColors.tosca.withOpacity(0.12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.tosca,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mhs['nama']!,
                          style: const TextStyle(
                            color: AppColors.tosca,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'NIM: ${mhs['nim']}',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          mhs['email']!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 0.8,
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: AppColors.goldAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Teknik Informatika • Angkatan 2023',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}