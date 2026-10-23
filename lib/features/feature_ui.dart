import 'package:flutter/material.dart';

import '../ui/text_styles.dart';

class FeatureSectionTitle extends StatelessWidget {
  final String text;

  const FeatureSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: LifeText.section),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const FeatureCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class EmptyStateNote extends StatelessWidget {
  final String text;

  const EmptyStateNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60),
      ),
    );
  }
}
