class WeeklyReport {
  final String insight; // main AI paragraph
  final List<String> patterns; // list of pattern strings
  final double avgFounderScore;
  final double avgBuildScore;
  final double avgSelfScore;
  final String buildTrend; // 'up', 'down', 'stable'
  final String selfTrend;
  final bool burnoutRisk;
  final String? burnoutReason;
  final List<String> actions; // 3 action items
  final String strongestPattern;
  final String biggestRisk;
  final String biggestOpportunity;
  final String nextWeekFocus;
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklyReport({
    required this.insight,
    required this.patterns,
    required this.avgFounderScore,
    required this.avgBuildScore,
    required this.avgSelfScore,
    required this.buildTrend,
    required this.selfTrend,
    required this.burnoutRisk,
    this.burnoutReason,
    required this.actions,
    required this.strongestPattern,
    required this.biggestRisk,
    required this.biggestOpportunity,
    required this.nextWeekFocus,
    required this.weekStart,
    required this.weekEnd,
  });
}
