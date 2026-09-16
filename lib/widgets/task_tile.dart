import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

/// A single task row.
///
/// Handles three animations on its own:
/// - Entrance: fades + slides in when first built (new task, or first load),
///   staggered by [index] so a freshly loaded list cascades in.
/// - Check bounce: a quick scale pop when the checkbox is tapped.
/// - Exit: once [isExiting] flips to true (task marked complete), the tile
///   shrinks + fades out over ~300ms and then calls [onExitComplete], which
///   is when the caller should actually remove it from the data list.
class TaskTile extends StatefulWidget {
  final Task task;
  final int index;
  final bool isExiting;
  final VoidCallback onCheckTap;
  final VoidCallback onExitComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.index,
    required this.isExiting,
    required this.onCheckTap,
    required this.onExitComplete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    if (widget.isExiting) {
      _exitController.value = 1;
    }

    final staggerDelay = Duration(milliseconds: 40 * widget.index.clamp(0, 10));
    Future.delayed(staggerDelay, () {
      if (mounted) _enterController.forward();
    });
  }

  @override
  void didUpdateWidget(covariant TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExiting && !oldWidget.isExiting) {
      _exitController.forward().whenComplete(() {
        if (mounted) widget.onExitComplete();
      });
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleCheckTap() {
    if (widget.isExiting) return;
    _bounceController.forward(from: 0);
    widget.onCheckTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final task = widget.task;
    final checked = task.isCompleted || widget.isExiting;
    final overdue = task.reminderAt != null &&
        !checked &&
        task.reminderAt!.isBefore(DateTime.now());

    final content = Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _handleCheckTap,
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2)
                      .chain(CurveTween(curve: Curves.easeOutBack))
                      .animate(_bounceController),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 2, right: 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checked ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: checked ? scheme.primary : scheme.outline,
                        width: 2,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: checked
                          ? Icon(Icons.check_rounded,
                              key: const ValueKey('checked'),
                              size: 16,
                              color: scheme.onPrimary)
                          : const SizedBox(key: ValueKey('unchecked')),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            decoration:
                                checked ? TextDecoration.lineThrough : null,
                            color: checked
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                      child: Text(task.title),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (task.reminderAt != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: overdue
                              ? scheme.errorContainer
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: overdue
                                  ? scheme.onErrorContainer
                                  : scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(task.reminderAt!),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: overdue
                                        ? scheme.onErrorContainer
                                        : scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
      ),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(_exitController),
        child: FadeTransition(
          opacity: _enterController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
