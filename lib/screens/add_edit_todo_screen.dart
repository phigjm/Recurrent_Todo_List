import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;

  const AddEditTodoScreen({super.key, this.todo});

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _todoService = TodoService();

  ReminderType _reminderType = ReminderType.none;
  bool _isLoading = false;
  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.todo!.title;
      _notesController.text = widget.todo!.notes;
      _reminderType = widget.todo!.reminderType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (_isEditing) {
        // Update existing todo
        final updatedTodo = widget.todo!.copyWith(
          title: _titleController.text.trim(),
          notes: _notesController.text.trim(),
          reminderType: _reminderType,
          nextReminder: _reminderType != ReminderType.none
              ? _calculateNextReminder()
              : null,
          lastUpdated: now,
        );
        await _todoService.updateTodo(updatedTodo);
      } else {
        // Create new todo
        final newTodo = Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          notes: _notesController.text.trim(),
          reminderType: _reminderType,
          nextReminder: _reminderType != ReminderType.none
              ? _calculateNextReminder()
              : null,
          createdAt: now,
        );
        await _todoService.addTodo(newTodo);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving todo: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _calculateNextReminder() {
    final now = DateTime.now();
    DateTime next;

    switch (_reminderType) {
      case ReminderType.daily:
        next = DateTime(now.year, now.month, now.day + 1, 9, 0);
        break;
      case ReminderType.weekly:
        next = DateTime(now.year, now.month, now.day + 7, 9, 0);
        break;
      case ReminderType.monthly:
        next = DateTime(now.year, now.month + 1, now.day, 9, 0);
        break;
      case ReminderType.none:
        return now;
    }

    // If the calculated time is in the past, move it to tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  String _getReminderTypeText(ReminderType type) {
    switch (type) {
      case ReminderType.none:
        return 'No reminder';
      case ReminderType.daily:
        return 'Daily';
      case ReminderType.weekly:
        return 'Weekly';
      case ReminderType.monthly:
        return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Todo' : 'Add Todo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTodo,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter todo title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any additional notes or details',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Reminder Section
              Text(
                'Reminder',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: ReminderType.values.map((type) {
                    return RadioListTile<ReminderType>(
                      title: Text(_getReminderTypeText(type)),
                      subtitle: _buildReminderSubtitle(type),
                      value: type,
                      groupValue: _reminderType,
                      onChanged: (value) {
                        setState(() {
                          _reminderType = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              if (_reminderType != ReminderType.none) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next reminder:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy \'at\' HH:mm',
                                ).format(_calculateNextReminder()),
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveTodo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditing ? 'Update Todo' : 'Create Todo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget? _buildReminderSubtitle(ReminderType type) {
    if (type == ReminderType.none) return null;

    String description;
    switch (type) {
      case ReminderType.daily:
        description = 'Remind me every day at 9:00 AM';
        break;
      case ReminderType.weekly:
        description = 'Remind me every week';
        break;
      case ReminderType.monthly:
        description = 'Remind me every month';
        break;
      case ReminderType.none:
        return null;
    }

    return Text(
      description,
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }
}
