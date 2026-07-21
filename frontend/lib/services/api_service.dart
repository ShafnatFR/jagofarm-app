import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  /// Ganti URL ini setelah deploy backend.
  /// Format: "https://jagofarm-api.up.railway.app"
  static const String baseUrl = "http://10.0.2.2:8000";

  /// Helper untuk dapatkan URL dinamis:
  /// - Android emulator → 10.0.2.2 (localhost dari emulator)
  /// - iOS simulator / real device → ganti manual
  static String get _effectiveBaseUrl {
    if (baseUrl.startsWith("http://10.0.2.2") || baseUrl.startsWith("http://localhost")) {
      return baseUrl;
    }
    return baseUrl; // Production URL
  }

  static Future<Ringkasan> getRingkasan() async {
    final res = await http.get(Uri.parse('$_effectiveBaseUrl/api/ringkasan'));
    if (res.statusCode == 200) {
      return Ringkasan.fromJson(jsonDecode(res.body));
    }
    throw Exception('Gagal memuat ringkasan: ${res.statusCode}');
  }

  static Future<List<RingkasanBiaya>> getRingkasanBiaya() async {
    final res = await http.get(Uri.parse('$_effectiveBaseUrl/api/ringkasan-biaya'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => RingkasanBiaya.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat ringkasan biaya: ${res.statusCode}');
  }

  static Future<List<TransaksiItem>> getTransaksi({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/transaksi?limit=$limit&offset=$offset'),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => TransaksiItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat transaksi: ${res.statusCode}');
  }

  static Future<List<NeracaSaldoItem>> getNeracaSaldo() async {
    final res = await http.get(Uri.parse('$_effectiveBaseUrl/api/neraca-saldo'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => NeracaSaldoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat neraca saldo: ${res.statusCode}');
  }

  static Future<LaporanKeuangan> getLaporanKeuangan() async {
    final res = await http.get(Uri.parse('$_effectiveBaseUrl/api/laporan-keuangan'));
    if (res.statusCode == 200) {
      return LaporanKeuangan.fromJson(jsonDecode(res.body));
    }
    throw Exception('Gagal memuat laporan: ${res.statusCode}');
  }

  static Future<List<AkunItem>> getDaftarAkun() async {
    final res = await http.get(Uri.parse('$_effectiveBaseUrl/api/daftar-akun'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => AkunItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat daftar akun: ${res.statusCode}');
  }
}
