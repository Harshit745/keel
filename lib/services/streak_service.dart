import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLongestStreak = 'longest_streak';
  static const String _keyLastLogDate = 'last_log_date';
  static const String _keyStreakFreezes = 'streak_freezes';
  static const String _keyLastFreezeWeek = 'last_freeze_week';
  static const String _keyShownMilestones = 'shown_streak_milestones';

  static Future<int> recordLog(DateTime date) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastLogStr = prefs.getString(_keyLastLogDate);
    final int current = prefs.getInt(_keyCurrentStreak) ?? 0;
    final int longest = prefs.getInt(_keyLongestStreak) ?? 0;

    final String today = _dateKey(date);
    final String yesterday = _dateKey(
      DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(const Duration(days: 1)),
    );

    int newStreak;

    if (lastLogStr == today) {
      newStreak = current;
    } else if (lastLogStr == yesterday || lastLogStr == null) {
      newStreak = current + 1;
    } else {
      final int freezes = prefs.getInt(_keyStreakFreezes) ?? 0;
      if (freezes > 0 && _daysBetween(lastLogStr, today) == 2) {
        newStreak = current + 1;
        await prefs.setInt(_keyStreakFreezes, freezes - 1);
      } else {
        newStreak = 1;
      }
    }

    await prefs.setInt(_keyCurrentStreak, newStreak);
    await prefs.setString(_keyLastLogDate, today);
    if (newStreak > longest) {
      await prefs.setInt(_keyLongestStreak, newStreak);
    }

    return newStreak;
  }

  static Future<int> getCurrentStreak() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastLogStr = prefs.getString(_keyLastLogDate);
    if (lastLogStr == null) {
      return 0;
    }

    final String today = _dateKey(DateTime.now());
    final String yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (lastLogStr != today && lastLogStr != yesterday) {
      await prefs.setInt(_keyCurrentStreak, 0);
      return 0;
    }

    return prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  static Future<int> getLongestStreak() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLongestStreak) ?? 0;
  }

  static Future<int> getStreakFreezes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakFreezes) ?? 1;
  }

  static Future<void> checkAndAwardWeeklyFreeze() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String lastFreezeWeek = prefs.getString(_keyLastFreezeWeek) ?? '';
    final DateTime now = DateTime.now();
    final String thisWeek = '${now.year}-W${_isoWeek(now)}';
    if (lastFreezeWeek != thisWeek && now.weekday == DateTime.monday) {
      final int current = prefs.getInt(_keyStreakFreezes) ?? 0;
      if (current < 2) {
        await prefs.setInt(_keyStreakFreezes, current + 1);
      }
      await prefs.setString(_keyLastFreezeWeek, thisWeek);
    }
  }

  static bool isMilestone(int streak) {
    return <int>[3, 7, 14, 21, 30, 60, 100, 365].contains(streak);
  }

  static String milestoneMessage(int streak) {
    switch (streak) {
      case 3:
        return 'Three days strong! You\'re building a habit.';
      case 7:
        return 'One full week! You\'re on fire.';
      case 14:
        return 'Two weeks! This is becoming part of you.';
      case 21:
        return '21 days — science says this is now a habit.';
      case 30:
        return 'One month! You\'re in the top 1% of users.';
      case 60:
        return 'Two months. Absolute legend.';
      case 100:
        return '100 days. Nothing can stop you now.';
      case 365:
        return 'One full year. You are LifeScore.';
      default:
        return 'Keep going!';
    }
  }

  static Future<bool> shouldShowMilestone(int streak) async {
    if (!isMilestone(streak)) {
      return false;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> shownMilestones =
        prefs.getStringList(_keyShownMilestones) ?? <String>[];
    return !shownMilestones.contains(streak.toString());
  }

  static Future<void> markMilestoneShown(int streak) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> shownMilestones =
        prefs.getStringList(_keyShownMilestones) ?? <String>[];
    final String value = streak.toString();
    if (!shownMilestones.contains(value)) {
      shownMilestones.add(value);
      await prefs.setStringList(_keyShownMilestones, shownMilestones);
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _isoWeek(DateTime date) {
    final int dayOfYear = int.parse(DateFormat('D').format(date));
    final int dayOfWeek = date.weekday;
    return ((dayOfYear - dayOfWeek + 10) / 7).floor();
  }

  static int _daysBetween(String from, String to) {
    final DateTime a = DateTime.parse(from);
    final DateTime b = DateTime.parse(to);
    return b.difference(a).inDays;
  }
}
