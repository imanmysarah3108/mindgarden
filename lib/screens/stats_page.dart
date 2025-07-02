import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../utils/constants.dart';

// StatsPage displays various statistics about the user's journal entries
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

// Fetch entries from Supabase
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

// StatsPage UI
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
            return const Center(child: Text("No data available to show stats. Start writing some entries!"));
          }

// If we have data, proceed to build the stats view
          final entries = snapshot.data!;
          final totalEntries = entries.length;
          final streak = _calculateStreak(entries);
          final moodPercentages = _getMoodPercentages(entries); // Get mood percentages
          final topTags = _getTopTags(entries, count: 3); // Get top 3 tags with counts
          final averageEntryLength = _getAverageEntryLength(entries);
          final totalWordsWritten = _getTotalWordsWritten(entries);

          // Calculate start and end dates for "this week" (last 7 days from today)
          final DateTime today = DateTime.now();
          final DateTime startDate = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
          final DateTime endDate = DateTime(today.year, today.month, today.day);
          final String weekRange = "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}";

// Build the stats view
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Entries
                _buildStatCard("Total Entries", value: totalEntries.toString()),
                const SizedBox(height: 16), 

                // Current Streak
                _buildStatCard("Current Streak", value: "$streak days"),
                const SizedBox(height: 16), 

                // Mood Bar
                _buildMoodBar(moodPercentages, weekRange),
                const SizedBox(height: 16),

                // Frequently Recorded Tags
                _buildFrequentTags(topTags),
                const SizedBox(height: 16),

                // Average Entry Length
                _buildStatCard(
                  "Average Entry Length",
                  value: "${averageEntryLength.round()} words", // Round to nearest whole number
                ),
                const SizedBox(height: 16),

                // Total Words Written
                _buildStatCard(
                  "Total Words Written",
                  value: "${totalWordsWritten.round()} words", // Round to nearest whole number
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, {String? value, Widget? valueWidget}) {
    return Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (value != null)
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
            if (valueWidget != null)
              valueWidget,
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

    // Sort to ensure correct streak calculation
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

  // Helper to get the emoji for a given mood name
  String? _getMoodEmoji(String moodName) {
    final mood = _availableMoods.firstWhere(
      (m) => m['name'] == moodName,
      orElse: () => {'emoji': ''}, // Return empty string if not found
    );
    return mood['emoji'];
  }

  // New method to get mood percentages for the last 7 days
  Map<String, double> _getMoodPercentages(List<Entry> entries) {
    // Filter entries for the last 7 days
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    List<Entry> recentEntries = entries.where((entry) =>
        entry.entryDate.isAfter(sevenDaysAgo) && entry.mood != null
    ).toList();

    if (recentEntries.isEmpty) return {};

    final Map<String, int> moodCounts = {};
    for (var entry in recentEntries) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }

    final int totalRecentEntries = recentEntries.length;
    final Map<String, double> moodPercentages = {};
    moodCounts.forEach((mood, count) {
      moodPercentages[mood] = (count / totalRecentEntries) * 100;
    });

    return moodPercentages;
  }


  // Mood Bar
  Widget _buildMoodBar(Map<String, double> moodPercentages, String weekRange) {
    if (moodPercentages.isEmpty) {
      return _buildStatCard(
        "Mood Bar",
        valueWidget: Column(
          children: [
            const Text("No moods recorded this week.", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(weekRange, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    // Sort moods by their percentage in descending order for the bar segments
    final sortedMoods = moodPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Mood Bar",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Mood icons and percentages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _availableMoods.map((mood) {
                final percentage = moodPercentages[mood['name']] ?? 0.0;
                return Column(
                  children: [
                    Text(mood['emoji']!, style: const TextStyle(fontSize: 30)),
                    Text('${percentage.round()}%', style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // The actual mood bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 20, 
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double currentWidth = 0;
                    return Stack(
                      children: sortedMoods.map((e) {
                        final moodColor = _getMoodColor(e.key);
                        final segmentWidth = (e.value / 100) * constraints.maxWidth;
                        final offset = currentWidth;
                        currentWidth += segmentWidth;
                        return Positioned(
                          left: offset,
                          top: 0,
                          bottom: 0,
                          width: segmentWidth,
                          child: Container(
                            color: moodColor,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              weekRange,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get a consistent color for each mood for the bar
  Color _getMoodColor(String moodName) {
    switch (moodName) {
      case 'Happy': return Colors.yellow.shade300;
      case 'Calm': return Colors.lightBlue.shade300;
      case 'Neutral': return Colors.grey.shade300;
      case 'Sad': return Colors.blueGrey.shade300;
      case 'Anxious': return Colors.orange.shade300;
      case 'Angry': return Colors.red.shade300;
      case 'Excited': return Colors.green.shade300;
      case 'Tired': return Colors.purple.shade300;
      default: return Colors.transparent;
    }
  }


  // Modified method to get top tags with their counts
  List<Map<String, dynamic>> _getTopTags(List<Entry> entries, {int count = 3}) {
    if (entries.isEmpty) return [];

    final Map<String, int> tagCounts = {};
    for (var entry in entries) {
      if (entry.tags != null) {
        for (var tag in entry.tags!) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    if (tagCounts.isEmpty) return [];

    // Sort tags by count in descending order
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return the top 'count' tags with their counts
    return sortedTags.take(count).map((e) => {'name': e.key, 'count': e.value}).toList();
  }

  // New Widget for Frequently Recorded Tags
  Widget _buildFrequentTags(List<Map<String, dynamic>> topTags) {
    String mostFrequentTagSummary = "No tags recorded yet.";
    if (topTags.isNotEmpty) {
      mostFrequentTagSummary = "You recorded ${topTags.first['name']} the most.";
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Frequently Recorded",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (topTags.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8, 
                ),
                itemCount: topTags.length,
                itemBuilder: (context, index) {
                  final tag = topTags[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          tag['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "x${tag['count']}",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const Text(
                "No frequently recorded tags yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
            Text(
              mostFrequentTagSummary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// Calculate the average entry length in words
  double _getAverageEntryLength(List<Entry> entries) {
    if (entries.isEmpty) return 0.0;
    int totalWords = 0;
    for (var entry in entries) {
      totalWords += entry.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }
    return totalWords / entries.length;
  }

  // Calculate the total words written across all entries
  int _getTotalWordsWritten(List<Entry> entries) {
    if (entries.isEmpty) return 0;
    int totalWords = 0;
    for (var entry in entries) {
      totalWords += entry.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }
    return totalWords;
  }
}
