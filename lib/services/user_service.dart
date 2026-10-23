import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class UserService {
  static const String _keyProject = 'user_project';
  static const String _keyCurrentPriority = 'user_current_priority';
  static const String _keyTodayBuildFocusPrefix = 'today_build_focus';
  static const String _keyTodaySelfFocusPrefix = 'today_self_focus';
  static SharedPreferences? _prefs;
  static Future<SharedPreferences>? _prefsFuture;

  static Future<SharedPreferences> init() {
    return _prefsFuture ??= SharedPreferences.getInstance().then((
      SharedPreferences prefs,
    ) {
      _prefs = prefs;
      return prefs;
    });
  }

  static Future<SharedPreferences> _instance() async {
    return _prefs ?? await init();
  }

  static Future<bool> isOnboarded() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  static Future<void> completeOnboarding({
    required String name,
    required String goal,
    required double dailyBudget,
    required int age,
    String? project,
    String? currentPriority,
  }) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
    await prefs.setString(AppConstants.userNameKey, name);
    await prefs.setString(AppConstants.userGoalKey, goal);
    await prefs.setDouble(AppConstants.userDailyBudgetKey, dailyBudget);
    await prefs.setInt(AppConstants.userAgeKey, age);
    if (project != null) {
      await prefs.setString(_keyProject, project);
    }
    if (currentPriority != null) {
      await prefs.setString(_keyCurrentPriority, currentPriority);
    }
  }

  static Future<String> getName() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(AppConstants.userNameKey) ?? 'Founder';
  }

  static Future<String> getProject() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(_keyProject) ?? 'your startup';
  }

  static Future<String> getGoal() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(AppConstants.userGoalKey) ?? 'building';
  }

  static Future<String> getCurrentPriority() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(_keyCurrentPriority) ?? 'Protect momentum';
  }

  static Future<void> setCurrentPriority(String value) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(_keyCurrentPriority, value);
  }

  static Future<double> getDailyBudget() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getDouble(AppConstants.userDailyBudgetKey) ?? 500.0;
  }

  static Future<int> getAge() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getInt(AppConstants.userAgeKey) ?? 20;
  }

  static Future<bool> getNotificationsEnabled() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setBool(AppConstants.notificationsEnabledKey, enabled);
  }

  static Future<String> getTodayBuildFocus() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(_datedKey(_keyTodayBuildFocusPrefix)) ?? '';
  }

  static Future<void> setTodayBuildFocus(String value) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(_datedKey(_keyTodayBuildFocusPrefix), value.trim());
  }

  static Future<String> getTodaySelfFocus() async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(_datedKey(_keyTodaySelfFocusPrefix)) ?? '';
  }

  static Future<void> setTodaySelfFocus(String value) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(_datedKey(_keyTodaySelfFocusPrefix), value.trim());
  }

  static String _datedKey(String prefix, {DateTime? date}) {
    final DateTime target = date ?? DateTime.now();
    return '${prefix}_${target.year}_${target.month}_${target.day}';
  }

  static String getInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'F';
  }
}
