import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_state.dart';
import 'widgets/chart_legend.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = KeelState.history.reversed.toList();

    if (history.length < 2) {
      return const Scaffold(
        body: Center(child: Text("Not enough data")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Trends")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Reflection Index",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: _chart(history)),
            const SizedBox(height: 24),
            const ChartLegend(),
          ],
        ),
      ),
    );
  }

  LineChart _chart(List history) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              history.length,
                  (i) => FlSpot(i.toDouble(), history[i].index.toDouble()),
            ),
            isCurved: true,
            color: const Color(0xFF4FACFE),
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
