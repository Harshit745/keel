import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class GoalBreakdownScreen extends StatefulWidget {
  const GoalBreakdownScreen({super.key});

  @override
  State<GoalBreakdownScreen> createState() => _GoalBreakdownScreenState();
}

class _GoalBreakdownScreenState extends State<GoalBreakdownScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal-to-Task Breakdown')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoal,
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Add Goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (LifeFeatureState.goals.isEmpty)
            const FeatureCard(
              child: EmptyStateNote('No goals yet. Add one to auto-generate weekly and daily tasks.'),
            )
          else
            ...LifeFeatureState.goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeatureCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Checkbox(
                            value: goal.completed,
                            onChanged: (_) {
                              setState(() => LifeFeatureState.toggleGoalCompletion(goal.id));
                            },
                          ),
                        ],
                      ),
                      Text(
                        goal.vision,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      const Text('Weekly steps', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...goal.weeklyTasks.map((task) => _taskLine(task)),
                      const SizedBox(height: 10),
                      const Text('Daily actions', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...goal.dailyTasks.map((task) => _taskLine(task)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final added = LifeFeatureState.addDailyTasksFromGoal(goal.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$added daily tasks added to Command Center.')),
                            );
                            setState(() {});
                          },
                          icon: const Icon(Icons.playlist_add_check),
                          label: const Text('Push Daily Tasks'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _taskLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 7, color: Colors.white54),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Future<void> _addGoal() async {
    final titleCtrl = TextEditingController();
    final visionCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Goal title'),
            ),
            TextField(
              controller: visionCtrl,
              decoration: const InputDecoration(labelText: 'Vision'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || visionCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (saved != true) {
      return;
    }

    setState(() {
      LifeFeatureState.addGoal(
        title: titleCtrl.text.trim(),
        vision: visionCtrl.text.trim(),
      );
    });
  }
}
