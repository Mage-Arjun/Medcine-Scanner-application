import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medcam_app/core/constants.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/services/settings_service.dart';

class ApiService {
  final SettingsService _settings;

  ApiService(this._settings);

  Future<String> get _baseUrl async => await _settings.apiBaseUrl;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _baseUrl}$path');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> health() async {
    final url = Uri.parse('${await _baseUrl}${ApiPaths.health}');
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<SearchResponse> search(String query, {int topN = 10}) async {
    final data = await _post(ApiPaths.search, {
      'query': query,
      'top_n': topN,
    });
    return SearchResponse.fromJson(data);
  }

  Future<SearchResponse> identify(List<OcrBlock> blocks, {int topN = 5}) async {
    final data = await _post(ApiPaths.identify, {
      'ocr_blocks': blocks.map((b) => b.toJson()).toList(),
      'top_n': topN,
    });
    return SearchResponse.fromJson(data);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
