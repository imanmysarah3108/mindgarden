import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindgarden/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../utils/constants.dart';
import 'entry_editor_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late Future<List<Entry>> _entriesFuture;

  // The screens list will now be built within the _HomePageInherited scope
  // to ensure they have access to the inherited data.
  List<Widget> _getScreens() {
    return [
      const EntriesListScreen(),
      const StatsPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  Future<List<Entry>> _fetchEntries() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('entries')
        .select('*')
        .eq('user_id', userId)
        .order('entry_date', ascending: false);

    return (response as List).map((json) => Entry.fromJson(json)).toList();
  }

  Future<void> _refreshEntries() async {
    setState(() {
      _entriesFuture = _fetchEntries();
    });
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await supabase.from('entries').delete().eq('id', entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully!')),
        );
        _refreshEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HomePageInherited(
      entriesFuture: _entriesFuture,
      refreshEntries: _refreshEntries,
      deleteEntry: _deleteEntry,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mind Garden'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        ),
        body: _getScreens()[_currentIndex], // Access screens via _getScreens()
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Entries',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EntryEditorPage(),
                    ),
                  );
                  if (result == true && mounted) {
                    _refreshEntries();
                  }
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class EntriesListScreen extends StatelessWidget {
  const EntriesListScreen({super.key});

  // Define a list of moods with emojis, consistent with entry_editor_page and stats_page
  final List<Map<String, String>> _availableMoods = const [
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Calm', 'emoji': '😌'},
    {'name': 'Neutral', 'emoji': '😐'},
    {'name': 'Sad', 'emoji': '😢'},
    {'name': 'Anxious', 'emoji': '😟'},
    {'name': 'Angry', 'emoji': '😠'},
    {'name': 'Excited', 'emoji': '🤩'},
    {'name': 'Tired', 'emoji': '😴'},
  ];

  String _getMoodEmoji(String? moodName) {
    if (moodName == null) return '';
    final mood = _availableMoods.firstWhere(
      (m) => m['name'] == moodName,
      orElse: () => {'emoji': ''}, // Return empty string if not found
    );
    return mood['emoji'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Access the inherited widget safely using .of(context)
    final homePageInherited = _HomePageInherited.of(context);

    // Provide a fallback or handle the null case if homePageInherited could be null
    // (though with the fix above, it should not be null here)
    if (homePageInherited == null) {
      return const Center(child: Text('Error: Home page data not available.'));
    }

    final entriesFuture = homePageInherited.entriesFuture;

    return RefreshIndicator(
      onRefresh: () async {
        await homePageInherited.refreshEntries();
      },
      child: FutureBuilder<List<Entry>>(
        future: entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No entries yet. Start writing!'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  color: entry.displayColor ?? Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    // Display mood emoji on the left
                    leading: Text(
                      _getMoodEmoji(entry.mood),
                      style: const TextStyle(fontSize: 30), // Adjust size as needed
                    ),
                    title: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: (entry.displayColor != null &&
                                    entry.displayColor!.computeLuminance() < 0.5)
                                ? Colors.white
                                : Colors.black,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Only display the date, remove content
                        const SizedBox(height: 4.0),
                        Text(
                          DateFormat('yyyy-MM-dd').format(entry.entryDate),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: (entry.displayColor != null &&
                                        entry.displayColor!.computeLuminance() < 0.5)
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntryEditorPage(entry: entry),
                        ),
                      );
                      if (result == true) {
                        homePageInherited.refreshEntries();
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => homePageInherited.deleteEntry(entry.id),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class _HomePageInherited extends InheritedWidget {
  final Future<List<Entry>> entriesFuture;
  final Future<void> Function() refreshEntries;
  final Future<void> Function(String) deleteEntry;

  const _HomePageInherited({
    required super.child,
    required this.entriesFuture,
    required this.refreshEntries,
    required this.deleteEntry,
  });

  @override
  bool updateShouldNotify(_HomePageInherited oldWidget) =>
      entriesFuture != oldWidget.entriesFuture;

  static _HomePageInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HomePageInherited>();
  }
}
