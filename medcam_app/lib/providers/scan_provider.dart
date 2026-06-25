import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/providers/shared_providers.dart';
import 'package:medcam_app/services/api_service.dart';

class ScanState {
  final bool isCapturing;
  final bool isProcessing;
  final List<OcrBlock> ocrBlocks;
  final SearchResponse? response;
  final String? error;

  const ScanState({
    this.isCapturing = false,
    this.isProcessing = false,
    this.ocrBlocks = const [],
    this.response,
    this.error,
  });

  ScanState copyWith({
    bool? isCapturing,
    bool? isProcessing,
    List<OcrBlock>? ocrBlocks,
    SearchResponse? response,
    String? error,
  }) {
    return ScanState(
      isCapturing: isCapturing ?? this.isCapturing,
      isProcessing: isProcessing ?? this.isProcessing,
      ocrBlocks: ocrBlocks ?? this.ocrBlocks,
      response: response ?? this.response,
      error: error,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final ApiService _api;

  ScanNotifier(this._api) : super(const ScanState());

  void setCapturing(bool v) => state = state.copyWith(isCapturing: v);

  void setOcrBlocks(List<OcrBlock> blocks) {
    state = state.copyWith(ocrBlocks: blocks, isCapturing: false);
  }

  Future<void> identify({int topN = 5}) async {
    if (state.ocrBlocks.isEmpty) return;
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final response = await _api.identify(state.ocrBlocks, topN: topN);
      state = state.copyWith(response: response, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void reset() {
    state = const ScanState();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ScanNotifier(api);
});
