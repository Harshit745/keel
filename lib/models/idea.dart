import 'package:hive/hive.dart';

part 'idea.g.dart';

@HiveType(typeId: 2)
class Idea {
  Idea({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category = 'other',
    this.isPinned = false,
    this.isArchived = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String category;

  @HiveField(4)
  bool isPinned;

  @HiveField(5)
  bool isArchived;
}
