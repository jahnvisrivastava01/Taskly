import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/task_storage.dart';

class TaskProvider extends ChangeNotifier {
  final TaskStorage _storage = TaskStorage();

  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];

  bool _isLoaded = false;

  // -------------------------------------------------------------------------
  // GETTERS
  // -------------------------------------------------------------------------

  bool get isLoaded => _isLoaded;

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get activeTasks {
    final list = _tasks
        .where((task) => !task.isCompleted)
        .toList();

    list.sort((a, b) {
      final aDate = a.reminderAt ?? a.createdAt;
      final bDate = b.reminderAt ?? b.createdAt;

      return aDate.compareTo(bDate);
    });

    return list;
  }

  List<Task> get completedTasks {
    final list = _tasks
        .where((task) => task.isCompleted)
        .toList();

    list.sort(
      (a, b) => (b.completedAt ?? b.createdAt)
          .compareTo(
            a.completedAt ?? a.createdAt,
          ),
    );

    return list;
  }

  int get totalTasks => _tasks.length;

  int get activeCount =>
      _tasks.where((task) => !task.isCompleted).length;

  int get completedCount =>
      _tasks.where((task) => task.isCompleted).length;

  // -------------------------------------------------------------------------
  // LOAD TASKS
  // -------------------------------------------------------------------------

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      _tasks = await _storage.loadTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
    }

    _isLoaded = true;

    notifyListeners();

    // Restore future reminders after loading saved tasks.
    await _restoreReminders();
  }

  // -------------------------------------------------------------------------
  // RESTORE SAVED REMINDERS
  // -------------------------------------------------------------------------

  Future<void> _restoreReminders() async {
    await NotificationService.instance.init();

    final now = DateTime.now();

    for (final task in _tasks) {
      if (task.isCompleted) continue;

      final reminder = task.reminderAt;

      if (reminder == null) continue;

      if (reminder.isAfter(now)) {
        await NotificationService.instance.scheduleReminder(
          id: task.id,
          title: task.title,
          body: task.description,
          dateTime: reminder,
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // SAVE
  // -------------------------------------------------------------------------

  Future<void> _persist() async {
    try {
      await _storage.saveTasks(_tasks);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // -------------------------------------------------------------------------
  // ADD TASK
  // -------------------------------------------------------------------------

  Future<Task?> addTask({
    required String title,
    String description = '',
    DateTime? reminderAt,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      return null;
    }

    final task = Task(
      id: _uuid.v4(),
      title: cleanTitle,
      description: description.trim(),
      reminderAt: reminderAt,
      createdAt: DateTime.now(),
    );

    _tasks.add(task);

    notifyListeners();

    await _persist();

    // Schedule reminder if one was selected.
    if (reminderAt != null) {
      await NotificationService.instance.scheduleReminder(
        id: task.id,
        title: task.title,
        body: task.description,
        dateTime: reminderAt,
      );
    }

    return task;
  }

  // -------------------------------------------------------------------------
  // UPDATE TASK
  // -------------------------------------------------------------------------

  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) async {
    final index = _tasks.indexWhere(
      (task) => task.id == id,
    );

    if (index == -1) return;

    final current = _tasks[index];

    if (title != null && title.trim().isEmpty) {
      return;
    }

    final updated = current.copyWith(
      title: title?.trim(),
      description: description?.trim(),
      reminderAt: reminderAt,
      clearReminder: clearReminder,
    );

    _tasks[index] = updated;

    notifyListeners();

    await _persist();

    // Remove the old reminder first.
    await NotificationService.instance.cancelReminder(id);

    // Schedule the new reminder if appropriate.
    if (!updated.isCompleted &&
        updated.reminderAt != null &&
        updated.reminderAt!.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        id: updated.id,
        title: updated.title,
        body: updated.description,
        dateTime: updated.reminderAt!,
      );
    }
  }

  // -------------------------------------------------------------------------
  // COMPLETE TASK
  // -------------------------------------------------------------------------

  Future<void> completeTask(String id) async {
    final index = _tasks.indexWhere(
      (task) => task.id == id,
    );

    if (index == -1) return;

    final updated = _tasks[index].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    _tasks[index] = updated;

    // Cancel reminder immediately.
    await NotificationService.instance.cancelReminder(id);

    notifyListeners();

    await _persist();
  }

  // -------------------------------------------------------------------------
  // RESTORE TASK
  // -------------------------------------------------------------------------

  Future<void> restoreTask(String id) async {
    final index = _tasks.indexWhere(
      (task) => task.id == id,
    );

    if (index == -1) return;

    final task = _tasks[index];

    final restored = task.copyWith(
      isCompleted: false,
      clearCompletedAt: true,
    );

    _tasks[index] = restored;

    notifyListeners();

    await _persist();

    // Re-create reminder if it is still in the future.
    if (restored.reminderAt != null &&
        restored.reminderAt!.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        id: restored.id,
        title: restored.title,
        body: restored.description,
        dateTime: restored.reminderAt!,
      );
    }
  }

  // -------------------------------------------------------------------------
  // DELETE TASK
  // -------------------------------------------------------------------------

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere(
      (task) => task.id == id,
    );

    // Cancel its reminder.
    await NotificationService.instance.cancelReminder(id);

    notifyListeners();

    await _persist();
  }
}