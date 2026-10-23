import 'package:hive/hive.dart';

part 'self_log.g.dart';

@HiveType(typeId: 1)
class SelfLog {
  SelfLog({
    this.id = '',
    required this.date,
    this.sleepHours = 0.0,
    this.energyLevel = 3,
    this.moodRating = 3,
    this.moneySpent = 0.0,
    this.dailyBudget = 1000.0,
    this.exercised = false,
    this.journalEntry = '',
    this.selfScore = 0,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double sleepHours;

  @HiveField(3)
  int energyLevel;

  @HiveField(4)
  int moodRating;

  @HiveField(5)
  double moneySpent;

  @HiveField(6)
  double dailyBudget;

  @HiveField(7)
  bool exercised;

  @HiveField(8)
  String journalEntry;

  @HiveField(9)
  int selfScore;

  static String keyForDate(DateTime date) {
    return 'self_${date.year}_${date.month}_${date.day}';
  }
}
