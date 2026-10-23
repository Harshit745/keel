import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/build_log.dart';
import '../models/idea.dart';
import '../models/self_log.dart';
import '../services/ai_service.dart';
import '../services/hive_service.dart';
import '../services/user_service.dart';
import '../services/streak_service.dart';
import '../services/score_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF111111);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _muted = Color(0x99FFFFFF);

  final HiveService _hiveService = HiveService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  bool _isAwaitingReply = false;
  int _messageCounter = 0;

  @override
  void initState() {
    super.initState();
    _seedIntroMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _seedIntroMessage() async {
    final BuildLog? b = await _hiveService.getBuildLogForDate(DateTime.now());
    final SelfLog? s = await _hiveService.getSelfLogForDate(DateTime.now());

    String intro =
        "Hey founder 👋 Tell me about your day — what did you ship, who did you talk to, how are you holding up?";

    if (b != null || s != null) {
      final List<String> obs = <String>[];
      if ((s?.sleepHours ?? 0) < 6 && (s?.sleepHours ?? 0) > 0) {
        obs.add(
          "I see you only got ${s!.sleepHours}h of sleep — rough night? 😴",
        );
      }
      if ((s?.sleepHours ?? 0) >= 7.5) {
        obs.add("Nice — solid sleep! 💪");
      }
      if ((b?.tasksShipped ?? 0) > 0) {
        obs.add(
          "You shipped ${b!.tasksShipped} tasks today — keep it going! 🚀",
        );
      }
      if (obs.isNotEmpty) {
        intro = "${obs.join(' ')}\n\nWhat else happened today?";
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          id: _nextMessageId(),
          role: _ChatRole.assistant,
          text: intro,
        ),
      );
    });
  }

  String _nextMessageId() => 'msg_${++_messageCounter}';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final String input = _textController.text.trim();
    if (input.isEmpty || _isAwaitingReply) {
      return;
    }

    _textController.clear();
    setState(() {
      _messages.add(
        _ChatMessage(id: _nextMessageId(), role: _ChatRole.user, text: input),
      );
      _isAwaitingReply = true;
    });
    _scrollToBottom();

    // Prepare history (take the last 10 messages, then reverse back to chronological order for the prompt)
    final List<Map<String, dynamic>> history = _messages.reversed
        .take(10) // get 10 most recent
        .map(
          (m) => {
            'role': m.role == _ChatRole.user ? 'user' : 'assistant',
            'content': m.text,
          },
        )
        .toList(); // these are now in reverse order (newest first)

    // Prepare context
    final String name = await UserService.getName();
    final int streak = await StreakService.getCurrentStreak();
    final DateTime now = DateTime.now();

    final BuildLog? todayB = await _hiveService.getBuildLogForDate(now);
    final SelfLog? todayS = await _hiveService.getSelfLogForDate(now);

    final List<BuildLog> weekB = await _hiveService.getBuildLogsForWeek(now);
    final List<SelfLog> weekS = await _hiveService.getSelfLogsForWeek(now);

    final double totalRevenue = weekB.fold(
      0.0,
      (sum, b) => sum + b.revenueAdded,
    );
    final int totalTasks = weekB.fold(0, (sum, b) => sum + b.tasksShipped);
    final double avgSleep = weekS.isEmpty
        ? 0.0
        : weekS.fold(0.0, (sum, s) => sum + s.sleepHours) / weekS.length;

    final int buildScore = todayB?.buildScore ?? 0;
    final int selfScore = todayS?.selfScore ?? 0;
    final int founderScore = ScoreService.calculateFounderScore(
      buildScore,
      selfScore,
    );

    final String context =
        "Founder Name: $name. Current Streak: $streak days. "
        "SCORES TODAY: FounderScore: $founderScore/100, Build Score: $buildScore/100, Self Score: $selfScore/100. "
        "TODAY STATS: ${todayB?.tasksShipped ?? 0} tasks, ₹${todayB?.revenueAdded ?? 0} revenue, ${todayS?.sleepHours ?? 0}h sleep. "
        "WEEK SUMMARY: $totalTasks total tasks, ₹${totalRevenue.toStringAsFixed(0)} total revenue, ${avgSleep.toStringAsFixed(1)}h avg sleep over ${weekS.length} days logged.";

    final Map<String, dynamic> res = await AiService.parseFounderLog(
      input,
      history,
      contextSummary: context,
    );

    if (!mounted) return;
    setState(() {
      _isAwaitingReply = false;
      if (res.containsKey('error')) {
        _messages.add(
          _ChatMessage(
            id: _nextMessageId(),
            role: _ChatRole.assistant,
            text:
                res['reply'] as String? ??
                res['message'] as String? ??
                "Couldn't understand that.",
          ),
        );
      } else {
        _messages.add(
          _ChatMessage(
            id: _nextMessageId(),
            role: _ChatRole.assistant,
            data: res,
          ),
        );
      }
    });
    _scrollToBottom();
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    final DateTime now = DateTime.now();

    // Build Log saving
    if (data['tasksShipped'] > 0 ||
        data['talkedToUser'] ||
        data['movedNeedle'] ||
        data['revenueAdded'] > 0 ||
        data['winOfDay'] != '') {
      BuildLog? b = await _hiveService.getBuildLogForDate(now);
      b ??= BuildLog(date: now, id: BuildLog.keyForDate(now));

      if (data['tasksShipped'] > 0) {
        b.tasksShipped += (data['tasksShipped'] as num).toInt();
      }
      if ((data['talkedToUser'] as bool?) == true) {
        b.talkedToUser = true;
      }
      if ((data['movedNeedle'] as bool?) == true) {
        b.movedNeedle = true;
      }
      if (data['revenueAdded'] > 0) {
        b.revenueAdded += (data['revenueAdded'] as num).toDouble();
      }
      if (data['winOfDay'] != '') {
        b.winOfDay = data['winOfDay'] as String;
      }

      b.buildScore = ScoreService.calculateBuildScore(
        tasksShipped: b.tasksShipped,
        talkedToUser: b.talkedToUser,
        movedNeedle: b.movedNeedle,
        revenueAdded: b.revenueAdded,
      );

      await _hiveService.saveBuildLog(b);
    }

    // Self Log saving
    if (data['sleepHours'] > 0 ||
        data['energyLevel'] > 0 ||
        data['moodRating'] > 0 ||
        data['moneySpent'] > 0 ||
        data['exercised']) {
      final double currentBudget = await UserService.getDailyBudget();
      SelfLog? s = await _hiveService.getSelfLogForDate(now);
      s ??= SelfLog(
        date: now,
        id: SelfLog.keyForDate(now),
        dailyBudget: currentBudget,
      );

      if (data['sleepHours'] > 0) {
        s.sleepHours = (data['sleepHours'] as num).toDouble();
      }
      if (data['energyLevel'] > 0) {
        s.energyLevel = (data['energyLevel'] as num).toInt();
      }
      if (data['moodRating'] > 0) {
        s.moodRating = (data['moodRating'] as num).toInt();
      }
      if (data['moneySpent'] > 0) {
        s.moneySpent += (data['moneySpent'] as num).toDouble();
      }
      if ((data['exercised'] as bool?) == true) {
        s.exercised = true;
      }

      s.selfScore = ScoreService.calculateSelfScore(
        sleepHours: s.sleepHours,
        energyLevel: s.energyLevel,
        moodRating: s.moodRating,
        moneySpent: s.moneySpent,
        dailyBudget: s.dailyBudget,
        exercised: s.exercised,
      );

      await _hiveService.saveSelfLog(s);
    }

    // Ideas saving
    if (data['ideas'] != null && (data['ideas'] as List<dynamic>).isNotEmpty) {
      final List<dynamic> ideas = data['ideas'] as List<dynamic>;
      for (int i = 0; i < ideas.length; i++) {
        final dynamic ideaText = ideas[i];
        final Idea idea = Idea(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          content: ideaText.toString(),
          createdAt: DateTime.now(),
        );
        await _hiveService.saveIdea(idea);
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to Keel!')));
    Navigator.pop(context, true);
  }

  Widget _buildTopBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: _bg.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: <Widget>[
              const BackButton(color: Colors.white),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.auto_awesome, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Keel AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Smart Logger',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(Map<String, dynamic> data) {
    final List<Widget> buildRows = <Widget>[];
    if (data['tasksShipped'] > 0) {
      buildRows.add(
        _metricRow(
          Icons.check_circle,
          'Shipped',
          '${data['tasksShipped']} tasks',
        ),
      );
    }
    if (data['talkedToUser']) {
      buildRows.add(_metricRow(Icons.record_voice_over, 'Users', 'Talked'));
    }
    if (data['movedNeedle']) {
      buildRows.add(_metricRow(Icons.bolt, 'Needle', 'Moved'));
    }
    if (data['revenueAdded'] > 0) {
      buildRows.add(
        _metricRow(
          Icons.attach_money,
          'Revenue',
          _currencyFormatter.format(data['revenueAdded']),
        ),
      );
    }
    if (data['winOfDay'] != '') {
      buildRows.add(
        _metricRow(Icons.emoji_events, 'Win', data['winOfDay'] as String),
      );
    }

    final List<Widget> selfRows = <Widget>[];
    if (data['sleepHours'] > 0) {
      selfRows.add(
        _metricRow(Icons.bedtime, 'Sleep', '${data['sleepHours']}h'),
      );
    }
    if (data['energyLevel'] > 0) {
      selfRows.add(
        _metricRow(
          Icons.battery_charging_full,
          'Energy',
          '${data['energyLevel']}/5',
        ),
      );
    }
    if (data['moodRating'] > 0) {
      selfRows.add(_metricRow(Icons.mood, 'Mood', '${data['moodRating']}/5'));
    }
    if (data['moneySpent'] > 0) {
      selfRows.add(
        _metricRow(
          Icons.money_off,
          'Spent',
          _currencyFormatter.format(data['moneySpent']),
        ),
      );
    }
    if (data['exercised']) {
      selfRows.add(_metricRow(Icons.fitness_center, 'Body', 'Moved'));
    }

    final List<dynamic> ideas = data['ideas'] as List<dynamic>? ?? <dynamic>[];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                "Here's what I got:",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              if (buildRows.isNotEmpty) ...<Widget>[
                Text(
                  'BUILD',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...buildRows,
                const SizedBox(height: 16),
              ],
              if (selfRows.isNotEmpty) ...<Widget>[
                Text(
                  'SELF',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...selfRows,
                const SizedBox(height: 16),
              ],
              if (ideas.isNotEmpty) ...<Widget>[
                Text(
                  'IDEAS',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...ideas.map(
                  (dynamic idea) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.lock, color: _accent, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            idea.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _saveData(data),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save to Keel',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: _accent, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLogData(Map<String, dynamic> data) {
    return (data['tasksShipped'] as num? ?? 0) > 0 ||
        (data['talkedToUser'] as bool? ?? false) ||
        (data['movedNeedle'] as bool? ?? false) ||
        (data['revenueAdded'] as num? ?? 0) > 0 ||
        (data['winOfDay'] as String? ?? '') != '' ||
        (data['sleepHours'] as num? ?? 0) > 0 ||
        (data['energyLevel'] as num? ?? 0) > 0 ||
        (data['moodRating'] as num? ?? 0) > 0 ||
        (data['moneySpent'] as num? ?? 0) > 0 ||
        (data['exercised'] as bool? ?? false) ||
        (data['ideas'] as List<dynamic>? ?? []).isNotEmpty;
  }

  Widget _buildMessage(_ChatMessage message) {
    final bool isUser = message.role == _ChatRole.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: message.data == null
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isUser ? _card : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.data != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.data!['reply'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              message.data!['reply'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        if (_hasLogData(message.data!))
                          _buildConfirmationCard(message.data!),
                      ],
                    )
                  : Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (!isUser && message.data == null) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: _bg.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    hintText: 'Describe your day...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isAwaitingReply ? null : _sendMessage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _accent.withValues(
                        alpha: _isAwaitingReply ? 0.3 : 1.0,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTopBar(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isAwaitingReply ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: _accent,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  _ChatMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.data,
  });
  final String id;
  final _ChatRole role;
  final String text;
  final Map<String, dynamic>? data;
}
