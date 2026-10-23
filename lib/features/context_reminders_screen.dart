import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class ContextRemindersScreen extends StatefulWidget {
  const ContextRemindersScreen({super.key});

  @override
  State<ContextRemindersScreen> createState() => _ContextRemindersScreenState();
}

class _ContextRemindersScreenState extends State<ContextRemindersScreen> {
  String _filterContext = 'All';

  @override
  Widget build(BuildContext context) {
    final reminders = LifeFeatureState.remindersForContext(_filterContext);

    return Scaffold(
      appBar: AppBar(title: const Text('Context-Aware Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.alarm_add),
        label: const Text('New Reminder'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          FeatureCard(
            child: Row(
              children: [
                const Text('Context filter:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filterContext,
                  dropdownColor: const Color(0xFF141418),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _filterContext = value);
                  },
                  items: LifeFeatureState.reminderContexts
                      .map((contextValue) => DropdownMenuItem<String>(
                            value: contextValue,
                            child: Text(contextValue),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (reminders.isEmpty)
            const FeatureCard(
              child: EmptyStateNote('No reminders for this context.'),
            )
          else
            ...reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FeatureCard(
                  child: CheckboxListTile(
                    value: reminder.done,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (_) {
                      setState(() => LifeFeatureState.toggleReminder(reminder.id));
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(reminder.text),
                    subtitle: Text(
                      '${reminder.context} • ${reminder.locationTag} • ${LifeFeatureState.formatTime(reminder.time)}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addReminder() async {
    final textCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Anywhere');
    var contextValue = 'Desk';
    TimeOfDay? time;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(labelText: 'Reminder text'),
                  ),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location tag'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: contextValue,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => contextValue = value);
                    },
                    items: LifeFeatureState.reminderContexts
                        .where((item) => item != 'All')
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Time: ${LifeFeatureState.formatTime(time)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: time ?? TimeOfDay.now(),
                          );
                          if (selected == null) {
                            return;
                          }
                          setDialogState(() => time = selected);
                        },
                        child: const Text('Set Time'),
                      ),
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
                    if (textCtrl.text.trim().isEmpty) {
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

    if (save != true) {
      return;
    }

    setState(() {
      LifeFeatureState.addReminder(
        text: textCtrl.text.trim(),
        context: contextValue,
        locationTag: locationCtrl.text.trim().isEmpty ? 'Anywhere' : locationCtrl.text.trim(),
        time: time,
      );
      _filterContext = contextValue;
    });
  }
}
