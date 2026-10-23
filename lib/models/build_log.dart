import 'package:hive/hive.dart';

part 'build_log.g.dart';

@HiveType(typeId: 0)
class BuildLog {
  BuildLog({
    this.id = '',
    required this.date,
    this.tasksShipped = 0,
    this.talkedToUser = false,
    this.movedNeedle = false,
    this.revenueAdded = 0.0,
    this.ideasCaptured = const <String>[],
    this.winOfDay = '',
    this.buildScore = 0,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int tasksShipped;

  @HiveField(3)
  bool talkedToUser;

  @HiveField(4)
  bool movedNeedle;

  @HiveField(5)
  double revenueAdded;

  @HiveField(6)
  List<String> ideasCaptured;

  @HiveField(7)
  String winOfDay;

  @HiveField(8)
  int buildScore;

  static String keyForDate(DateTime date) {
    return 'build_${date.year}_${date.month}_${date.day}';
  }
}
