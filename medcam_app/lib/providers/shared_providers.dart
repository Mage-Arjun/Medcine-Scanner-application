import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medcam_app/services/api_service.dart';
import 'package:medcam_app/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final apiServiceProvider = Provider<ApiService>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return ApiService(settings);
});
