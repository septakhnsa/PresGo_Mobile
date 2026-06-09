import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static const String baseUrl = "http://192.168.1.11:8000/api";

  // ── GET /api/admin/dashboard ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/admin/dashboard"),
            headers: {"Accept": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {"success": false, "message": "Format response tidak sesuai"};
      }
      return {
        "success": false,
        "message": "HTTP Error: ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

// ── GET /api/admin/matakuliah ─────────────────────────────────────────────
  static Future<List<dynamic>> getMataKuliah() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/matakuliah"), // <── Sesuaikan dengan endpoint route di Laravel Anda
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Jika response Laravel berupa object (ex: {data: [...]}), sesuaikan menjadi data['data']
        return data is List ? data : (data['data'] ?? []);
      } else {
        throw Exception("Gagal memuat data mata kuliah");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // ── GET /api/admin/mahasiswa ──────────────────────────────────────────────
  static Future<List<dynamic>> getMahasiswa() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/mahasiswa"), // <── Sesuaikan dengan endpoint route di Laravel Anda
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['data'] ?? []);
      } else {
        throw Exception("Gagal memuat data mahasiswa");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
  
  // ── GET /api/admin/jadwal ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getJadwal() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/admin/jadwal"),
            headers: {"Accept": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {"success": false, "message": "Format response tidak sesuai"};
      }
      return {
        "success": false,
        "message": "HTTP Error: ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }

  // ── GET /api/admin/presensi/{jadwal_id} ───────────────────────────────────
  static Future<Map<String, dynamic>> getPresensi(int jadwalId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/admin/presensi/$jadwalId"),
            headers: {"Accept": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {"success": false, "message": "Format response tidak sesuai"};
      }
      return {
        "success": false,
        "message": "HTTP Error: ${response.statusCode}",
      };
    } catch (e) {
      return {"success": false, "message": "Exception: $e"};
    }
  }
}