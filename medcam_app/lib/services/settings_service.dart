import 'package:shared_preferences/shared_preferences.dart';
import 'package:medcam_app/core/constants.dart';

class SettingsService {
  static const _defaultUrl = 'http://127.0.0.1:8000';
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> get apiBaseUrl async {
    final prefs = await _getInstance();
    return prefs.getString(StorageKeys.apiBaseUrl) ?? _defaultUrl;
  }

  Future<void> setApiBaseUrl(String url) async {
    final prefs = await _getInstance();
    await prefs.setString(StorageKeys.apiBaseUrl, url);
  }
}
