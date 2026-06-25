class SearchResult {
  final String medicine;
  final String? genericName;
  final double score;
  final String matchType;
  final String? uses;
  final String? sideEffects;
  final String? imageUrl;

  SearchResult({
    required this.medicine,
    this.genericName,
    required this.score,
    required this.matchType,
    this.uses,
    this.sideEffects,
    this.imageUrl,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      medicine: json['medicine'] as String,
      genericName: json['generic_name'] as String?,
      score: (json['score'] as num).toDouble(),
      matchType: json['match_type'] as String,
      uses: json['uses'] as String?,
      sideEffects: json['side_effects'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'medicine': medicine,
    'generic_name': genericName,
    'score': score,
    'match_type': matchType,
    'uses': uses,
    'side_effects': sideEffects,
    'image_url': imageUrl,
  };
}

class SearchResponse {
  final String query;
  final String normalizedQuery;
  final List<SearchResult> results;

  SearchResponse({
    required this.query,
    required this.normalizedQuery,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String,
      normalizedQuery: json['normalized_query'] as String,
      results: (json['results'] as List)
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OcrBlock {
  final String text;
  final double confidence;
  final Map<String, dynamic>? boundingBox;

  OcrBlock({
    required this.text,
    this.confidence = 0.0,
    this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'confidence': confidence,
    if (boundingBox != null) 'bounding_box': boundingBox,
  };
}
