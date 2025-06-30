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
  String? _nickname; // State variable to store the user's nickname

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
    _fetchUserProfile(); // Fetch user profile when the page initializes
  }

  Future<void> _fetchUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('nickname')
          .eq('user_id', userId)
          .single(); // Use single() to get a single row

      if (response != null && response['nickname'] != null) {
        setState(() {
          _nickname = response['nickname'] as String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user profile: $e')),
        );
      }
    }
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
      nickname: _nickname, // Pass the nickname to the inherited widget
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Docked to the center of the bottom app bar
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
                shape: const CircleBorder(), // Ensure it's a perfect circle
                backgroundColor: Theme.of(context).colorScheme.errorContainer, // Set background color to pinkish
                child: const Icon(Icons.local_florist), // Flower icon
              )
            : null,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(), // Creates a notch for the FAB
          notchMargin: 6.0, // Reduced notch margin for a tighter fit
          color: Theme.of(context).colorScheme.primaryContainer, // Match app bar color or theme
          child: SizedBox( // Added SizedBox to control height
            height: kBottomNavigationBarHeight - 10.0, // Explicitly set a slightly reduced height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: InkWell( // Use InkWell for tap effect
                    onTap: () => setState(() => _currentIndex = 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home,
                          color: _currentIndex == 0
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                        ),
                        Text(
                          'Entries',
                          style: TextStyle(
                            color: _currentIndex == 0
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Spacer for the FAB
                const SizedBox(width: 60), // Adjust width to match FAB size
                Expanded(
                  child: InkWell( // Use InkWell for tap effect
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: _currentIndex == 1
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                        ),
                        Text(
                          'Stats',
                          style: TextStyle(
                            color: _currentIndex == 1
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  // New widget for the mood picker on the home page
  Widget _buildMoodPicker(BuildContext context, Function refreshEntries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16), // Space after "How are you feeling today?"
        SizedBox(
          height: 80, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableMoods.length,
            itemBuilder: (context, index) {
              final mood = _availableMoods[index];
              return GestureDetector(
                onTap: () async {
                  // Navigate to EntryEditorPage and pass the selected mood
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntryEditorPage(initialMood: mood['name']),
                    ),
                  );
                  if (result == true) {
                    refreshEntries(); // Refresh entries if a new one was added
                  }
                },
                child: Container(
                  width: 70, // Adjust width for each mood item
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // Use card color for mood items
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mood['emoji']!,
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the inherited widget safely using .of(context)
    final homePageInherited = _HomePageInherited.of(context);

    // Provide a fallback or handle the null case if homePageInherited could be null
    if (homePageInherited == null) {
      return const Center(child: Text('Error: Home page data not available.'));
    }

    final entriesFuture = homePageInherited.entriesFuture;
    final nickname = homePageInherited.nickname; // Get nickname from inherited widget

    return Column( // Use a Column to stack the welcome message and the list
      crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch to take full width
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Keep this for inner centering
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome, ${nickname ?? 'User'}', // Display nickname, with 'User' as fallback
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 4),
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center, // Center the text
              ),
            ],
          ),
        ),
        // Insert the new mood picker here
        _buildMoodPicker(context, homePageInherited.refreshEntries),
        const SizedBox(height: 30), // Space between mood picker and "Past Entries"
        Padding( // New Padding for "Past Entries" to control its alignment
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Match horizontal padding
          child: Align(
            alignment: Alignment.centerLeft, // Align to the left
            child: Text(
              'Past Entries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 5), // Space between "Past Entries" and the list
        Expanded( // Wrap the RefreshIndicator with Expanded
          child: RefreshIndicator(
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
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: entry.displayColor != null
                              ? BorderSide(color: entry.displayColor!, width: 2) // Use color as outline
                              : BorderSide.none, // No border if no color
                        ),
                        child: Container( // Wrap ListTile in Container to set background color
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor, // Default card background
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    color: Theme.of(context).colorScheme.onSurface, // Text color based on theme
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
                                        color: Theme.of(context).colorScheme.onSurfaceVariant, // Text color based on theme
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
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePageInherited extends InheritedWidget {
  final Future<List<Entry>> entriesFuture;
  final Future<void> Function() refreshEntries;
  final Future<void> Function(String) deleteEntry;
  final String? nickname; // New property for nickname

  const _HomePageInherited({
    super.key, // Add key to constructor
    required super.child,
    required this.entriesFuture,
    required this.refreshEntries,
    required this.deleteEntry,
    this.nickname, // Include nickname in constructor
  });

  @override
  bool updateShouldNotify(_HomePageInherited oldWidget) =>
      entriesFuture != oldWidget.entriesFuture || nickname != oldWidget.nickname; // Update condition

  static _HomePageInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HomePageInherited>();
  }
}
