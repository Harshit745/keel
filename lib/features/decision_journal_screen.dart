import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class DecisionJournalScreen extends StatefulWidget {
  const DecisionJournalScreen({super.key});

  @override
  State<DecisionJournalScreen> createState() => _DecisionJournalScreenState();
}

class _DecisionJournalScreenState extends State<DecisionJournalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDecision,
        icon: const Icon(Icons.add_chart),
        label: const Text('Add Decision'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (LifeFeatureState.decisions.isEmpty)
            const FeatureCard(
              child: EmptyStateNote('No decisions logged yet.'),
            )
          else
            ...LifeFeatureState.decisions.map(
              (decision) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeatureCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              decision.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(
                            decision.reviewed ? Icons.check_circle : Icons.schedule,
                            color: decision.reviewed ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Expected: ${decision.expectedOutcome}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review on: ${LifeFeatureState.formatDate(decision.reviewOn)}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      if (decision.reviewed && decision.actualOutcome != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Actual: ${decision.actualOutcome}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (!decision.reviewed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: () => _captureOutcome(decision.id),
                            child: const Text('Record Outcome'),
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

  Future<void> _addDecision() async {
    final titleCtrl = TextEditingController();
    final expectedCtrl = TextEditingController();
    var reviewOn = DateTime.now().add(const Duration(days: 7));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Decision'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Decision'),
                  ),
                  TextField(
                    controller: expectedCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Expected outcome'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Review: ${LifeFeatureState.formatDate(reviewOn)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: reviewOn,
                          );
                          if (picked == null) {
                            return;
                          }
                          setDialogState(() => reviewOn = picked);
                        },
                        child: const Text('Pick Date'),
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
                    if (titleCtrl.text.trim().isEmpty || expectedCtrl.text.trim().isEmpty) {
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
      LifeFeatureState.addDecision(
        title: titleCtrl.text.trim(),
        expectedOutcome: expectedCtrl.text.trim(),
        reviewOn: reviewOn,
      );
    });
  }

  Future<void> _captureOutcome(String decisionId) async {
    final outcomeCtrl = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actual Outcome'),
        content: TextField(
          controller: outcomeCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'What actually happened?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (outcomeCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) {
      return;
    }

    setState(() {
      LifeFeatureState.reviewDecision(
        decisionId: decisionId,
        actualOutcome: outcomeCtrl.text.trim(),
      );
    });
  }
}
