import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class KnowledgeVaultScreen extends StatefulWidget {
  const KnowledgeVaultScreen({super.key});

  @override
  State<KnowledgeVaultScreen> createState() => _KnowledgeVaultScreenState();
}

class _KnowledgeVaultScreenState extends State<KnowledgeVaultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Knowledge Vault')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addKnowledge,
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add Note'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (LifeFeatureState.knowledgeEntries.isEmpty)
            const FeatureCard(
              child: EmptyStateNote('No knowledge notes yet. Capture one insight and link it to a goal.'),
            )
          else
            ...LifeFeatureState.knowledgeEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FeatureCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.content, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        'Linked goal: ${entry.linkedGoal} • ${LifeFeatureState.formatDateTime(entry.createdAt)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
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

  Future<void> _addKnowledge() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final availableGoals = [
      'General',
      ...LifeFeatureState.goals.map((goal) => goal.title),
    ];
    var selectedGoal = availableGoals.first;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Knowledge Note'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Insight / note'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedGoal,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => selectedGoal = value);
                    },
                    items: availableGoals
                        .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
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
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
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
      LifeFeatureState.addKnowledgeEntry(
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        linkedGoal: selectedGoal,
      );
    });
  }
}
