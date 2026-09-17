import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/completed_tasks_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _checkingIds = {};

  late final AnimationController _headerController;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _bootstrap(),
    );
  }

  Future<void> _bootstrap() async {
    final provider = context.read<TaskProvider>();

    if (!provider.isLoaded) {
      await provider.load();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CHECK / COMPLETE
  // ---------------------------------------------------------------------------

  void _handleCheckTap(Task task) {
    if (_checkingIds.contains(task.id)) return;

    setState(() {
      _checkingIds.add(task.id);
    });
  }

  Future<void> _handleExitComplete(Task task) async {
    await context.read<TaskProvider>().completeTask(task.id);

    if (mounted) {
      setState(() {
        _checkingIds.remove(task.id);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ADD / EDIT
  // ---------------------------------------------------------------------------

  void _openAddSheet({Task? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskSheet(
        existing: editing,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETED TASKS
  // ---------------------------------------------------------------------------

  void _openCompleted() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CompletedTasksSheet(),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final active = provider.activeTasks;
        final completedCount = provider.completedTasks.length;
        final total = active.length + completedCount;

        final progress =
            total == 0 ? 0.0 : completedCount / total;

        final rows = _buildRows(active);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // ----------------------------------------------------------------
                // HEADER
                // ----------------------------------------------------------------

                FadeTransition(
                  opacity: _headerController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _headerController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Tasks',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  total == 0
                                      ? 'Nothing on your list yet'
                                      : '$completedCount of $total completed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color:
                                            scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          IconButton.filledTonal(
                            onPressed: _openCompleted,
                            icon: const Icon(
                              Icons.checklist_rtl_rounded,
                            ),
                            tooltip: 'Completed tasks',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // PROGRESS BAR
                // ----------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: progress,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor:
                              scheme.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation(
                            scheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------------------------------
                // TASK LIST
                // ----------------------------------------------------------------

                Expanded(
                  child: !provider.isLoaded
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : active.isEmpty
                          ? const EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                100,
                              ),
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];

                                // ------------------------------------------------
                                // DATE HEADING
                                // ------------------------------------------------

                                if (row.isHeader) {
                                  return _DateHeaderLabel(
                                    date: row.headerDate!,
                                  );
                                }

                                final task = row.task!;

                                // ------------------------------------------------
                                // TASK TILE
                                // ------------------------------------------------

                                return TaskTile(
                                  key: ValueKey(task.id),

                                  task: task,

                                  index: row.taskIndex,

                                  isExiting:
                                      _checkingIds.contains(task.id),

                                  // CHECK
                                  onCheckTap: () =>
                                      _handleCheckTap(task),

                                  // COMPLETE AFTER EXIT ANIMATION
                                  onExitComplete: () =>
                                      _handleExitComplete(task),

                                 
                                  

                                  // DELETE
                                  onDelete: () => context
                                      .read<TaskProvider>()
                                      .deleteTask(task.id),

                                  // EDIT FROM ⋮ MENU
                                  onEdit: () =>
                                      _openAddSheet(
                                    editing: task,
                                  ),

                                  // RESTORE
                                  //
                                  // Active tasks are the only ones displayed
                                  // here, so this callback is mainly useful
                                  // if TaskTile is reused elsewhere.
                                  onRestore: () => context
                                      .read<TaskProvider>()
                                      .restoreTask(task.id),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------------------------
          // ADD TASK BUTTON
          // --------------------------------------------------------------------

          floatingActionButton:
              FloatingActionButton.extended(
            onPressed: () => _openAddSheet(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Task'),
          ),
        );
      },
    );
  }
}

// ============================================================================
// DATE GROUPING
// ============================================================================

class _TaskRow {
  final DateTime? headerDate;
  final bool isHeader;
  final Task? task;
  final int taskIndex;

  _TaskRow.header(this.headerDate)
      : isHeader = true,
        task = null,
        taskIndex = -1;

  _TaskRow.task(this.task, this.taskIndex)
      : isHeader = false,
        headerDate = null;
}

/// Creates rows like:
///
/// Today · 16th September 2026
///     Task 1
///     Task 2
///
/// Tomorrow · 17th September 2026
///     Task 3
///
/// 20th September 2026
///     Task 4
List<_TaskRow> _buildRows(List<Task> tasks) {
  final rows = <_TaskRow>[];

  DateTime? currentDay;
  var taskIndex = 0;

  for (final task in tasks) {
    // If a reminder exists, use its date.
    // Otherwise use the task creation date.
    final sourceDate = task.reminderAt ?? task.createdAt;

    final day = DateTime(
      sourceDate.year,
      sourceDate.month,
      sourceDate.day,
    );

    // Add a new date header whenever the day changes.
    if (currentDay == null || day != currentDay) {
      rows.add(
        _TaskRow.header(day),
      );

      currentDay = day;
    }

    rows.add(
      _TaskRow.task(
        task,
        taskIndex,
      ),
    );

    taskIndex++;
  }

  return rows;
}

// ============================================================================
// DATE HEADER
// ============================================================================

class _DateHeaderLabel extends StatelessWidget {
  final DateTime date;

  const _DateHeaderLabel({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        18,
        4,
        8,
      ),
      child: Row(
        children: [
          Text(
            _formatDateHeader(date),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATE FORMATTING
// ============================================================================

String _ordinalDay(int day) {
  // 11th, 12th and 13th are exceptions.
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }

  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String _formatDateHeader(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final targetDate = DateTime(
    date.year,
    date.month,
    date.day,
  );

  final difference = targetDate.difference(today).inDays;

  final monthName = DateFormat('MMMM').format(date);

  final fullDate =
      '${_ordinalDay(date.day)} '
      '$monthName '
      '${date.year}';

  if (difference == 0) {
    return 'Today · $fullDate';
  }

  if (difference == 1) {
    return 'Tomorrow · $fullDate';
  }

  if (difference == -1) {
    return 'Yesterday · $fullDate';
  }

  return fullDate;
}