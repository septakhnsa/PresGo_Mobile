import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MataKuliahScreen extends StatefulWidget {
  const MataKuliahScreen({super.key});

  @override
  State<MataKuliahScreen> createState() => _MataKuliahScreenState();
}

class _MataKuliahScreenState extends State<MataKuliahScreen> {
  // DATA DUMMY SEMESTER 6 TEKNIK INFORMATIKA
  final List<Map<String, dynamic>> _daftarMk = [
    {'nama_mk': 'Metodologi Penelitian', 'kode_mk': '#2', 'sks': 2},
    {'nama_mk': 'Komputasi Awan', 'kode_mk': '#5', 'sks': 4},
    {'nama_mk': 'Rekayasa Perangkat Lunak', 'kode_mk': '#67', 'sks': 3},
    {'nama_mk': 'Mobile Programming Lanjut', 'kode_mk': '#29', 'sks': 4},
    {'nama_mk': 'Kecerdasan Buatan', 'kode_mk': '#41', 'sks': 3},
    {'nama_mk': 'Web Programming Lanjut', 'kode_mk': '#51', 'sks': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mata Kuliah'),
        backgroundColor: AppColors.tosca,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _daftarMk.length,
        itemBuilder: (context, index) {
          final mk = _daftarMk[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.mintBackground,
                child: Icon(Icons.book_rounded, color: AppColors.tosca),
              ),
              title: Text(
                mk['nama_mk']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Kode MK: ${mk['kode_mk']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${mk['sks']} SKS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tosca,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}