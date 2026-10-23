import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/score_service.dart';

class ScoreCardWidget extends StatelessWidget {
  const ScoreCardWidget({
    super.key,
    required this.repaintKey,
    required this.founderScore,
    required this.buildScore,
    required this.selfScore,
    required this.winOfDay,
    required this.weekLabel,
    required this.aiInsight,
    required this.isLoadingInsight,
  });

  static const Color _card = Color(0xFF111111);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _selfAccent = Color(0xFF00E5FF);
  static const Color _muted = Color(0x99FFFFFF);

  final GlobalKey repaintKey;
  final int founderScore;
  final int buildScore;
  final int selfScore;
  final String winOfDay;
  final String weekLabel;
  final String aiInsight;
  final bool isLoadingInsight;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text(
                  'Keel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: <Widget>[
                Text(
                  founderScore.toString(),
                  style: const TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${ScoreService.getScoreLabel(founderScore)} ${ScoreService.getScoreEmoji(founderScore)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  weekLabel,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 0.5, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 18),
            _MetricRow(
              icon: Icons.rocket_launch,
              label: 'Build Score',
              value: buildScore.toString(),
              color: _accent,
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: Icons.person_outline,
              label: 'Self Score',
              value: selfScore.toString(),
              color: _selfAccent,
            ),
            if (winOfDay.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 18),
              Text(
                'WIN OF THE DAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _accent.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '"$winOfDay"',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 18),
            Container(height: 0.5, color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 18),
            Text(
              isLoadingInsight
                  ? 'Analysing your week...'
                  : (aiInsight.isEmpty ? 'Keep showing up.' : aiInsight),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'keel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
