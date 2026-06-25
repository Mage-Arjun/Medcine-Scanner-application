import 'dart:convert';
import 'medicine.dart';

class HistoryEntry {
  final String id;
  final String medicine;
  final String? genericName;
  final String? imageUrl;
  final String source;
  final DateTime scannedAt;
  final String? query;

  HistoryEntry({
    required this.id,
    required this.medicine,
    this.genericName,
    this.imageUrl,
    required this.source,
    required this.scannedAt,
    this.query,
  });

  factory HistoryEntry.fromResult({
    required String id,
    required SearchResult result,
    required String source,
    String? query,
  }) {
    return HistoryEntry(
      id: id,
      medicine: result.medicine,
      genericName: result.genericName,
      imageUrl: result.imageUrl,
      source: source,
      scannedAt: DateTime.now(),
      query: query,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicine': medicine,
    'generic_name': genericName,
    'image_url': imageUrl,
    'source': source,
    'scanned_at': scannedAt.toIso8601String(),
    'query': query,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      medicine: json['medicine'] as String,
      genericName: json['generic_name'] as String?,
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      query: json['query'] as String?,
    );
  }

  static String encodeList(List<HistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<HistoryEntry> decodeList(String encoded) {
    final list = jsonDecode(encoded) as List;
    return list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
