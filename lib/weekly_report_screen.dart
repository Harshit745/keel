import 'package:flutter/material.dart';
import 'app_state.dart';
import 'ui/text_styles.dart';
import 'weekly_report_engine.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final narrative =
    WeeklyReportEngine.generate(KeelState.history);

    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Report")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            narrative.text,
            style: LifeText.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
