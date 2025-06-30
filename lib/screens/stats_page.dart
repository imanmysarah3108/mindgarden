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

  // Define a list of moods with emojis, consistent with entry_editor_page
  final List<Map<String, String>> _availableMoods = [
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Calm', 'emoji': '😌'},
    {'name': 'Neutral', 'emoji': '😐'},
    {'name': 'Sad', 'emoji': '😢'},
    {'name': 'Anxious', 'emoji': '😟'},
    {'name': 'Angry', 'emoji': '😠'},
    {'name': 'Excited', 'emoji': '🤩'},
    {'name': 'Tired', 'emoji': '😴'},
  ];

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
          final mostFrequentMood = _getMostFrequentMood(entries);

          // Calculate start and end dates for "this week" (last 7 days from today)
          final DateTime today = DateTime.now();
          final DateTime startDate = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
          final DateTime endDate = DateTime(today.year, today.month, today.day);
          final String weekRange = "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}";


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wrap stats cards in a Row for better layout on wider screens
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Entries", totalEntries.toString())),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard("Current Streak", "$streak days")),
                  ],
                ),
                const SizedBox(height: 16),
                // Display the most frequent mood with emoji and date range
                if (mostFrequentMood != null)
                  _buildStatCard(
                    "Your Mood This Week ($weekRange)",
                    "${mostFrequentMood['emoji']} You feel ${mostFrequentMood['name']!.toLowerCase()} this week.",
                  ),
                const SizedBox(height: 24),
                Text(
                  "Entries Over Time",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
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
      elevation: 4, // Increased elevation for a more prominent look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center, // Center align title
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center, // Center align value
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<Entry> entries) {
    if (entries.isEmpty) return 0;

    // Filter entries for the last 7 days to calculate a "this week" streak
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Entry> recentEntries = entries.where((entry) => entry.entryDate.isAfter(sevenDaysAgo)).toList();

    if (recentEntries.isEmpty) return 0;

    recentEntries.sort((a, b) => b.entryDate.compareTo(a.entryDate));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentDate = DateTime(today.year, today.month, today.day);

    // Check if there's an entry for today or yesterday to start the streak
    if (recentEntries.first.entryDate.isAtSameMomentAs(currentDate) ||
        recentEntries.first.entryDate.isAtSameMomentAs(currentDate.subtract(const Duration(days: 1)))) {
      streak = 1;
      DateTime lastDate = recentEntries.first.entryDate;

      for (int i = 1; i < recentEntries.length; i++) {
        DateTime entryDate = recentEntries[i].entryDate;
        // Check if the current entry is exactly one day before the last entry
        if (lastDate.difference(entryDate).inDays == 1) {
          streak++;
          lastDate = entryDate;
        } else if (lastDate.difference(entryDate).inDays > 1) {
          // Gap in streak
          break;
        }
        // If entryDate is same as lastDate, it's a duplicate for the day, continue
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
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              // Ensure Y-axis labels are whole numbers
              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
            },
            interval: 1, // Ensure labels are for each integer value
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1000 * 60 * 60 * 24 * 5, // Show titles every 5 days
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 10)),
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
      minY: 0, // Ensure Y-axis starts from 0 for better visualization of counts
    );
  }

  String? _getMoodEmoji(String moodName) {
    final mood = _availableMoods.firstWhere(
      (m) => m['name'] == moodName,
      orElse: () => {'emoji': ''}, // Return empty string if not found
    );
    return mood['emoji'];
  }

  Map<String, String>? _getMostFrequentMood(List<Entry> entries) {
    if (entries.isEmpty) return null;

    // Filter entries for the last 7 days
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Entry> recentEntries = entries.where((entry) =>
        entry.entryDate.isAfter(sevenDaysAgo) && entry.mood != null
    ).toList();

    if (recentEntries.isEmpty) return null;

    final Map<String, int> moodCounts = {};
    for (var entry in recentEntries) {
      if (entry.mood != null) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
    }

    if (moodCounts.isEmpty) return null;

    // Find the mood with the highest count
    String? mostFrequentMoodName;
    int maxCount = 0;
    moodCounts.forEach((moodName, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentMoodName = moodName;
      }
    });

    if (mostFrequentMoodName != null) {
      return {
        'name': mostFrequentMoodName!,
        'emoji': _getMoodEmoji(mostFrequentMoodName!) ?? '',
      };
    }
    return null;
  }
}
