import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class StreakCelebration extends StatefulWidget {
  const StreakCelebration({
    super.key,
    required this.streak,
    required this.message,
    required this.onDismiss,
  });

  final int streak;
  final String message;
  final VoidCallback onDismiss;

  @override
  State<StreakCelebration> createState() => _StreakCelebrationState();
}

class _StreakCelebrationState extends State<StreakCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareStreak() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'I\'m on a ${widget.streak} day streak on LifeScore! 🔥 Who can beat me?',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      final double scale = 1 + (_controller.value * 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: const <Widget>[
                            Icon(
                              Icons.local_fire_department,
                              size: 80,
                              color: Color(0x4DFF6B35),
                            ),
                            Icon(
                              Icons.local_fire_department,
                              size: 72,
                              color: Color(0xB3FF6B35),
                            ),
                            Icon(
                              Icons.local_fire_department,
                              size: 64,
                              color: Color(0xFFFFD700),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${widget.streak}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.streak == 1 ? 'day streak' : 'day streak',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Keep it up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _shareStreak,
                    child: const Text(
                      'Share your streak',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
