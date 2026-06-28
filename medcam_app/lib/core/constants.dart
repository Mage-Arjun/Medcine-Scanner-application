class ApiPaths {
  ApiPaths._();
  static const health = '/health';
  static const search = '/search';
  static const identify = '/identify';
  static const ocr = '/ocr';
}

class AppTabs {
  AppTabs._();
  static const int scanner = 0;
  static const int search = 1;
  static const int history = 2;
}

class AppLimits {
  AppLimits._();
  static const defaultTopN = 10;
  static const maxTopN = 100;
  static const searchDebounceMs = 300;
}

class StorageKeys {
  StorageKeys._();
  static const apiBaseUrl = 'api_base_url';
  static const historyBox = 'history_box';
}
