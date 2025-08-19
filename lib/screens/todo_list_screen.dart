import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import 'add_edit_todo_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoService _todoService = TodoService();
  List<Todo> _todos = [];
  bool _isLoading = true;
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final todos = await _todoService.getTodos();
      setState(() {
        _todos = _todoService.sortTodosByReminder(
          todos,
          showHidden: _showHidden,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading todos: $e')));
      }
    }
  }

  Future<void> _deleteTodo(String todoId) async {
    try {
      await _todoService.deleteTodo(todoId);
      await _loadTodos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting todo: $e')));
      }
    }
  }

  Future<void> _markTodoCompleted(Todo todo, {String? note}) async {
    try {
      await _todoService.markTodoAsCompleted(todo.id, note: note);
      await _loadTodos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing todo: $e')));
      }
    }
  }

  Future<void> _snoozeTodo(Todo todo) async {
    try {
      await _todoService.snoozeTodo(todo.id);
      await _loadTodos();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Todo snoozed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error snoozing todo: $e')));
      }
    }
  }

  Future<void> _toggleTodoCompletion(Todo todo) async {
    if (todo.reminderType == ReminderType.none ||
        todo.reminderType == ReminderType.custom) {
      // For non-recurring todos, show completion dialog
      _showCompletionDialog(todo);
    } else {
      // For recurring todos, mark as completed automatically
      await _markTodoCompleted(todo);
    }
  }

  String _formatReminder(Todo todo) {
    if (todo.reminderType == ReminderType.none || todo.nextReminder == null) {
      return 'No reminder';
    }

    final reminder = todo.nextReminder!;
    final now = DateTime.now();
    final isOverdue = reminder.isBefore(now);

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final reminderText = dateFormat.format(reminder);

    if (isOverdue) {
      return 'Overdue: $reminderText';
    }

    return 'Reminder: $reminderText';
  }

  Color _getReminderColor(Todo todo) {
    if (todo.reminderType == ReminderType.none || todo.nextReminder == null) {
      return Colors.grey;
    }

    final reminder = todo.nextReminder!;
    final now = DateTime.now();

    if (reminder.isBefore(now)) {
      return Colors.red; // Overdue
    } else if (reminder.difference(now).inHours < 24) {
      return Colors.orange; // Due within 24 hours
    }

    return Colors.blue; // Future reminder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private TODO'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTodos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTodos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _todos.length,
                itemBuilder: (context, index) => _buildTodoCard(_todos[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditTodoScreen()),
          );
          if (result == true) {
            await _loadTodos();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No todos yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first todo',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    final reminderColor = _getReminderColor(todo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: todo.isCompleted
            ? BorderSide(color: Colors.green[300]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditTodoScreen(todo: todo),
            ),
          );
          if (result == true) {
            await _loadTodos();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleTodoCompletion(todo),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        todo.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: todo.isCompleted
                            ? Colors.green
                            : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted ? Colors.grey[600] : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(todo);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (todo.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  todo.notes,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: todo.isCompleted
                        ? Colors.grey[500]
                        : Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: reminderColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatReminder(todo),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: reminderColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd').format(todo.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTodo(todo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
