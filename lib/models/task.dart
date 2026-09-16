/// A single to-do item.
///
/// Note: the class is called `Task` (not `TodoTask`) - every screen, widget
/// and the provider refer to this name.
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.reminderAt,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reminderAt': reminderAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    // Accepts both the current key names and the older ones
    // ('completed' / 'reminder') so previously saved data still loads.
    final reminderRaw = json['reminderAt'] ?? json['reminder'];
    final completedRaw = json['isCompleted'] ?? json['completed'];

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      reminderAt:
          reminderRaw is String ? DateTime.tryParse(reminderRaw) : null,
      isCompleted: completedRaw as bool? ?? false,
      completedAt: json['completedAt'] is String
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] is String
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
