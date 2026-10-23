import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class ReflectionJournalPromptsScreen extends StatefulWidget {
  const ReflectionJournalPromptsScreen({super.key});

  @override
  State<ReflectionJournalPromptsScreen> createState() => _ReflectionJournalPromptsScreenState();
}

class _ReflectionJournalPromptsScreenState extends State<ReflectionJournalPromptsScreen> {
  late String _prompt;
  final TextEditingController _responseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prompt = LifeFeatureState.nextJournalPrompt();
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflection Journal Prompts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FeatureSectionTitle('Today\'s Prompt'),
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prompt,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _responseCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your reflection',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveEntry,
                        child: const Text('Save Reflection'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _prompt = LifeFeatureState.nextJournalPrompt());
                      },
                      child: const Text('Next Prompt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Recent Entries'),
          FeatureCard(
            child: LifeFeatureState.journalEntries.isEmpty
                ? const EmptyStateNote('No journal entries yet.')
                : Column(
                    children: LifeFeatureState.journalEntries
                        .take(8)
                        .map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.prompt),
                            subtitle: Text(
                              '${entry.response}\n${LifeFeatureState.formatDateTime(entry.createdAt)}',
                              style: const TextStyle(color: Colors.white70, height: 1.4),
                            ),
                            isThreeLine: true,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _saveEntry() {
    final response = _responseCtrl.text.trim();
    if (response.isEmpty) {
      return;
    }

    setState(() {
      LifeFeatureState.addJournalEntry(prompt: _prompt, response: response);
      _responseCtrl.clear();
      _prompt = LifeFeatureState.nextJournalPrompt();
    });
  }
}
