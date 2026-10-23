import 'dart:async';

import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  int _plannedMinutes = 25;
  int _secondsRemaining = 0;
  Timer? _timer;
  final TextEditingController _distractionCtrl = TextEditingController();

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    _distractionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusRate = LifeFeatureState.focusCompletionRate() * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Session + Distraction Log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _running ? 'Session in progress' : 'Ready for a focus session',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_running ? _secondsRemaining : _plannedMinutes * 60),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Completion rate: ${focusRate.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                if (!_running)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planned: $_plannedMinutes min'),
                      Slider(
                        value: _plannedMinutes.toDouble(),
                        min: 10,
                        max: 90,
                        divisions: 16,
                        onChanged: (value) {
                          setState(() => _plannedMinutes = value.round());
                        },
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _running ? null : _startSession,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _running ? _stopSession : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Log a Distraction Trigger'),
          FeatureCard(
            child: Column(
              children: [
                TextField(
                  controller: _distractionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'What distracted you?',
                    hintText: 'Example: phone notification',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _addDistraction,
                    child: const Text('Log'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Recent Distractions'),
          FeatureCard(
            child: LifeFeatureState.distractionLogs.isEmpty
                ? const EmptyStateNote('No distractions logged yet.')
                : Column(
                    children: LifeFeatureState.distractionLogs
                        .take(6)
                        .map(
                          (log) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(log.trigger),
                            subtitle: Text(
                              LifeFeatureState.formatDateTime(log.createdAt),
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Session History'),
          FeatureCard(
            child: LifeFeatureState.focusSessions.isEmpty
                ? const EmptyStateNote('No sessions completed yet.')
                : Column(
                    children: LifeFeatureState.focusSessions
                        .take(8)
                        .map(
                          (session) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.timer),
                            title: Text(
                              '${session.completedMinutes}/${session.plannedMinutes} minutes',
                            ),
                            subtitle: Text(
                              LifeFeatureState.formatDateTime(session.startedAt),
                              style: const TextStyle(color: Colors.white60),
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

  void _startSession() {
    if (_running) {
      return;
    }

    setState(() {
      _secondsRemaining = _plannedMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        _finishSession();
        return;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  void _stopSession() {
    if (!_running) {
      return;
    }
    final elapsedMinutes = (_plannedMinutes * 60 - _secondsRemaining) ~/ 60;
    _timer?.cancel();
    _timer = null;
    setState(() {
      LifeFeatureState.logFocusSession(
        plannedMinutes: _plannedMinutes,
        completedMinutes: elapsedMinutes,
      );
      _secondsRemaining = 0;
    });
  }

  void _finishSession() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _secondsRemaining = 0;
      LifeFeatureState.logFocusSession(
        plannedMinutes: _plannedMinutes,
        completedMinutes: _plannedMinutes,
      );
    });
  }

  void _addDistraction() {
    final text = _distractionCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      LifeFeatureState.addDistractionLog(text);
      _distractionCtrl.clear();
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
