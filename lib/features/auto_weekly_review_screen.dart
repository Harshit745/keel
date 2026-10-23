import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class AutoWeeklyReviewScreen extends StatefulWidget {
  const AutoWeeklyReviewScreen({super.key});

  @override
  State<AutoWeeklyReviewScreen> createState() => _AutoWeeklyReviewScreenState();
}

class _AutoWeeklyReviewScreenState extends State<AutoWeeklyReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final summary = LifeFeatureState.generateWeeklyReview();

    return Scaffold(
      appBar: AppBar(title: const Text('Auto Weekly Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Narrative',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(summary.narrative, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FeatureCard(
            child: Column(
              children: [
                _metricRow('Completed tasks', '${summary.completedTasks}'),
                _metricRow('Remaining tasks', '${summary.remainingTasks}'),
                _metricRow('Life area average', '${summary.lifeAreaAverage.toStringAsFixed(1)}/10'),
                _metricRow('Focus sessions', '${summary.focusSessions}'),
                _metricRow(
                  'Focus completion',
                  '${(summary.focusCompletionRate * 100).toStringAsFixed(0)}%',
                ),
                _metricRow('Journal entries', '${summary.journalEntries}'),
                _metricRow('Reflection index avg', '${summary.averageReflectionIndex}'),
                _metricRow('Pending decision reviews', '${summary.pendingDecisionReviews}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Recommended Next Steps'),
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: summary.nextWeekPriorities
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5, right: 8),
                            child: Icon(Icons.arrow_right, size: 16),
                          ),
                          Expanded(
                            child: Text(item, style: const TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
