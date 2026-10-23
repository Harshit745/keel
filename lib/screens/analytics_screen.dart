import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/build_log.dart';
import '../models/self_log.dart';
import '../services/hive_service.dart';
import '../services/score_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const Color _bg = Color(0xFF080808);
  static const Color _card = Color(0xFF0D0D0D);
  static const Color _accent = Color(0xFFF0FF00);

  final HiveService _hiveService = HiveService();
  final DateFormat _dayFormatter = DateFormat('E');

  bool _isLoading = true;
  List<int> _scores = <int>[];
  List<DateTime> _days = <DateTime>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(const Duration(days: 6));

    final List<int> scores = <int>[];
    final List<DateTime> days = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      final DateTime date = start.add(Duration(days: i));
      days.add(date);

      final BuildLog? b = await _hiveService.getBuildLogForDate(date);
      final SelfLog? s = await _hiveService.getSelfLogForDate(date);

      final int bs = b?.buildScore ?? 0;
      final int ss = s?.selfScore ?? 0;

      scores.add(ScoreService.calculateFounderScore(bs, ss));
    }

    if (!mounted) return;

    setState(() {
      _scores = scores;
      _days = days;
      _isLoading = false;
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Column(
            children: <Widget>[
              Text(
                'ANALYTICS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'PERFORMANCE TRENDS',
                style: TextStyle(
                  fontSize: 10,
                  color: Color.fromRGBO(255, 255, 255, 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              'FOUNDERSCORE TREND',
              style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.5),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (double v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, _) {
                        final int index = value.toInt();
                        if (index < 0 || index >= _days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _dayFormatter.format(_days[index]).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: _scores
                        .asMap()
                        .entries
                        .map(
                          (MapEntry<int, int> e) =>
                              FlSpot(e.key.toDouble(), e.value.toDouble()),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter:
                          (
                            FlSpot spot,
                            double percent,
                            LineChartBarData barData,
                            int index,
                          ) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _accent,
                              strokeWidth: 3,
                              strokeColor: _card,
                            );
                          },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _accent.withValues(alpha: 0.2),
                          _accent.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildChart(),
                    const SizedBox(height: 24),
                    _buildStatCard(
                      'AVG FOUNDERSCORE',
                      '${(_scores.reduce((a, b) => a + b) / _scores.length).round()}',
                      Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color.fromRGBO(255, 255, 255, 0.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
          Icon(icon, color: _accent.withValues(alpha: 0.2), size: 32),
        ],
      ),
    );
  }
}
