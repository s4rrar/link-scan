import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<void> sendBarcode({
    required String ipAddress,
    required int port,
    required String barcode,
    required String format,
  }) async {
    final url = Uri.parse('http://$ipAddress:$port/scan');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'barcode': barcode,
        'format': format,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    ).timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw Exception('Server returned status code: ${response.statusCode}');
    }
  }

  Future<void> pingServer({
    required String ipAddress,
    required int port,
  }) async {
    final url = Uri.parse('http://$ipAddress:$port/ping');
    final response = await http.get(url).timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw Exception('Ping response: ${response.statusCode}');
    }
  }
}
