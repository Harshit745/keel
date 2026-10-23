import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models/reflection_entry.dart';
import 'ui/text_styles.dart';
import 'engines/reflection_validator.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  int energy = 3, focus = 3, distraction = 3, clarity = 3;
  final noteCtrl = TextEditingController();

  void save() {
    final result = ReflectionValidator.validate(noteCtrl.text);

    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    KeelState.saveReflection(
      ReflectionEntry(
        date: DateTime.now(),
        energy: energy,
        focus: focus,
        distraction: distraction,
        clarity: clarity,
        note: noteCtrl.text,
      ),
    );

    Navigator.pop(context);
  }

  Widget slider(String label, int v, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: $v", style: LifeText.section),
        Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: v.toDouble(),
          onChanged: (x) => setState(() => onChanged(x.round())),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reflection")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            slider("Energy", energy, (v) => energy = v),
            slider("Focus", focus, (v) => focus = v),
            slider("Distraction", distraction, (v) => distraction = v),
            slider("Clarity", clarity, (v) => clarity = v),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Note"),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: save,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
