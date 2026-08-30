import 'package:hive_flutter/hive_flutter.dart';
import 'package:m_reground/core/models/app_state.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String appStateBoxName = 'app_state_box';
  static const String appStateKey = 'app_state';
  static const String userBoxName = 'user_box';

  late Box<dynamic> _appStateBox;

  /// Initialize Hive. When [dir] is provided (used in tests), Hive will
  /// initialize in that directory instead of relying on platform plugins.
  Future<void> initialize({String? dir}) async {
    if (dir != null) {
      Hive.init(dir);
    } else {
      await Hive.initFlutter();
    }
    _appStateBox = await Hive.openBox<dynamic>(appStateBoxName);
    await Hive.openBox<dynamic>(userBoxName);
  }

  AppStateModel readAppState() {
    final dynamic raw = _appStateBox.get(appStateKey);
    if (raw is Map) {
      return AppStateModel.fromMap(raw);
    }
    return AppStateModel.initial();
  }

  Future<void> saveAppState(AppStateModel model) async {
    await _appStateBox.put(appStateKey, model.toMap());
  }

  Box<dynamic> userBox() => Hive.box<dynamic>(userBoxName);
}
