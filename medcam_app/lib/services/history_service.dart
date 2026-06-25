import 'package:shared_preferences/shared_preferences.dart';
import 'package:medcam_app/core/constants.dart';
import 'package:medcam_app/models/history_entry.dart';

class HistoryService {
  List<HistoryEntry> _cache = [];

  Future<List<HistoryEntry>> load() async {
    if (_cache.isNotEmpty) return _cache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.historyBox);
    if (raw == null || raw.isEmpty) return [];
    _cache = HistoryEntry.decodeList(raw);
    _cache.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return List.unmodifiable(_cache);
  }

  Future<void> add(HistoryEntry entry) async {
    _cache.add(entry);
    _cache.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    await _persist();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> clear() async {
    _cache.clear();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.historyBox, HistoryEntry.encodeList(_cache));
  }
}
