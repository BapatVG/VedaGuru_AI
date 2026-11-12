import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class YagyaBoardScreen extends StatefulWidget {
  const YagyaBoardScreen({super.key});

  @override
  State<YagyaBoardScreen> createState() => _YagyaBoardScreenState();
}

class _YagyaBoardScreenState extends State<YagyaBoardScreen> {
  List<dynamic> _boards = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _dateController = TextEditingController(text: '2026-11-20');

  // Active Board Tasks
  Map<String, dynamic>? _selectedBoard;
  List<dynamic> _tasks = [];
  bool _isLoadingTasks = false;
  final _taskDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBoards();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  Future<void> _fetchBoards() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final boards = await ApiService.getYagyaBoards(username);
    if (mounted) {
      setState(() {
        _boards = boards;
        _isLoading = false;
      });
    }
  }

  Future<void> _createBoard() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/yagya/boards');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'event_date': _dateController.text.trim(),
          'created_by': username,
        }),
      );
      if (res.statusCode == 200) {
        _titleController.clear();
        _fetchBoards();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {}
  }

  Future<void> _deleteBoard(int boardId) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/yagya/boards/$boardId');
      await http.delete(uri);
      setState(() => _selectedBoard = null);
      _fetchBoards();
    } catch (_) {}
  }

  Future<void> _fetchTasks(Map<String, dynamic> board) async {
    setState(() {
      _selectedBoard = board;
      _isLoadingTasks = true;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/yagya/tasks/${board['id']}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _tasks = data['tasks'] ?? [];
          _isLoadingTasks = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _addTask() async {
    final desc = _taskDescController.text.trim();
    if (desc.isEmpty || _selectedBoard == null) return;

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/yagya/tasks');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'board_id': _selectedBoard!['id'],
          'task_desc': desc,
          'assigned_to': '',
        }),
      );
      if (res.statusCode == 200) {
        _taskDescController.clear();
        _fetchTasks(_selectedBoard!);
      }
    } catch (_) {}
  }

  Future<void> _toggleTaskStatus(int taskId, bool currentStatus) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/yagya/tasks/$taskId/status');
      await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_completed': !currentStatus}),
      );
      if (_selectedBoard != null) _fetchTasks(_selectedBoard!);
    } catch (_) {}
  }

  void _showCreateBoardDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create Yagya Board', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title (e.g. Diwali Havan)')),
            const SizedBox(height: 10),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _createBoard, child: const Text('Create Board')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedBoard == null ? 'Yagya Event Boards' : _selectedBoard!['title'] ?? 'Board',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        leading: _selectedBoard != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedBoard = null),
              )
            : null,
      ),
      floatingActionButton: _selectedBoard == null
          ? FloatingActionButton.extended(
              onPressed: _showCreateBoardDialog,
              backgroundColor: AppTheme.primarySaffron,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Board', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _selectedBoard == null ? _buildBoardsList() : _buildTasksView(),
    );
  }

  Widget _buildBoardsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron));
    }
    if (_boards.isEmpty) {
      return const Center(child: Text('No ritual boards created yet. Tap + to create one.', style: TextStyle(color: AppTheme.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _boards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final b = _boards[idx];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.surfaceElevated,
              child: Text('📋', style: TextStyle(fontSize: 20)),
            ),
            title: Text(b['title'] ?? '', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
            subtitle: Text('Event Date: ${b['event_date'] ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _deleteBoard(b['id']),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primarySaffron),
              ],
            ),
            onTap: () => _fetchTasks(b),
          ),
        );
      },
    );
  }

  Widget _buildTasksView() {
    return Column(
      children: [
        // Add Task Input
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskDescController,
                  decoration: const InputDecoration(
                    hintText: 'Add preparation task (e.g., Procure Ganga Jal)...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                child: const Text('Add'),
              ),
            ],
          ),
        ),

        // Tasks List
        Expanded(
          child: _isLoadingTasks
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
              : _tasks.isEmpty
                  ? const Center(child: Text('No tasks in this board yet. Add one above!', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final t = _tasks[idx];
                        final isDone = t['status'] == 'Completed';
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: CheckboxListTile(
                            value: isDone,
                            activeColor: AppTheme.primarySaffron,
                            title: Text(
                              t['task_desc'] ?? '',
                              style: TextStyle(
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? Colors.grey : AppTheme.textDark,
                              ),
                            ),
                            onChanged: (_) => _toggleTaskStatus(t['id'], isDone),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
