class ApiPaths {
  static const health = '/health';
  static const search = '/search';
  static const identify = '/identify';
}

class AppLimits {
  static const defaultTopN = 10;
  static const maxTopN = 100;
  static const searchDebounceMs = 300;
}

class StorageKeys {
  static const apiBaseUrl = 'api_base_url';
  static const historyBox = 'history_box';
}
