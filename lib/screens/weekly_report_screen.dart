import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/weekly_report.dart';
import '../services/ai_service.dart';
import '../services/hive_service.dart';
import '../services/subscription_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  final bool isPro;
  final bool showBackButton;
  const WeeklyReportScreen({
    super.key,
    required this.isPro,
    this.showBackButton = true,
  });

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF111111);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _teal = Color(0xFF00E5FF);
  static const Color _muted = Color(0x99FFFFFF);
  static const Color _danger = Color(0xFFFF6B6B);

  bool _isPro = false;
  bool _isLoading = true;
  WeeklyReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isPro = widget.isPro;
    if (_isPro) {
      _generateReport();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hiveService = HiveService();
      final now = DateTime.now();
      final buildLogs = await hiveService.getBuildLogsForWeek(now);
      final selfLogs = await hiveService.getSelfLogsForWeek(now);

      if (buildLogs.isEmpty && selfLogs.isEmpty) {
        setState(() {
          _isLoading = false;
          _error =
              "Log 3 to 5 real days and Keel will turn them into a weekly operating review.";
        });
        return;
      }

      final report = await AiService.generateWeeklyReport(buildLogs, selfLogs);
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to generate AI report. Check your connection.";
      });
    }
  }

  Future<void> _handlePurchase() async {
    final success = await SubscriptionService.purchase(context);
    if (success) {
      setState(() {
        _isPro = true;
      });
      _generateReport();
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscriptions are unavailable right now.')),
    );
  }

  void _shareReport() {
    if (_report == null) return;

    final text =
        '''
My Weekly Founder Report
Week of ${DateFormat('MMM d').format(_report!.weekStart)} – ${DateFormat('MMM d').format(_report!.weekEnd)}

Score: ${_report!.avgFounderScore.toStringAsFixed(0)}/100

AI Insight:
${_report!.insight}

Strongest pattern:
${_report!.strongestPattern}

Main risk:
${_report!.biggestRisk}

Main opportunity:
${_report!.biggestOpportunity}

Next-week focus:
${_report!.nextWeekFocus}

Patterns:
${_report!.patterns.map((p) => "- $p").join('\n')}

Action Plan:
${_report!.actions.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join('\n')}

Exported from Keel
''';
    SharePlus.instance.share(
      ShareParams(text: text, subject: 'My Weekly Founder Report'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          "Weekly Report",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isPro && _report != null)
            IconButton(
              icon: const Icon(
                Icons.ios_share_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _shareReport,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isPro) return _buildPaywall();
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_report == null) return _buildLoading();

    return _buildReport();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(color: _accent),
          const SizedBox(height: 20),
          Text(
            "Running your weekly operating review...",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Patterns, risk, and next-week focus are being assembled.",
            style: TextStyle(color: _muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? "An error occurred",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Keel works best when it has a few honest days to compare.',
              style: TextStyle(color: _muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _generateReport,
              child: const Text("Retry", style: TextStyle(color: _accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywall() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.lock_rounded, size: 56, color: _accent),
          const SizedBox(height: 20),
          const Text(
            "Unlock Weekly Reports",
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Get a personalized AI analysis of your past 7 days.\nSee exactly what's working and what's blocking you.",
            style: TextStyle(fontSize: 14, color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPaywallFeature("Deep pattern analysis across 7 days"),
          const SizedBox(height: 12),
          _buildPaywallFeature("Burnout risk detection + alerts"),
          const SizedBox(height: 12),
          _buildPaywallFeature("Personalized weekly action plan"),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Start for ₹99/month",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => SubscriptionService.restorePurchases(),
            child: const Text(
              "Restore purchases",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallFeature(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: _accent, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildReport() {
    final report = _report!;
    final dateDisplay =
        "Week of ${DateFormat('MMM d').format(report.weekStart)} – ${DateFormat('MMM d').format(report.weekEnd)}";
    final List<String> actions = report.actions.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. WEEK HEADER CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateDisplay,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.avgFounderScore.toStringAsFixed(0),
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Your Keel score averaged ${report.avgFounderScore.toStringAsFixed(0)} this week",
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. AI INSIGHT
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: _accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "AI Insight",
                      style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.insight,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. REVIEW SIGNALS
          Row(
            children: [
              Expanded(
                child: _buildReviewSignalCard(
                  label: 'Strongest pattern',
                  value: report.strongestPattern,
                  icon: Icons.track_changes_rounded,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReviewSignalCard(
                  label: 'Next-week focus',
                  value: report.nextWeekFocus,
                  icon: Icons.flag_rounded,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReviewSignalCard(
                  label: 'Main risk',
                  value: report.biggestRisk,
                  icon: Icons.warning_amber_rounded,
                  color: _danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReviewSignalCard(
                  label: 'Main opportunity',
                  value: report.biggestOpportunity,
                  icon: Icons.trending_up_rounded,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. PATTERN CARDS
          const Text(
            "Patterns detected",
            style: TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: report.patterns.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white24,
                        size: 20,
                      ),
                      const Spacer(),
                      Text(
                        report.patterns[index],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 5. PILLAR BREAKDOWN
          Row(
            children: [
              Expanded(
                child: _buildPillarCard(
                  "Build",
                  report.avgBuildScore,
                  report.buildTrend,
                  _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPillarCard(
                  "Self",
                  report.avgSelfScore,
                  report.selfTrend,
                  _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6. BURNOUT RISK METER
          if (report.burnoutRisk) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _danger.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _danger,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Burnout Risk Detected",
                        style: TextStyle(
                          color: _danger,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (report.burnoutReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      report.burnoutReason!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 7. ACTION PLAN
          const Text(
            "Your 3 actions for next week",
            style: TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 12),
          ...actions.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final action = entry.value;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 260 + (idx * 120)),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 14),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      "0$idx",
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPillarCard(
    String title,
    double score,
    String trend,
    Color color,
  ) {
    IconData trendIcon = Icons.trending_flat;
    if (trend == 'up') trendIcon = Icons.trending_up;
    if (trend == 'down') trendIcon = Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(trendIcon, color: _muted, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSignalCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
