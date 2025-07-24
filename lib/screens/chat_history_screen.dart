import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class Session {
  final String id;
  String title;
  final DateTime? updatedAt;

  Session({required this.id, required this.title, required this.updatedAt});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['_id'],
      title: json['session_name'] ?? 'Untitled',
      updatedAt: DateTime.parse(
        json['updated_at'],
      ), // backend must provide this
    );
  }
}

// Fetch all sessions by user email
Future<List<Session>> fetchSessions(String email) async {
  final response = await Dio().get(
    'https://refined-able-grouper.ngrok-free.app/get_sessions/$email',
  );
  final List data = response.data['sessions'];
  return data.map((e) => Session.fromJson(e)).toList();
}

// Fetch chat messages for one session
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

  @override
  void initState() {
    super.initState();
    _sessions = fetchSessions(_user?.email ?? '');
  }

  void _refresh() =>
      setState(() => _sessions = fetchSessions(_user?.email ?? ''));

  Future<void> _batchAction(String action) async {
    final List<Session>? selected = await showModalBottomSheet<List<Session>>(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        return _SelectSessionsSheet(
          sessionsFuture: _sessions,
          action: action,
          onApply: (List<Session> sel) => Navigator.pop(c, sel),
        );
      },
    );
    if (selected == null || selected.isEmpty) return;

    try {
      if (action == 'share') {
        for (var s in selected) {
          final data = await fetchSessionChat(s.id);
          final msgs = (data['messages'] as List<Map<String, String>>)
              .map((m) => "${m['role']!.toUpperCase()}: ${m['text']}")
              .join("\n\n");
          await Share.share(msgs, subject: s.title);
        }
      } else if (action == 'rename') {
        // for simplicity rename only first
        final newName = await _askRename(selected.first);
        if (newName != null) {
          await Dio().post(
            "https://.../rename_session",
            data: {"session_id": selected.first.id, "new_name": newName},
          );
          _refresh();
        }
      } else if (action == 'delete') {
        for (var s in selected) {
          await Dio().delete("https://.../delete_session/${s.id}");
        }
        _refresh();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$action failed: $e")));
    }
  }

  Future<String?> _askRename(Session session) {
    final c = TextEditingController(text: session.title);
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Rename session'),
            content: TextField(controller: c),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _batchAction('share'),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _batchAction('rename'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _batchAction('delete'),
          ),
        ],
      ),
      body: FutureBuilder<List<Session>>(
        future: _sessions,
        builder: (ctx, s) {
          if (s.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Center(child: Text("Error: ${s.error}"));
          final sessions = s.data ?? [];
          if (sessions.isEmpty)
            return const Center(child: Text('No sessions found.'));

          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: sessions.length,
            itemBuilder: (ctx2, i) {
              final sess = sessions[i];
              return ListTile(
                title: Text(sess.title),
                subtitle: Text(
                  sess.updatedAt != null
                      ? timeago.format(sess.updatedAt!)
                      : 'Updated time unknown',
                ),

                leading: const Icon(Icons.chat_bubble_outline),
                onTap: () async {
                  final chat = await fetchSessionChat(sess.id);
                  if (!mounted) return;
                  Navigator.pop(context, chat);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SelectSessionsSheet extends StatefulWidget {
  final Future<List<Session>> sessionsFuture;
  final String action;
  final Function(List<Session>) onApply;

  const _SelectSessionsSheet({
    super.key,
    required this.sessionsFuture,
    required this.action,
    required this.onApply,
  });

  @override
  State<_SelectSessionsSheet> createState() => _SelectSessionsSheetState();
}

class _SelectSessionsSheetState extends State<_SelectSessionsSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext ctx) {
    return FutureBuilder<List<Session>>(
      future: widget.sessionsFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        final items = snap.data ?? [];
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select sessions to ${widget.action}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children:
                      items.map((s) {
                        final sel = _selectedIds.contains(s.id);
                        return CheckboxListTile(
                          value: sel,
                          title: Text(s.title),
                          onChanged: (_) {
                            setState(() {
                              if (sel)
                                _selectedIds.remove(s.id);
                              else
                                _selectedIds.add(s.id);
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedIds.isEmpty
                            ? null
                            : () {
                              final sel =
                                  items
                                      .where((x) => _selectedIds.contains(x.id))
                                      .toList();
                              widget.onApply(sel);
                            },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
