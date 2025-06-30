import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../utils/constants.dart';
import 'entry_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        .order('entry_date', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Entry.fromJson(json)).toList();
  }

  Future<void> _refreshEntries() async {
    setState(() {
      _entriesFuture = _fetchEntries();
    });
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await supabase.from('entries').delete().eq('id', entryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted successfully!')),
      );
      _refreshEntries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshEntries,
        child: FutureBuilder<List<Entry>>(
          future: _entriesFuture,
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
                      title: Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: (entry.displayColor != null && entry.displayColor!.computeLuminance() < 0.5)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4.0),
                          Text(
                            DateFormat('yyyy-MM-dd').format(entry.entryDate),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: (entry.displayColor != null && entry.displayColor!.computeLuminance() < 0.5)
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            entry.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          _refreshEntries();
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteEntry(entry.id),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EntryEditorPage(),
            ),
          );
          if (result == true) {
            _refreshEntries();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}