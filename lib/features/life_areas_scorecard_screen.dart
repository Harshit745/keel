import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class LifeAreasScorecardScreen extends StatefulWidget {
  const LifeAreasScorecardScreen({super.key});

  @override
  State<LifeAreasScorecardScreen> createState() => _LifeAreasScorecardScreenState();
}

class _LifeAreasScorecardScreenState extends State<LifeAreasScorecardScreen> {
  @override
  Widget build(BuildContext context) {
    final average = LifeFeatureState.lifeAreaAverage();

    return Scaffold(
      appBar: AppBar(title: const Text('Life Areas Scorecard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance score: ${average.toStringAsFixed(1)}/10',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _balanceMessage(average),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...LifeFeatureState.lifeAreas.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ${entry.value}/10',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: entry.value.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          LifeFeatureState.setLifeAreaScore(entry.key, value.round());
                        });
                      },
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

  String _balanceMessage(double average) {
    if (average >= 7.5) {
      return 'You are in a strong balanced zone. Keep this weekly cadence.';
    }
    if (average >= 6) {
      return 'Progress is stable. Raise one weaker area to improve overall stability.';
    }
    return 'Imbalance is visible. Protect energy and improve one area at a time.';
  }
}
