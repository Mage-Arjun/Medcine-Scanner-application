import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    final url = Uri.parse('${await _baseUrl}$path');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout ?? const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException(0, 'No internet connection');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on FormatException {
      throw ApiException(0, 'Invalid server response');
    }
  }

  Future<Map<String, dynamic>> health() async {
    final url = Uri.parse('${await _baseUrl}${ApiPaths.health}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, response.body);
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException(0, 'No internet connection');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out');
    } on FormatException {
      throw ApiException(0, 'Invalid server response');
    }
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

  Future<OcrResponse> ocr(String imageBase64) async {
    final data = await _post(ApiPaths.ocr, {
      'image': imageBase64,
    }, timeout: const Duration(seconds: 60));
    return OcrResponse.fromJson(data);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
