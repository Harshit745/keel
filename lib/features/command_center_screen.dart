import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  EnergyLevel _currentEnergy = EnergyLevel.medium;

  @override
  Widget build(BuildContext context) {
    final priorities = LifeFeatureState.topPriorities();
    final suggested = LifeFeatureState.suggestedTasks(_currentEnergy);
    final calendar = [...LifeFeatureState.calendarItems]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Command Center')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const FeatureSectionTitle('Top 3 Priorities'),
          FeatureCard(
            child: priorities.isEmpty
                ? const EmptyStateNote('No open priorities yet.')
                : Column(
                    children: priorities
                        .map(
                          (task) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: task.isDone,
                            onChanged: (_) {
                              setState(() => LifeFeatureState.toggleTask(task.id));
                            },
                            title: Text(task.title),
                            subtitle: Text(
                              '${task.context} • ${LifeFeatureState.formatDateTime(task.due)}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          const FeatureSectionTitle('Calendar Snapshot'),
          FeatureCard(
            child: calendar.isEmpty
                ? const EmptyStateNote('No calendar events added.')
                : Column(
                    children: calendar
                        .map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today, size: 18),
                            title: Text(item.title),
                            subtitle: Text(
                              LifeFeatureState.formatDateTime(item.startsAt),
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          const FeatureSectionTitle('Habits and Streaks'),
          FeatureCard(
            child: Column(
              children: LifeFeatureState.habits
                  .map(
                    (habit) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: habit.completedToday,
                      onChanged: (_) {
                        setState(() => LifeFeatureState.toggleHabit(habit.id));
                      },
                      title: Text(habit.name),
                      subtitle: Text(
                        'Streak: ${habit.streak} • Grace skips left: ${habit.graceSkipsRemaining}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          const FeatureSectionTitle('Energy-Based Planning'),
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Current energy:'),
                    const SizedBox(width: 12),
                    DropdownButton<EnergyLevel>(
                      value: _currentEnergy,
                      dropdownColor: const Color(0xFF141418),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _currentEnergy = value);
                      },
                      items: EnergyLevel.values
                          .map(
                            (level) => DropdownMenuItem<EnergyLevel>(
                              value: level,
                              child: Text(level.label),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (suggested.isEmpty)
                  const EmptyStateNote('No suggested tasks for this energy level.')
                else
                  ...suggested.map(
                    (task) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt, size: 18),
                      title: Text(task.title),
                      subtitle: Text(
                        '${task.energy.label} energy • ${task.context}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          setState(() => LifeFeatureState.toggleTask(task.id));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final titleCtrl = TextEditingController();
    final contextCtrl = TextEditingController(text: 'Desk');
    var chosenEnergy = EnergyLevel.medium;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Task title'),
                  ),
                  TextField(
                    controller: contextCtrl,
                    decoration: const InputDecoration(labelText: 'Context'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<EnergyLevel>(
                    value: chosenEnergy,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => chosenEnergy = value);
                    },
                    items: EnergyLevel.values
                        .map(
                          (level) => DropdownMenuItem<EnergyLevel>(
                            value: level,
                            child: Text(level.label),
                          ),
                        )
                        .toList(),
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
                    if (titleCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    setState(() {
      LifeFeatureState.addTask(
        title: titleCtrl.text.trim(),
        context: contextCtrl.text.trim().isEmpty ? 'Desk' : contextCtrl.text.trim(),
        energy: chosenEnergy,
      );
    });
  }
}
