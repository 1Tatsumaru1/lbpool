import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lbpool/model/elo_point.dart';

class CustomLinechart extends StatelessWidget {
  const CustomLinechart({super.key, required this.spots, required this.labels});

  final List<FlSpot> spots;
  final List<String> labels;

  // Transformer for EloPoint input
  static List<FlSpot> eloToSpot(List<EloPoint> points) {
    return points.asMap().entries.map((entry) {
      final index = entry.key.toDouble(); // X = index
      final point = entry.value;
      return FlSpot(index, point.elo.toDouble()); // Y = ELO
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Calcul min/max
    final double minY = min(1000, spots.map((s) => s.y).reduce(min));
    final double maxY = max(1000, spots.map((s) => s.y).reduce(max));

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
            color: ColorScheme.of(context).primary,
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.white,
          )
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  space: 4,
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              strokeWidth: 0.5,
              color: Colors.grey,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 1000,
              color: Colors.red,
              strokeWidth: 2,
              dashArray: [8, 4],
            ),
          ],
        ),
      ),
    );
  }
}