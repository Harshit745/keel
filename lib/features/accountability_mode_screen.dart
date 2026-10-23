import 'package:flutter/material.dart';

import 'feature_ui.dart';
import 'life_feature_state.dart';

class AccountabilityModeScreen extends StatefulWidget {
  const AccountabilityModeScreen({super.key});

  @override
  State<AccountabilityModeScreen> createState() => _AccountabilityModeScreenState();
}

class _AccountabilityModeScreenState extends State<AccountabilityModeScreen> {
  final TextEditingController _recipientCtrl = TextEditingController();

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accountability Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FeatureSectionTitle('Create Progress Snapshot'),
          FeatureCard(
            child: Column(
              children: [
                TextField(
                  controller: _recipientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Friend / coach email',
                    hintText: 'example@domain.com',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _createSnapshot,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Generate Snapshot'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FeatureSectionTitle('Snapshots'),
          if (LifeFeatureState.snapshots.isEmpty)
            const FeatureCard(child: EmptyStateNote('No snapshots generated yet.'))
          else
            ...LifeFeatureState.snapshots.map(
              (snapshot) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FeatureCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              snapshot.recipient,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (snapshot.sent)
                            const Icon(Icons.check_circle, color: Colors.greenAccent)
                          else
                            OutlinedButton(
                              onPressed: () {
                                setState(() => LifeFeatureState.markSnapshotSent(snapshot.id));
                              },
                              child: const Text('Mark as Sent'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(snapshot.summary, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        LifeFeatureState.formatDateTime(snapshot.createdAt),
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

  void _createSnapshot() {
    final recipient = _recipientCtrl.text.trim();
    if (recipient.isEmpty) {
      return;
    }

    setState(() {
      LifeFeatureState.createSnapshot(recipient);
      _recipientCtrl.clear();
    });
  }
}
