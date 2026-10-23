import 'package:keel/app_state.dart';
import 'package:keel/models/goal.dart';

class GoalState {
  static final List<Goal> goals = [
    Goal(id: '1', title: 'Fitness'),
    Goal(id: '2', title: 'Study'),
    Goal(id: '3', title: 'Mental Health'),
  ];
}

class GoalInsightEngine {
  static String generate() {
    if (KeelState.history.length < 3) {
      return "Not enough data to evaluate goal alignment.";
    }

    final activeGoals =
    GoalState.goals.where((g) => !g.completed).toList();

    if (activeGoals.isEmpty) {
      return "All goals completed. Excellent discipline.";
    }

    final avgIndex = KeelState.history
        .take(3)
        .map((e) => e.index)
        .reduce((a, b) => a + b) /
        3;

    if (avgIndex >= 70) {
      return "Your current habits support your goals.";
    }

    return "Your recent patterns are misaligned with your goals.";
  }
}
