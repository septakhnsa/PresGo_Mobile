import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class KrsService {

  static Future<List<dynamic>> getMatkul() async {
    final res = await http.get(
      Uri.parse("${AuthService.baseUrl}/krs/matakuliah"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${AuthService.authToken}",
      },
    );

    final data = jsonDecode(res.body);
    return data['data'];
  }

  static Future<bool> submitKrs(List<int> ids) async {
    final res = await http.post(
      Uri.parse("${AuthService.baseUrl}/krs"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer ${AuthService.authToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "jadwal_ids": ids,
      }),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }
}