import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/providers/shared_providers.dart';
import 'package:medcam_app/services/api_service.dart';

class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _api;

  SearchNotifier(this._api) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: query, results: [], error: null);
      return;
    }
    state = state.copyWith(query: query, isLoading: true, error: null);
    try {
      final response = await _api.search(query);
      state = state.copyWith(
        results: response.results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SearchNotifier(api);
});
