import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final morning = LifeFeatureState.routineItems.where((item) => item.isMorning).toList();
    final evening = LifeFeatureState.routineItems.where((item) => !item.isMorning).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Routine Builder')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoutine,
        icon: const Icon(Icons.playlist_add),
        label: const Text('Add Routine Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const FeatureSectionTitle('Morning Routine'),
          FeatureCard(
            child: morning.isEmpty
                ? const EmptyStateNote('No morning items configured.')
                : Column(children: morning.map((item) => _routineTile(item)).toList()),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Evening Routine'),
          FeatureCard(
            child: evening.isEmpty
                ? const EmptyStateNote('No evening items configured.')
                : Column(children: evening.map((item) => _routineTile(item)).toList()),
          ),
        ],
      ),
    );
  }

  Widget _routineTile(RoutineItem item) {
    return SwitchListTile(
      value: item.completedToday,
      contentPadding: EdgeInsets.zero,
      onChanged: (_) {
        setState(() => LifeFeatureState.toggleRoutineItem(item.id));
      },
      title: Text(item.name),
      subtitle: Text(
        'Streak: ${item.streak} • Grace skips left: ${item.graceSkipsRemaining}',
        style: const TextStyle(color: Colors.white60),
      ),
    );
  }

  Future<void> _addRoutine() async {
    final nameCtrl = TextEditingController();
    var isMorning = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Routine Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Routine step'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Morning'),
                      const SizedBox(width: 8),
                      Switch(
                        value: isMorning,
                        onChanged: (value) {
                          setDialogState(() => isMorning = value);
                        },
                      ),
                      const Text('Evening'),
                    ],
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
                    if (nameCtrl.text.trim().isEmpty) {
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
      LifeFeatureState.addRoutineItem(name: nameCtrl.text.trim(), isMorning: isMorning);
    });
  }
}
