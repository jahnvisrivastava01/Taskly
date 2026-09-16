import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/task_storage.dart';

/// Holds the in-memory task list, persists changes, and keeps reminder
/// notifications in sync with each task's state.
///
/// This file must contain the PROVIDER only. The TasksScreen widget lives in
/// lib/screens/tasks_screen.dart - do not paste screen code in here.
class TaskProvider extends ChangeNotifier {
  final TaskStorage _storage = TaskStorage();
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Not-yet-completed tasks, soonest reminder first, then by creation time.
  List<Task> get activeTasks {
    final list = _tasks.where((t) => !t.isCompleted).toList();
    list.sort((a, b) {
      if (a.reminderAt == null && b.reminderAt == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (a.reminderAt == null) return 1;
      if (b.reminderAt == null) return -1;
      return a.reminderAt!.compareTo(b.reminderAt!);
    });
    return list;
  }

  /// Completed tasks, most recently finished first.
  List<Task> get completedTasks {
    final list = _tasks.where((t) => t.isCompleted).toList();
    list.sort((a, b) =>
        (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    return list;
  }

  Future<void> load() async {
    _tasks = await _storage.loadTasks();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveTasks(_tasks);

  Future<Task> addTask({
    required String title,
    String description = '',
    DateTime? reminderAt,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      reminderAt: reminderAt,
    );
    _tasks.add(task);
    notifyListeners();
    await _persist();

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

  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _tasks[index].copyWith(
      title: title,
      description: description,
      reminderAt: reminderAt,
      clearReminder: clearReminder,
    );
    _tasks[index] = updated;
    notifyListeners();
    await _persist();

    // Re-schedule from scratch so an edited time replaces the old alarm.
    await NotificationService.instance.cancelReminder(id);
    if (updated.reminderAt != null && !updated.isCompleted) {
      await NotificationService.instance.scheduleReminder(
        id: updated.id,
        title: updated.title,
        body: updated.description,
        dateTime: updated.reminderAt!,
      );
    }
  }

  Future<void> completeTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    _tasks[index] = _tasks[index].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    await NotificationService.instance.cancelReminder(id);
  }

  Future<void> restoreTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _tasks[index];
    _tasks[index] = task.copyWith(
      isCompleted: false,
      clearCompletedAt: true,
    );
    notifyListeners();
    await _persist();

    if (task.reminderAt != null && task.reminderAt!.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        id: task.id,
        title: task.title,
        body: task.description,
        dateTime: task.reminderAt!,
      );
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persist();
    await NotificationService.instance.cancelReminder(id);
  }
}
