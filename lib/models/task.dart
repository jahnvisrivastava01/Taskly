/// A single to-do item.
///
/// The class is called `Task` (not `TodoTask`) - every screen, widget
/// and the provider refer to this name.

enum TaskPriority {
  low,
  medium,
  high,
}

enum TaskCategory {
  work,
  college,
  personal,
  shopping,
  other,
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final TaskPriority priority;
  final TaskCategory category;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.reminderAt,
    this.isCompleted = false,
    this.completedAt,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool? isCompleted,
    DateTime? completedAt,
    TaskPriority? priority,
    TaskCategory? category,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderAt: clearReminder
          ? null
          : (reminderAt ?? this.reminderAt),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt
          ? null
          : (completedAt ?? this.completedAt),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE TASK AS JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reminderAt': reminderAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'priority': priority.name,
        'category': category.name,
      };

  // ---------------------------------------------------------------------------
  // LOAD TASK FROM JSON
  // ---------------------------------------------------------------------------

  factory Task.fromJson(Map<String, dynamic> json) {
    // Support old saved key names.
    final reminderRaw = json['reminderAt'] ?? json['reminder'];
    final completedRaw = json['isCompleted'] ?? json['completed'];

    // -------------------------------------------------------------------------
    // PRIORITY
    // -------------------------------------------------------------------------

    final priorityRaw = json['priority'];

    final priority = priorityRaw is String
        ? TaskPriority.values.firstWhere(
            (value) => value.name == priorityRaw,
            orElse: () => TaskPriority.medium,
          )
        : TaskPriority.medium;

    // -------------------------------------------------------------------------
    // CATEGORY
    // -------------------------------------------------------------------------

    final categoryRaw = json['category'];

    final category = categoryRaw is String
        ? TaskCategory.values.firstWhere(
            (value) => value.name == categoryRaw,
            orElse: () => TaskCategory.other,
          )
        : TaskCategory.other;

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      reminderAt:
          reminderRaw is String ? DateTime.tryParse(reminderRaw) : null,
      isCompleted: completedRaw as bool? ?? false,
      completedAt: json['completedAt'] is String
          ? DateTime.tryParse(
              json['completedAt'] as String,
            )
          : null,
      createdAt: json['createdAt'] is String
          ? (DateTime.tryParse(
                json['createdAt'] as String,
              ) ??
              DateTime.now())
          : DateTime.now(),

      // Restore saved priority.
      priority: priority,

      // Restore saved category.
      category: category,
    );
  }
}