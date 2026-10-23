class ScoreService {
  // Build score (0-100): did you make progress today?
  static int calculateBuildScore({
    required int tasksShipped,
    required bool talkedToUser,
    required bool movedNeedle,
    required double revenueAdded,
  }) {
    // Tasks shipped (35 pts)
    int taskScore = (tasksShipped * 7).clamp(0, 35);

    // Talked to a user (25 pts) — most important habit for founders
    int userScore = talkedToUser ? 25 : 0;

    // Moved the needle (25 pts) — did the ONE thing
    int needleScore = movedNeedle ? 25 : 0;

    // Revenue (15 pts) — any revenue is a win
    int revenueScore = revenueAdded > 0 ? 15 : 0;

    return (taskScore + userScore + needleScore + revenueScore).clamp(0, 100);
  }

  // Self score (0-100): are you sustainable?
  static int calculateSelfScore({
    required double sleepHours,
    required int energyLevel,
    required int moodRating,
    required double moneySpent,
    required double dailyBudget,
    required bool exercised,
  }) {
    // Sleep (30 pts)
    int sleepScore;
    if (sleepHours >= 7) {
      sleepScore = 30;
    } else if (sleepHours >= 6) {
      sleepScore = 20;
    } else if (sleepHours >= 5) {
      sleepScore = 10;
    } else {
      sleepScore = 0;
    }

    // Energy (20 pts)
    int energyScore = ((energyLevel / 5) * 20).round();

    // Mood (20 pts)
    int moodScore = ((moodRating / 5) * 20).round();

    // Budget (20 pts)
    int budgetScore = (dailyBudget <= 0 || moneySpent <= dailyBudget) ? 20 : 5;

    // Exercise (10 pts)
    int exerciseScore = exercised ? 10 : 0;

    return (sleepScore + energyScore + moodScore + budgetScore + exerciseScore)
        .clamp(0, 100);
  }

  // FounderScore: weighted average
  static int calculateFounderScore(int buildScore, int selfScore) {
    // Build matters more (60/40) — you're here to build
    return ((buildScore * 0.6) + (selfScore * 0.4)).round().clamp(0, 100);
  }

  static String getKeelState({
    required int buildScore,
    required int selfScore,
  }) {
    if (buildScore >= 75 && selfScore >= 70) {
      return 'Locked in';
    }
    if (buildScore >= 70 && selfScore < 45) {
      return 'High output, low sustainability';
    }
    if (buildScore < 45 && selfScore >= 70) {
      return 'Recovered, but under-shipping';
    }
    if (buildScore < 45 && selfScore < 45) {
      return 'Recovery week';
    }
    if ((buildScore - selfScore).abs() <= 10 && buildScore < 65) {
      return 'Stable, but stagnant';
    }
    return 'Building momentum';
  }

  static String getScoreInsight({
    required int buildScore,
    required int selfScore,
    required int keelScore,
  }) {
    if (buildScore >= 75 && selfScore >= 70) {
      return 'You are shipping without breaking yourself. Protect the rhythm and keep pressure on the right work.';
    }
    if (buildScore >= 70 && selfScore < 45) {
      return 'You are forcing output through low recovery. Keep standards high, but tighten sleep and energy before you drift.';
    }
    if (buildScore < 45 && selfScore >= 70) {
      return 'Your foundation is better than your execution right now. Use the recovered energy to ship one meaningful thing today.';
    }
    if (buildScore < 45 && selfScore < 45) {
      return 'Both pillars are slipping. Strip today down to one win and one recovery move.';
    }
    if (keelScore >= 65) {
      return 'You have enough momentum to compound this week. Avoid distraction and keep the next action obvious.';
    }
    return 'The system is working, but it needs more clarity. Reduce friction and make today smaller and sharper.';
  }

  static String getNextAction({
    required int buildScore,
    required int selfScore,
  }) {
    if (buildScore < 45) {
      return 'Ship one concrete task before noon.';
    }
    if (selfScore < 45) {
      return 'Protect recovery first: sleep, food, movement, or a spending reset.';
    }
    if (buildScore >= 75 && selfScore >= 70) {
      return 'Turn today into leverage: one task that compounds tomorrow.';
    }
    return 'Keep the streak honest with one build move and one self move.';
  }

  static String getWeeklyTrendLabel({
    required int todayScore,
    required double weeklyAverage,
  }) {
    final double delta = todayScore - weeklyAverage;
    if (delta >= 12) {
      return 'up';
    }
    if (delta <= -12) {
      return 'down';
    }
    return 'stable';
  }

  static int calculateWeeklyFounderScore(List<int> dailyScores) {
    if (dailyScores.isEmpty) return 0;
    return (dailyScores.reduce((int a, int b) => a + b) / dailyScores.length)
        .round();
  }

  static String getScoreLabel(int score) {
    if (score >= 85) return 'Shipping';
    if (score >= 70) return 'Building';
    if (score >= 50) return 'Grinding';
    if (score >= 30) return 'Struggling';
    return 'Offline';
  }

  static String getScoreEmoji(int score) {
    if (score >= 85) return '🚀';
    if (score >= 70) return '🔨';
    if (score >= 50) return '⚡';
    if (score >= 30) return '😤';
    return '💤';
  }
}
