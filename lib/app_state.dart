import 'package:hive/hive.dart';
import 'models/reflection_entry.dart';
import 'engines/self_trust_engine.dart';

class KeelState {
  static late Box<ReflectionEntry> _box;

  // Derived metrics
  static int selfTrust = 50;

  /// Call this once in main()
  static Future<void> init() async {
    _box = Hive.box<ReflectionEntry>('reflections');
    _recompute();
  }

  /// All reflections (latest first)
  static List<ReflectionEntry> get history =>
      _box.values.toList().reversed.toList();

  /// Today’s reflection (if exists)
  static ReflectionEntry? get today {
    final now = DateTime.now();
    try {
      return history.firstWhere(
            (e) =>
        e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Save or overwrite today’s reflection
  static void saveReflection(ReflectionEntry entry) {
    final key =
        "${entry.date.year}-${entry.date.month}-${entry.date.day}";
    _box.put(key, entry);
    _recompute();
  }

  /// Recalculate all derived state
  static void _recompute() {
    final all = history.reversed.toList(); // chronological
    selfTrust = SelfTrustEngine.compute(all);
  }
}
