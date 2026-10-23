import 'package:flutter/material.dart';

import 'app_state.dart';
import 'features/accountability_mode_screen.dart';
import 'features/auto_weekly_review_screen.dart';
import 'features/command_center_screen.dart';
import 'features/context_reminders_screen.dart';
import 'features/decision_journal_screen.dart';
import 'features/focus_session_screen.dart';
import 'features/goal_breakdown_screen.dart';
import 'features/knowledge_vault_screen.dart';
import 'features/life_areas_scorecard_screen.dart';
import 'features/reflection_journal_prompts_screen.dart';
import 'features/routine_builder_screen.dart';
import 'insight_engine.dart';
import 'reflection.dart';
import 'reflection_charts.dart';
import 'reflection_history.dart';
import 'ui/text_styles.dart';
import 'weekly_report_screen.dart';
import 'widgets/index_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final today = KeelState.today;

    return Scaffold(
      appBar: AppBar(title: const Text('Keel')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const Text('Today', style: LifeText.section),
          const SizedBox(height: 16),
          Center(
            child: IndexRing(value: today?.index ?? 0),
          ),
          const SizedBox(height: 24),
          const _InsightCard(),
          const SizedBox(height: 28),
          const Text('Core Reflection', style: LifeText.section),
          const SizedBox(height: 10),
          _ActionTile(
            label: 'Reflect',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReflectionScreen()),
              );
              setState(() {});
            },
          ),
          _ActionTile(
            label: 'History',
            onTap: () => _go(const HistoryScreen()),
          ),
          _ActionTile(
            label: 'Charts',
            onTap: () => _go(const ChartsScreen()),
          ),
          _ActionTile(
            label: 'Weekly Report',
            onTap: () => _go(const WeeklyReportScreen()),
          ),
          const SizedBox(height: 18),
          const Text('New Features', style: LifeText.section),
          const SizedBox(height: 10),
          _ActionTile(
            label: 'Daily Command Center',
            onTap: () => _go(const CommandCenterScreen()),
          ),
          _ActionTile(
            label: 'Life Areas Scorecard',
            onTap: () => _go(const LifeAreasScorecardScreen()),
          ),
          _ActionTile(
            label: 'Goal-to-Task Breakdown',
            onTap: () => _go(const GoalBreakdownScreen()),
          ),
          _ActionTile(
            label: 'Smart Routine Builder',
            onTap: () => _go(const RoutineBuilderScreen()),
          ),
          _ActionTile(
            label: 'Focus Sessions + Distraction Log',
            onTap: () => _go(const FocusSessionScreen()),
          ),
          _ActionTile(
            label: 'Reflection Journal Prompts',
            onTap: () => _go(const ReflectionJournalPromptsScreen()),
          ),
          _ActionTile(
            label: 'Decision Journal',
            onTap: () => _go(const DecisionJournalScreen()),
          ),
          _ActionTile(
            label: 'Auto Weekly Review',
            onTap: () => _go(const AutoWeeklyReviewScreen()),
          ),
          _ActionTile(
            label: 'Context-Aware Reminders',
            onTap: () => _go(const ContextRemindersScreen()),
          ),
          _ActionTile(
            label: 'Personal Knowledge Vault',
            onTap: () => _go(const KnowledgeVaultScreen()),
          ),
          _ActionTile(
            label: 'Accountability Mode',
            onTap: () => _go(const AccountabilityModeScreen()),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _go(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        InsightEngine.primary(),
        style: LifeText.body,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: LifeText.button)),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
