import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:medcam_app/services/history_service.dart';

final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  final HistoryService _service;
  bool _loaded = false;

  HistoryNotifier(this._service) : super([]);

  Future<void> load() async {
    if (_loaded) return;
    state = await _service.load();
    _loaded = true;
  }

  Future<void> add(HistoryEntry entry) async {
    await _service.add(entry);
    state = await _service.load();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    state = await _service.load();
  }

  Future<void> clear() async {
    await _service.clear();
    state = [];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>((ref) {
  final service = ref.watch(historyServiceProvider);
  return HistoryNotifier(service);
});
