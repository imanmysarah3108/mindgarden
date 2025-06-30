import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../utils/constants.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<Entry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _fetchEntries();
  }

  Future<List<Entry>> _fetchEntries() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('entries')
        .select('*')
        .eq('user_id', userId)
        .order('entry_date', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Entry.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Entry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error fetching stats: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data available to show stats."));
          }

          final entries = snapshot.data!;
          final totalEntries = entries.length;
          final streak = _calculateStreak(entries);
          final chartData = _prepareChartData(entries);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatCard("Total Entries", totalEntries.toString()),
                const SizedBox(height: 16),
                _buildStatCard("Current Streak", "$streak days"),
                const SizedBox(height: 24),
                Text(
                  "Entries Over Time",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(_buildChart(chartData)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<Entry> entries) {
    if (entries.isEmpty) return 0;

    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentDate = DateTime(today.year, today.month, today.day);

    if (entries.first.entryDate.isAtSameMomentAs(currentDate) ||
        entries.first.entryDate.isAtSameMomentAs(currentDate.subtract(const Duration(days: 1)))) {
      streak = 1;
      DateTime lastDate = entries.first.entryDate;

      for (int i = 1; i < entries.length; i++) {
        DateTime entryDate = entries[i].entryDate;
        if (lastDate.difference(entryDate).inDays == 1) {
          streak++;
          lastDate = entryDate;
        } else if (lastDate.difference(entryDate).inDays > 1) {
          break;
        }
      }
    }

    return streak;
  }

  Map<DateTime, int> _prepareChartData(List<Entry> entries) {
    final Map<DateTime, int> data = {};
    for (var entry in entries) {
      final date = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
      data[date] = (data[date] ?? 0) + 1;
    }
    return data;
  }

  LineChartData _buildChart(Map<DateTime, int> data) {
    final spots = data.entries.map((e) {
      return FlSpot(e.key.millisecondsSinceEpoch.toDouble(), e.value.toDouble());
    }).toList();

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1000 * 60 * 60 * 24 * 5,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(DateFormat('MMM d').format(date)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}