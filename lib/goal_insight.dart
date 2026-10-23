import '../app_state.dart';
import '../goals.dart';

class GoalInsightEngine {
  static String generate() {
    if (KeelState.history.length < 3) {
      return "Insufficient data for goal correlation.";
    }

    final activeGoals = GoalState.goals.where((g) => !g.completed).toList();

    if (activeGoals.isEmpty) {
      return "No active goals found.";
    }

    final avgIndex = KeelState.history
        .take(3)
        .map((e) => e.index)
        .reduce((a, b) => a + b) /
        3;

    if (avgIndex >= 70) {
      return "Your current habits are supporting your active goals.";
    }

    return "Your reflection trends suggest misalignment with goals.";
  }
}
