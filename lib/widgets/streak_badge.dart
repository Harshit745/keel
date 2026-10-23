import 'package:flutter/material.dart';

class StreakBadge extends StatefulWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    required this.longestStreak,
    required this.freezes,
  });

  final int streak;
  final int longestStreak;
  final int freezes;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak != widget.streak) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.streak > 0) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.streak > 0
        ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
        : Colors.white12;
    final Color fireColor = widget.streak == 0
        ? Colors.white.withValues(alpha: 0.25)
        : (widget.streak >= 7
              ? const Color(0xFFFFD700)
              : const Color(0xFFFF6B35));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final double scale = widget.streak > 0
                      ? 1 + (_controller.value * 0.15)
                      : 1;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Icon(
                  Icons.local_fire_department,
                  color: fireColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.streak > 0
                    ? '${widget.streak} day streak'
                    : 'Start your streak',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.streak > 0
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        if (widget.freezes > 0) ...<Widget>[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Streak freeze — protects your streak for 1 missed day',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.shield, color: Color(0xFF6C63FF), size: 16),
                  Text(
                    ' ${widget.freezes}',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
