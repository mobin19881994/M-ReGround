import 'package:m_reground/config/app_config.dart';
import 'package:m_reground/core/services/local_storage_service.dart';

class VersionGuardService {
  VersionGuardService._();

  static final VersionGuardService instance = VersionGuardService._();

  bool isExpired() {
    final DateTime installDate = LocalStorageService.instance.readAppState().installDate;
    final int ageDays = DateTime.now().difference(installDate).inDays;
    return ageDays >= AppConfig.appExpiryDays;
  }

  int remainingDays() {
    final DateTime installDate = LocalStorageService.instance.readAppState().installDate;
    final int ageDays = DateTime.now().difference(installDate).inDays;
    return (AppConfig.appExpiryDays - ageDays).clamp(0, AppConfig.appExpiryDays);
  }
}
