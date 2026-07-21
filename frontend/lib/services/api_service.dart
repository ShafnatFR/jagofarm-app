import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  /// URL backend setelah deploy ke Vercel.
  static const String baseUrl = "https://jagofarm-api.vercel.app";

  /// HTTP client dengan timeout panjang (Render free cold start)
  static final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 45);
  static const int _maxRetries = 2;

  /// Helper: request dengan retry & timeout
  static Future<http.Response> _request(Uri uri) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final req = http.Request('GET', uri);
        final stream = await _client.send(req).timeout(_timeout);
        final res = await http.Response.fromStream(stream);

        // Cold start → retry sekali lagi
        if (res.statusCode >= 502 && attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
          continue;
        }
        return res;
      } on TimeoutException {
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    // Fallback (tidak akan sampai sini)
    throw Exception('Request gagal setelah $_maxRetries percobaan');
  }

  static Future<Ringkasan> getRingkasan() async {
    final res = await _request(Uri.parse('$baseUrl/api/ringkasan'));
    if (res.statusCode == 200) {
      return Ringkasan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Gagal muat ringkasan (${res.statusCode})');
  }

  static Future<List<RingkasanBiaya>> getRingkasanBiaya() async {
    final res = await _request(Uri.parse('$baseUrl/api/ringkasan-biaya'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => RingkasanBiaya.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal muat ringkasan biaya (${res.statusCode})');
  }

  static Future<List<TransaksiItem>> getTransaksi({int limit = 50, int offset = 0}) async {
    final res = await _request(
      Uri.parse('$baseUrl/api/transaksi?limit=$limit&offset=$offset'),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => TransaksiItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal muat transaksi (${res.statusCode})');
  }

  static Future<LaporanKeuangan> getLaporanKeuangan() async {
    final res = await _request(Uri.parse('$baseUrl/api/laporan-keuangan'));
    if (res.statusCode != 200) {
      throw Exception('Gagal muat laporan (${res.statusCode})');
    }
    return LaporanKeuangan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
