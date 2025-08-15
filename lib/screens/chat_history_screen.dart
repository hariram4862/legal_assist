import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class Session {
  final String id;
  String title;
  final DateTime createdAt;

  Session({required this.id, required this.title, required this.createdAt});

  factory Session.fromJson(Map<String, dynamic> json) {
    final utcTime = DateTime.parse(json['created_at']).toUtc();

    return Session(
      id: json['_id'],
      title: json['session_name'] ?? 'Untitled',
      createdAt: utcTime.toLocal(),
    );
  }
}

Future<List<Session>> fetchSessions(String email) async {
  final response = await Dio().get(
    'https://refined-able-grouper.ngrok-free.app/get_sessions/$email',
  );
  final List data = response.data['sessions'];
  return data.map((e) => Session.fromJson(e)).toList();
}

Future<Map<String, dynamic>> fetchSessionChat(String sessionId) async {
  final response = await Dio().get(
    'https://refined-able-grouper.ngrok-free.app/get_session_chat/$sessionId',
  );

  final data = response.data;
  final List<Map<String, String>> messages = [];

  if (data.containsKey('messages') && data['messages'] is List) {
    for (var msg in data['messages']) {
      messages.add({'role': 'user', 'text': msg['prompt']});
      messages.add({'role': 'bot', 'text': msg['response']});
    }
  }

  return {'sessionId': data['_id'], 'messages': messages};
}

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  late Future<List<Session>> _sessions;
  final _user = FirebaseAuth.instance.currentUser;
  final Set<String> _selectedSessionIds = {};
  bool _isSelectionMode = false;

  List<Session> _allSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = fetchSessions(_user?.email ?? '');
      _selectedSessionIds.clear();
    });
  }

  void _toggleSelection(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }

      // Exit selection mode if no items selected
      if (_selectedSessionIds.isEmpty) {
        _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
      }
    });
  }

  // void _clearSelection() {
  //   setState(() => _selectedSessionIds.clear());
  // }

  Future<void> _renameSession() async {
    if (_selectedSessionIds.length != 1) return;
    final session = _allSessions.firstWhere(
      (s) => s.id == _selectedSessionIds.first,
    );
    final controller = TextEditingController(text: session.title);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Rename Session"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Enter new name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text("Rename"),
              ),
            ],
          ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        await Dio().post(
          "https://refined-able-grouper.ngrok-free.app/rename_session",
          data: {"session_id": session.id, "new_name": newName.trim()},
        );
        _loadSessions();
      } catch (e) {
        _showError("Rename failed", e);
      }
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now(); // already local
    final difference = now.difference(date); // date is local

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _deleteSessions() async {
    if (_selectedSessionIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Sessions"),
            content: Text(
              "Are you sure you want to delete ${_selectedSessionIds.length} sessions?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        for (var id in _selectedSessionIds) {
          await Dio().delete(
            "https://refined-able-grouper.ngrok-free.app/delete_session/$id",
          );
        }
        _loadSessions();
      } catch (e) {
        _showError("Delete failed", e);
      }
    }
  }

  Future<void> _shareSessions() async {
    if (_selectedSessionIds.length != 1) return;
    final sessionId = _selectedSessionIds.first;

    try {
      final response = await Dio().post(
        "https://refined-able-grouper.ngrok-free.app/share_session/$sessionId",
      );

      final shareId = response.data['share_id'];
      final pin = response.data['pin'];

      // Show bottom sheet instead of dialog
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🔐 Share This Session",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText("Share ID: $shareId"),
                const SizedBox(height: 10),
                SelectableText("PIN: $pin"),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showError("Share failed", e);
    }
  }

  void _showError(String title, Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("❌ $title: $e")));
  }

  List<Widget> _buildFloatingMenuOptions(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.edit,
        'label': 'Rename',
        'onPressed': () async {
          if (_selectedSessionIds.length != 1) {
            _showSnack("❗ Select only one session to rename");
          } else {
            await _renameSession();
            _toggleFab(false);
          }
        },
      },
      {
        'icon': Icons.share,
        'label': 'Share',
        'onPressed': () async {
          if (_selectedSessionIds.isEmpty) {
            _showSnack("❗ Select sessions to share");
          } else if (_selectedSessionIds.length > 1) {
            _showSnack("❗ Select only one session to share");
          } else {
            await _shareSessions();
            _toggleFab(false);
          }
        },
      },
      {
        'icon': Icons.delete,
        'label': 'Delete',
        'onPressed': () async {
          if (_selectedSessionIds.isEmpty) {
            _showSnack("❗ Select sessions to delete");
          } else {
            await _deleteSessions();
            _toggleFab(false);
          }
        },
      },
    ];

    return List.generate(options.length, (index) {
      return Positioned(
        right: 16,
        bottom: 90.0 + (index * 60), // stacked 60px apart above FAB
        child: Material(
          color: Colors.black.withOpacity(0.85),
          elevation: 6,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: options[index]['onPressed'],
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    options[index]['label'],
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Icon(options[index]['icon'], color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _fabMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Session>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          _allSessions = snapshot.data!;
          if (_allSessions.isEmpty) {
            return const Center(child: Text("No sessions found."));
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => _loadSessions(),
                child: ListView.builder(
                  itemCount: _allSessions.length,
                  itemBuilder: (context, index) {
                    final session = _allSessions[index];
                    final isSelected = _selectedSessionIds.contains(session.id);

                    return GestureDetector(
                      onTap: () async {
                        if (_isSelectionMode) {
                          _toggleSelection(session.id);
                        } else {
                          final sessionData = await fetchSessionChat(
                            session.id,
                          );
                          if (mounted) Navigator.pop(context, sessionData);
                        }
                      },
                      onDoubleTap: () => _toggleSelection(session.id),
                      onLongPress: () => _toggleSelection(session.id),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: isSelected ? 5 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side:
                              isSelected
                                  ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    width: 1.25,
                                  )
                                  : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child:
                                        _isSelectionMode
                                            ? Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons
                                                      .radio_button_unchecked,
                                              key: ValueKey(
                                                isSelected,
                                              ), // ensures switch triggers
                                              color:
                                                  isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .secondary // Grey[900]
                                                      : Colors.grey[500],

                                              size: 24,
                                            )
                                            : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  session.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.secondary
                                            : Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimeAgo(session.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Floating Buttons (Rename, Share, Delete)
              // Floating Buttons (Rename, Share, Delete)
              if (_fabMenuOpen) ..._buildFloatingMenuOptions(context),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _fabMenuOpen ? Colors.black87 : Colors.grey.shade800,
        onPressed: () {
          setState(() {
            _fabMenuOpen = !_fabMenuOpen;
            _isSelectionMode = _fabMenuOpen;
            if (!_fabMenuOpen) _selectedSessionIds.clear();
          });
        },
        child: Icon(
          _fabMenuOpen ? Icons.close : Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleFab(bool open) {
    setState(() {
      _fabMenuOpen = open;
      _isSelectionMode = open;
      if (!open) _selectedSessionIds.clear();
    });
  }
}
