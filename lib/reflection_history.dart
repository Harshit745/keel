import 'package:flutter/material.dart';
import 'app_state.dart';
import 'ui/text_styles.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = KeelState.history;

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: h.length,
        itemBuilder: (_, i) {
          final e = h[i];
          return ListTile(
            title: Text(
              "${e.date.toLocal()}".split(' ')[0],
              style: LifeText.button,
            ),
            subtitle: Text(
              "Index: ${e.index}",
              style: LifeText.body,
            ),
          );
        },
      ),
    );
  }
}
