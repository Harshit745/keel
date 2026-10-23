import 'package:flutter/material.dart';

import '../app_state.dart';

enum EnergyLevel { low, medium, high }

extension EnergyLevelLabel on EnergyLevel {
  String get label {
    switch (this) {
      case EnergyLevel.low:
        return 'Low';
      case EnergyLevel.medium:
        return 'Medium';
      case EnergyLevel.high:
        return 'High';
    }
  }
}

class CommandTask {
  final String id;
  final String title;
  final EnergyLevel energy;
  final String context;
  final DateTime due;
  final String? goalId;
  bool isDone;

  CommandTask({
    required this.id,
    required this.title,
    required this.energy,
    required this.context,
    required this.due,
    this.goalId,
    this.isDone = false,
  });
}

class HabitTrack {
  final String id;
  final String name;
  int streak;
  int graceSkipsRemaining;
  bool completedToday;

  HabitTrack({
    required this.id,
    required this.name,
    this.streak = 0,
    this.graceSkipsRemaining = 2,
    this.completedToday = false,
  });
}

class CalendarItem {
  final String id;
  final String title;
  final DateTime startsAt;

  CalendarItem({
    required this.id,
    required this.title,
    required this.startsAt,
  });
}

class GoalBreakdown {
  final String id;
  final String title;
  final String vision;
  final List<String> weeklyTasks;
  final List<String> dailyTasks;
  bool completed;

  GoalBreakdown({
    required this.id,
    required this.title,
    required this.vision,
    required this.weeklyTasks,
    required this.dailyTasks,
    this.completed = false,
  });
}

class RoutineItem {
  final String id;
  final String name;
  final bool isMorning;
  int streak;
  int graceSkipsRemaining;
  bool completedToday;

  RoutineItem({
    required this.id,
    required this.name,
    required this.isMorning,
    this.streak = 0,
    this.graceSkipsRemaining = 2,
    this.completedToday = false,
  });
}

class DistractionLog {
  final String id;
  final DateTime createdAt;
  final String trigger;

  DistractionLog({
    required this.id,
    required this.createdAt,
    required this.trigger,
  });
}

class FocusSessionRecord {
  final String id;
  final DateTime startedAt;
  final int plannedMinutes;
  final int completedMinutes;

  FocusSessionRecord({
    required this.id,
    required this.startedAt,
    required this.plannedMinutes,
    required this.completedMinutes,
  });
}

class JournalEntry {
  final String id;
  final DateTime createdAt;
  final String prompt;
  final String response;

  JournalEntry({
    required this.id,
    required this.createdAt,
    required this.prompt,
    required this.response,
  });
}

class DecisionEntry {
  final String id;
  final String title;
  final String expectedOutcome;
  final DateTime reviewOn;
  String? actualOutcome;
  bool reviewed;

  DecisionEntry({
    required this.id,
    required this.title,
    required this.expectedOutcome,
    required this.reviewOn,
    this.actualOutcome,
    this.reviewed = false,
  });
}

class ReminderEntry {
  final String id;
  final String text;
  final String context;
  final String locationTag;
  final TimeOfDay? time;
  bool done;

  ReminderEntry({
    required this.id,
    required this.text,
    required this.context,
    required this.locationTag,
    required this.time,
    this.done = false,
  });
}

class KnowledgeEntry {
  final String id;
  final String title;
  final String content;
  final String linkedGoal;
  final DateTime createdAt;

  KnowledgeEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.linkedGoal,
    required this.createdAt,
  });
}

class AccountabilitySnapshot {
  final String id;
  final DateTime createdAt;
  final String recipient;
  final String summary;
  bool sent;

  AccountabilitySnapshot({
    required this.id,
    required this.createdAt,
    required this.recipient,
    required this.summary,
    this.sent = false,
  });
}

class WeeklyReviewSummary {
  final String narrative;
  final int completedTasks;
  final int remainingTasks;
  final double lifeAreaAverage;
  final int focusSessions;
  final double focusCompletionRate;
  final int journalEntries;
  final int averageReflectionIndex;
  final int pendingDecisionReviews;
  final List<String> nextWeekPriorities;

  WeeklyReviewSummary({
    required this.narrative,
    required this.completedTasks,
    required this.remainingTasks,
    required this.lifeAreaAverage,
    required this.focusSessions,
    required this.focusCompletionRate,
    required this.journalEntries,
    required this.averageReflectionIndex,
    required this.pendingDecisionReviews,
    required this.nextWeekPriorities,
  });
}

class LifeFeatureState {
  static int _counter = 1000;
  static int _promptCursor = 0;

  static final List<CommandTask> tasks = [
    CommandTask(
      id: 'task-1',
      title: 'Plan the day in 10 minutes',
      energy: EnergyLevel.low,
      context: 'Morning',
      due: DateTime.now().add(const Duration(hours: 1)),
    ),
    CommandTask(
      id: 'task-2',
      title: 'Deep work block for main project',
      energy: EnergyLevel.high,
      context: 'Desk',
      due: DateTime.now().add(const Duration(hours: 4)),
    ),
    CommandTask(
      id: 'task-3',
      title: 'Review expenses and update tracker',
      energy: EnergyLevel.medium,
      context: 'Evening',
      due: DateTime.now().add(const Duration(hours: 8)),
    ),
  ];

  static final List<HabitTrack> habits = [
    HabitTrack(id: 'habit-1', name: 'Morning walk', streak: 4),
    HabitTrack(id: 'habit-2', name: 'Read for 20 minutes', streak: 6),
    HabitTrack(id: 'habit-3', name: 'No social media before lunch', streak: 2),
  ];

  static final List<CalendarItem> calendarItems = [
    CalendarItem(
      id: 'cal-1',
      title: 'Team sync',
      startsAt: DateTime.now().add(const Duration(hours: 2)),
    ),
    CalendarItem(
      id: 'cal-2',
      title: 'Workout',
      startsAt: DateTime.now().add(const Duration(hours: 6)),
    ),
  ];

  static final Map<String, int> lifeAreas = {
    'Health': 7,
    'Work': 6,
    'Relationships': 5,
    'Learning': 6,
    'Finances': 5,
  };

  static final List<GoalBreakdown> goals = [
    GoalBreakdown(
      id: 'goal-1',
      title: 'Improve Fitness',
      vision: 'Increase stamina and consistency in workouts.',
      weeklyTasks: const [
        'Schedule 4 workout slots',
        'Prep meals twice this week',
        'Track sleep for 7 days',
      ],
      dailyTasks: const [
        '30 minutes of movement',
        'Record one health metric',
      ],
    ),
    GoalBreakdown(
      id: 'goal-2',
      title: 'Ship Side Project',
      vision: 'Release MVP with consistent progress every week.',
      weeklyTasks: const [
        'Define one shippable milestone',
        'Run 2 deep work sessions',
        'Share one public update',
      ],
      dailyTasks: const [
        '25 minute feature sprint',
        'Write one implementation note',
      ],
    ),
  ];

  static final List<RoutineItem> routineItems = [
    RoutineItem(id: 'routine-1', name: 'Hydrate', isMorning: true, streak: 3),
    RoutineItem(id: 'routine-2', name: 'Plan top 3 priorities', isMorning: true, streak: 5),
    RoutineItem(id: 'routine-3', name: 'Screen-free wind down', isMorning: false, streak: 2),
  ];

  static final List<DistractionLog> distractionLogs = [];
  static final List<FocusSessionRecord> focusSessions = [];
  static final List<JournalEntry> journalEntries = [];
  static final List<DecisionEntry> decisions = [];
  static final List<ReminderEntry> reminders = [];

  static final List<String> reminderContexts = const [
    'All',
    'Desk',
    'Commute',
    'Evening',
    'Deep Work',
    'Errands',
  ];

  static final List<KnowledgeEntry> knowledgeEntries = [];
  static final List<AccountabilitySnapshot> snapshots = [];

  static final List<String> _journalPrompts = const [
    'What gave me energy today?',
    'What drained my focus and why?',
    'What is one thing I can simplify tomorrow?',
    'Where did I avoid discomfort, and what did it cost me?',
    'What am I proud of from today?',
  ];

  static String _nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }

  static List<CommandTask> topPriorities() {
    final ranked = tasks.where((task) => !task.isDone).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    return ranked.take(3).toList();
  }

  static List<CommandTask> suggestedTasks(EnergyLevel currentEnergy) {
    return tasks
        .where((task) => !task.isDone && task.energy.index <= currentEnergy.index)
        .toList();
  }

  static void toggleTask(String taskId) {
    final task = tasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) {
      return;
    }
    task.isDone = !task.isDone;
  }

  static CommandTask addTask({
    required String title,
    required String context,
    required EnergyLevel energy,
    DateTime? due,
    String? goalId,
  }) {
    final task = CommandTask(
      id: _nextId('task'),
      title: title,
      context: context,
      energy: energy,
      due: due ?? DateTime.now().add(const Duration(days: 1)),
      goalId: goalId,
    );
    tasks.add(task);
    return task;
  }

  static void toggleHabit(String habitId) {
    final habit = habits.where((item) => item.id == habitId).firstOrNull;
    if (habit == null) {
      return;
    }

    if (!habit.completedToday) {
      habit.completedToday = true;
      habit.streak += 1;
      return;
    }

    habit.completedToday = false;
    if (habit.graceSkipsRemaining > 0) {
      habit.graceSkipsRemaining -= 1;
    } else {
      habit.streak = 0;
    }
  }

  static HabitTrack addHabit(String name) {
    final habit = HabitTrack(id: _nextId('habit'), name: name);
    habits.add(habit);
    return habit;
  }

  static double lifeAreaAverage() {
    if (lifeAreas.isEmpty) {
      return 0;
    }
    final sum = lifeAreas.values.fold<int>(0, (acc, value) => acc + value);
    return sum / lifeAreas.length;
  }

  static void setLifeAreaScore(String area, int score) {
    lifeAreas[area] = score.clamp(0, 10).toInt();
  }

  static GoalBreakdown addGoal({
    required String title,
    required String vision,
  }) {
    final goal = GoalBreakdown(
      id: _nextId('goal'),
      title: title,
      vision: vision,
      weeklyTasks: [
        'Define a weekly milestone for $title',
        'Protect two focused sessions for $title',
        'Review blockers and remove one friction point',
      ],
      dailyTasks: [
        'Spend 25 minutes on $title',
        'Capture one measurable progress update for $title',
      ],
    );

    goals.add(goal);
    return goal;
  }

  static void toggleGoalCompletion(String goalId) {
    final goal = goals.where((item) => item.id == goalId).firstOrNull;
    if (goal == null) {
      return;
    }
    goal.completed = !goal.completed;
  }

  static int addDailyTasksFromGoal(String goalId) {
    final goal = goals.where((item) => item.id == goalId).firstOrNull;
    if (goal == null) {
      return 0;
    }

    var added = 0;
    for (final taskTitle in goal.dailyTasks) {
      final exists = tasks.any(
        (task) => task.goalId == goal.id && task.title.trim() == taskTitle.trim(),
      );
      if (exists) {
        continue;
      }
      addTask(
        title: taskTitle,
        context: 'Goal Work',
        energy: EnergyLevel.medium,
        due: DateTime.now().add(const Duration(days: 1)),
        goalId: goal.id,
      );
      added += 1;
    }
    return added;
  }

  static RoutineItem addRoutineItem({
    required String name,
    required bool isMorning,
  }) {
    final item = RoutineItem(
      id: _nextId('routine'),
      name: name,
      isMorning: isMorning,
    );
    routineItems.add(item);
    return item;
  }

  static void toggleRoutineItem(String routineId) {
    final item = routineItems.where((entry) => entry.id == routineId).firstOrNull;
    if (item == null) {
      return;
    }

    if (!item.completedToday) {
      item.completedToday = true;
      item.streak += 1;
      return;
    }

    item.completedToday = false;
    if (item.graceSkipsRemaining > 0) {
      item.graceSkipsRemaining -= 1;
    } else {
      item.streak = 0;
    }
  }

  static FocusSessionRecord logFocusSession({
    required int plannedMinutes,
    required int completedMinutes,
  }) {
    final session = FocusSessionRecord(
      id: _nextId('focus'),
      startedAt: DateTime.now(),
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
    );
    focusSessions.insert(0, session);
    return session;
  }

  static DistractionLog addDistractionLog(String trigger) {
    final log = DistractionLog(
      id: _nextId('distraction'),
      createdAt: DateTime.now(),
      trigger: trigger,
    );
    distractionLogs.insert(0, log);
    return log;
  }

  static double focusCompletionRate() {
    if (focusSessions.isEmpty) {
      return 0;
    }

    final ratio = focusSessions
        .map((session) {
          if (session.plannedMinutes <= 0) {
            return 0.0;
          }
          return session.completedMinutes / session.plannedMinutes;
        })
        .reduce((a, b) => a + b);

    return (ratio / focusSessions.length).clamp(0, 1).toDouble();
  }

  static String nextJournalPrompt() {
    final prompt = _journalPrompts[_promptCursor % _journalPrompts.length];
    _promptCursor += 1;
    return prompt;
  }

  static JournalEntry addJournalEntry({
    required String prompt,
    required String response,
  }) {
    final entry = JournalEntry(
      id: _nextId('journal'),
      createdAt: DateTime.now(),
      prompt: prompt,
      response: response,
    );
    journalEntries.insert(0, entry);
    return entry;
  }

  static DecisionEntry addDecision({
    required String title,
    required String expectedOutcome,
    required DateTime reviewOn,
  }) {
    final entry = DecisionEntry(
      id: _nextId('decision'),
      title: title,
      expectedOutcome: expectedOutcome,
      reviewOn: reviewOn,
    );
    decisions.insert(0, entry);
    return entry;
  }

  static void reviewDecision({
    required String decisionId,
    required String actualOutcome,
  }) {
    final decision = decisions.where((item) => item.id == decisionId).firstOrNull;
    if (decision == null) {
      return;
    }

    decision.reviewed = true;
    decision.actualOutcome = actualOutcome;
  }

  static ReminderEntry addReminder({
    required String text,
    required String context,
    required String locationTag,
    required TimeOfDay? time,
  }) {
    final entry = ReminderEntry(
      id: _nextId('reminder'),
      text: text,
      context: context,
      locationTag: locationTag,
      time: time,
    );
    reminders.insert(0, entry);
    return entry;
  }

  static void toggleReminder(String reminderId) {
    final reminder = reminders.where((item) => item.id == reminderId).firstOrNull;
    if (reminder == null) {
      return;
    }
    reminder.done = !reminder.done;
  }

  static List<ReminderEntry> remindersForContext(String context) {
    if (context == 'All') {
      return reminders;
    }
    return reminders.where((item) => item.context == context).toList();
  }

  static KnowledgeEntry addKnowledgeEntry({
    required String title,
    required String content,
    required String linkedGoal,
  }) {
    final entry = KnowledgeEntry(
      id: _nextId('knowledge'),
      title: title,
      content: content,
      linkedGoal: linkedGoal,
      createdAt: DateTime.now(),
    );
    knowledgeEntries.insert(0, entry);
    return entry;
  }

  static AccountabilitySnapshot createSnapshot(String recipient) {
    final summary = _buildSnapshotSummary();
    final snapshot = AccountabilitySnapshot(
      id: _nextId('snapshot'),
      createdAt: DateTime.now(),
      recipient: recipient,
      summary: summary,
    );
    snapshots.insert(0, snapshot);
    return snapshot;
  }

  static void markSnapshotSent(String snapshotId) {
    final snapshot = snapshots.where((item) => item.id == snapshotId).firstOrNull;
    if (snapshot == null) {
      return;
    }
    snapshot.sent = true;
  }

  static WeeklyReviewSummary generateWeeklyReview() {
    final completedTasks = tasks.where((item) => item.isDone).length;
    final remainingTasks = tasks.length - completedTasks;
    final averageLifeArea = lifeAreaAverage();
    final focusRate = focusCompletionRate();
    final pendingDecisionReviews = decisions.where((item) => !item.reviewed).length;

    final reflectionHistory = KeelState.history;
    var averageReflection = 0;
    if (reflectionHistory.isNotEmpty) {
      final total = reflectionHistory.fold<int>(0, (sum, entry) => sum + entry.index);
      averageReflection = (total / reflectionHistory.length).round();
    }

    String narrative;
    if (completedTasks >= remainingTasks && focusRate >= 0.75) {
      narrative = 'Strong execution week. Keep the current cadence and protect focus windows.';
    } else if (averageLifeArea >= 6 && focusRate >= 0.5) {
      narrative = 'Balanced but uneven week. You are progressing, but consistency can improve.';
    } else {
      narrative = 'Recovery-focused week. Simplify commitments and rebuild momentum with small wins.';
    }

    final nextWeekPriorities = <String>[];
    nextWeekPriorities.add('Complete the top 3 priorities before adding new tasks.');

    if (averageLifeArea < 6) {
      nextWeekPriorities.add('Raise at least one low life-area score by 1 point.');
    }

    if (focusRate < 0.7) {
      nextWeekPriorities.add('Run at least three uninterrupted focus sessions.');
    }

    if (pendingDecisionReviews > 0) {
      nextWeekPriorities.add('Close open decision reviews to improve judgment loops.');
    }

    return WeeklyReviewSummary(
      narrative: narrative,
      completedTasks: completedTasks,
      remainingTasks: remainingTasks,
      lifeAreaAverage: averageLifeArea,
      focusSessions: focusSessions.length,
      focusCompletionRate: focusRate,
      journalEntries: journalEntries.length,
      averageReflectionIndex: averageReflection,
      pendingDecisionReviews: pendingDecisionReviews,
      nextWeekPriorities: nextWeekPriorities,
    );
  }

  static String formatDateTime(DateTime dateTime) {
    final month = _monthName(dateTime.month);
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour24 = dateTime.hour;
    final hour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour24 < 12 ? 'AM' : 'PM';
    return '$month $day, $year $hour:$minute $period';
  }

  static String formatDate(DateTime dateTime) {
    final month = _monthName(dateTime.month);
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  static String formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Any time';
    }
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String _buildSnapshotSummary() {
    final completedTasks = tasks.where((task) => task.isDone).length;
    final totalTasks = tasks.length;
    final lifeScore = lifeAreaAverage().toStringAsFixed(1);
    final latestJournal = journalEntries.firstOrNull?.response;

    final summaryParts = [
      'Tasks: $completedTasks/$totalTasks complete',
      'Life area avg: $lifeScore/10',
      'Focus sessions: ${focusSessions.length}',
    ];

    if (latestJournal != null && latestJournal.isNotEmpty) {
      final trimmed = latestJournal.length > 80
          ? '${latestJournal.substring(0, 80)}...'
          : latestJournal;
      summaryParts.add('Latest reflection: "$trimmed"');
    }

    return summaryParts.join(' | ');
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
