import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/build_log.dart';
import '../models/idea.dart';
import '../models/self_log.dart';
import 'score_service.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BuildLogAdapter());
    Hive.registerAdapter(SelfLogAdapter());
    Hive.registerAdapter(IdeaAdapter());
    await Hive.openBox<BuildLog>(AppConstants.buildLogsBox);
    await Hive.openBox<SelfLog>(AppConstants.selfLogsBox);
    await Hive.openBox<Idea>(AppConstants.ideasBox);
  }

  Future<Box<T>> _box<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  // BUILD LOG methods
  Future<void> saveBuildLog(BuildLog log) async {
    log.buildScore = ScoreService.calculateBuildScore(
      tasksShipped: log.tasksShipped,
      talkedToUser: log.talkedToUser,
      movedNeedle: log.movedNeedle,
      revenueAdded: log.revenueAdded,
    );
    final Box<BuildLog> box = await _box<BuildLog>(AppConstants.buildLogsBox);
    await box.put(log.id, log);
  }

  Future<BuildLog?> getBuildLogForDate(DateTime date) async {
    final Box<BuildLog> box = await _box<BuildLog>(AppConstants.buildLogsBox);
    final String key = BuildLog.keyForDate(date);
    return box.get(key);
  }

  Future<List<BuildLog>> getBuildLogsForWeek(DateTime date) async {
    final Box<BuildLog> box = await _box<BuildLog>(AppConstants.buildLogsBox);
    final DateTime start = _startOfWeek(date);
    return box.values.where((BuildLog log) {
      final DateTime d = DateTime(log.date.year, log.date.month, log.date.day);
      return !d.isBefore(start) &&
          !d.isAfter(start.add(const Duration(days: 6)));
    }).toList();
  }

  // SELF LOG methods
  Future<void> saveSelfLog(SelfLog log) async {
    log.selfScore = ScoreService.calculateSelfScore(
      sleepHours: log.sleepHours,
      energyLevel: log.energyLevel,
      moodRating: log.moodRating,
      moneySpent: log.moneySpent,
      dailyBudget: log.dailyBudget,
      exercised: log.exercised,
    );
    final Box<SelfLog> box = await _box<SelfLog>(AppConstants.selfLogsBox);
    await box.put(log.id, log);
  }

  Future<SelfLog?> getSelfLogForDate(DateTime date) async {
    final Box<SelfLog> box = await _box<SelfLog>(AppConstants.selfLogsBox);
    return box.get(SelfLog.keyForDate(date));
  }

  Future<List<SelfLog>> getSelfLogsForWeek(DateTime date) async {
    final Box<SelfLog> box = await _box<SelfLog>(AppConstants.selfLogsBox);
    final DateTime start = _startOfWeek(date);
    return box.values.where((SelfLog log) {
      final DateTime d = DateTime(log.date.year, log.date.month, log.date.day);
      return !d.isBefore(start) &&
          !d.isAfter(start.add(const Duration(days: 6)));
    }).toList();
  }

  // IDEA VAULT methods
  Future<void> saveIdea(Idea idea) async {
    final Box<Idea> box = await _box<Idea>(AppConstants.ideasBox);
    await box.put(idea.id, idea);
  }

  Future<void> deleteIdea(String id) async {
    final Box<Idea> box = await _box<Idea>(AppConstants.ideasBox);
    await box.delete(id);
  }

  Future<List<Idea>> getAllIdeas() async {
    final Box<Idea> box = await _box<Idea>(AppConstants.ideasBox);
    return box.values.where((Idea i) => !i.isArchived).toList()
      ..sort((Idea a, Idea b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  DateTime _startOfWeek(DateTime date) {
    final DateTime d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
