import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'main_navigation.dart';
import '../theme/app_theme.dart';

class KrsScreen extends StatefulWidget {
  final bool initialPending;
  const KrsScreen({super.key, this.initialPending = false});

  @override
  State<KrsScreen> createState() => _KrsScreenState();
}

class _KrsScreenState extends State<KrsScreen> {
  List<dynamic> matkulList = [];
  List<dynamic> selected = [];
  bool loading = true;
  late bool isPending;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    isPending = widget.initialPending;
    fetchMatkul();
    if (isPending) {
      _startStatusPolling();
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkKrsStatus();
    });
  }

  Future<void> _checkKrsStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("${AuthService.baseUrl}/user"),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer ${AuthService.authToken ?? ''}",
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final krsCompleted = data['krs_completed']?.toString();
        
        if (krsCompleted == '1') {
          _statusTimer?.cancel();
          if (mounted) {
            // Update current user data so MainNavigation has the latest info
            if (AuthService.currentUser != null) {
              AuthService.currentUser!['krs_completed'] = 1;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Admin telah menyetujui KRS Anda"),
                backgroundColor: AppColors.greenHadir,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainNavigation(user: AuthService.currentUser ?? {})),
            );
          }
        }
      }
    } catch (e) {
      // Abaikan error saat polling
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchMatkul() async {
  try {
    final response = await http
        .get(
          Uri.parse("${AuthService.baseUrl}/krs/matakuliah"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer ${AuthService.authToken ?? ''}",
          },
        )
        .timeout(const Duration(seconds: 10)); // 🔥 penting

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

        print("=== KRS RAW DATA ===");
        print(data);

      setState(() {
        matkulList = data['data'] ?? [];
        if (data['status'] == 'pending') {
          isPending = true;
          _startStatusPolling();
        } else if (data['status'] == 'approved') {
           // Jika saat dibuka sudah approved
           WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainNavigation(user: AuthService.currentUser ?? {})),
              );
           });
        }
        loading = false;
      });
    } else {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error server: ${response.statusCode}")),
      );
    }
  } catch (e) {
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal koneksi: $e")),
    );
  }
}

  Future<void> submitKrs() async {
    if (selected.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Pilih minimal 1 mata kuliah terlebih dahulu"),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
    if (AuthService.authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login dulu")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("${AuthService.baseUrl}/krs"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${AuthService.authToken ?? ''}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "jadwal_ids": selected,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KRS berhasil disimpan")),
      );

      setState(() {
        isPending = true;
      });
      _startStatusPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tosca,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Kartu Rencana Studi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isPending
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.access_time_filled, size: 80, color: AppColors.tosca),
                  SizedBox(height: 20),
                  Text(
                    "Menunggu persetujuan admin",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "KRS Anda sedang dalam proses peninjauan.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : loading
              ? const Center(
                  child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.tosca),
                ))
              : Column(
                  children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pilih mata kuliah yang akan ditempuh pada semester ini",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: matkulList.length,
                    itemBuilder: (context, i) {
                      final item = matkulList[i];
                      final isSelected = selected.contains(item['id']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.tosca.withOpacity(0.5)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: Colors.grey.shade400,
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            title: Text(
                              item['nama_mk'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tosca.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${item['sks']} SKS",
                                      style: const TextStyle(
                                        color: AppColors.tosca,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            value: isSelected,
                            activeColor: AppColors.tosca,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selected.add(item['id']);
                                } else {
                                  selected.remove(item['id']);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: submitKrs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: AppColors.tosca,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Simpan KRS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}