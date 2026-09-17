import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditTaskSheet extends StatefulWidget {
  final Task? existing;

  const AddEditTaskSheet({
    super.key,
    this.existing,
  });

  @override
  State<AddEditTaskSheet> createState() =>
      _AddEditTaskSheetState();
}

class _AddEditTaskSheetState
    extends State<AddEditTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  final _formKey = GlobalKey<FormState>();

  DateTime? _reminder;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(
      text: widget.existing?.title ?? '',
    );

    _descCtrl = TextEditingController(
      text: widget.existing?.description ?? '',
    );

    _reminder = widget.existing?.reminderAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // PICK REMINDER
  // -------------------------------------------------------------------------

  Future<void> _pickReminder() async {
    final now = DateTime.now();

    final initialDate = _reminder != null &&
            _reminder!.isAfter(now)
        ? _reminder!
        : now;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 365 * 3),
      ),
    );

    if (date == null || !mounted) return;

    final initialTime = _reminder != null &&
            _reminder!.isAfter(now)
        ? TimeOfDay.fromDateTime(_reminder!)
        : TimeOfDay.fromDateTime(
            now.add(
              const Duration(minutes: 30),
            ),
          );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null || !mounted) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Don't allow a reminder in the past.
    if (!selectedDateTime.isAfter(now)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a future date and time.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _reminder = selectedDateTime;
    });
  }

  // -------------------------------------------------------------------------
  // SAVE
  // -------------------------------------------------------------------------

  Future<void> _save() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<TaskProvider>();

      if (widget.existing == null) {
        await provider.addTask(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          reminderAt: _reminder,
        );
      } else {
        await provider.updateTask(
          widget.existing!.id,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          reminderAt: _reminder,
          clearReminder: _reminder == null,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // HANDLE
              // -------------------------------------------------------------

              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // TITLE
              // -------------------------------------------------------------

              Text(
                isEditing ? 'Edit Task' : 'New Task',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // TASK TITLE
              // -------------------------------------------------------------

              TextFormField(
                controller: _titleCtrl,
                autofocus: !isEditing,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'What do you need to do?',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Give the task a title';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // DESCRIPTION
              // -------------------------------------------------------------

              TextFormField(
                controller: _descCtrl,
                textCapitalization:
                    TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // REMINDER
              // -------------------------------------------------------------

              InkWell(
                onTap: _isSaving
                    ? null
                    : _pickReminder,
                borderRadius:
                    BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: scheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _reminder == null
                            ? Icons
                                .notifications_none_rounded
                            : Icons
                                .notifications_active_rounded,
                        color: scheme.primary,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reminder == null
                                  ? 'Set a reminder'
                                  : 'Reminder',
                              style: textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            if (_reminder != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'EEE, MMM d · h:mm a',
                                ).format(_reminder!),
                                style: textTheme.bodySmall
                                    ?.copyWith(
                                  color: scheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_reminder != null)
                        IconButton(
                          tooltip: 'Remove reminder',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                          ),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _reminder = null;
                                  });
                                },
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color:
                              scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // SAVE BUTTON
              // -------------------------------------------------------------

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEditing
                              ? 'Save Changes'
                              : 'Add Task',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}