import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_models.dart';

/// Formatea una hora entera (0-24) a formato AM/PM.
String _fmtHour(int h) {
  if (h == 0 || h == 24) return '12:00 AM';
  if (h == 12) return '12:00 PM';
  return h < 12 ? '$h:00 AM' : '${h - 12}:00 PM';
}

// ─── Pantalla Principal ───────────────────────────────────────────────────────

class WorkerScheduleScreen extends ConsumerWidget {
  const WorkerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(currentWorkerProfileProvider);

    return workerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (worker) {
        if (worker == null) {
          return const Scaffold(body: Center(child: Text('Perfil no encontrado')));
        }
        final scheduleAsync = ref.watch(workerScheduleProvider(worker.uid));
        return scheduleAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error cargando horario: $e'))),
          data: (schedule) => _ScheduleEditor(
            workerUid: worker.uid,
            initial: schedule,
          ),
        );
      },
    );
  }
}

// ─── Editor de Horario ────────────────────────────────────────────────────────

class _ScheduleEditor extends ConsumerStatefulWidget {
  const _ScheduleEditor({required this.workerUid, required this.initial});

  final String workerUid;
  final ScheduleModel initial;

  @override
  ConsumerState<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends ConsumerState<_ScheduleEditor> {
  late Map<int, List<TimeSlot>> _days;
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Deep copy para no mutar el modelo inmutable
    _days = {
      for (final entry in widget.initial.days.entries)
        entry.key: List<TimeSlot>.from(entry.value),
    };
    _notesCtrl.text = widget.initial.notes ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _markChanged() => setState(() => _hasChanges = true);

  /// Añade una nueva franja al día [dayIndex]. Sugiere la siguiente hora disponible.
  void _addSlot(int dayIndex) {
    final slots = _days[dayIndex] ?? [];
    final lastEnd = slots.isEmpty ? 8 : slots.last.endHour;
    if (lastEnd >= 23) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes agregar más franjas para este día')),
      );
      return;
    }
    final newSlot = TimeSlot(
      startHour: lastEnd,
      endHour: (lastEnd + 2).clamp(1, 24),
    );
    setState(() {
      _days[dayIndex] = [...slots, newSlot];
      _hasChanges = true;
    });
  }

  void _removeSlot(int dayIndex, int slotIndex) {
    setState(() {
      final updated = List<TimeSlot>.from(_days[dayIndex] ?? []);
      updated.removeAt(slotIndex);
      _days[dayIndex] = updated;
      _hasChanges = true;
    });
  }

  void _updateSlot(int dayIndex, int slotIndex, TimeSlot updated) {
    setState(() {
      final slots = List<TimeSlot>.from(_days[dayIndex] ?? []);
      slots[slotIndex] = updated;
      _days[dayIndex] = slots;
      _hasChanges = true;
    });
  }

  /// Muestra un diálogo para editar start/end de una franja.
  Future<void> _editSlotDialog(int dayIndex, int slotIndex) async {
    final slot = (_days[dayIndex] ?? [])[slotIndex];
    int startHour = slot.startHour;
    int endHour = slot.endHour;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SlotEditDialog(
        initialStart: startHour,
        initialEnd: endHour,
        onChanged: (s, e) {
          startHour = s;
          endHour = e;
        },
      ),
    );

    if (result == true && mounted) {
      if (endHour <= startHour) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de fin debe ser mayor a la de inicio')),
        );
        return;
      }
      _updateSlot(dayIndex, slotIndex, TimeSlot(startHour: startHour, endHour: endHour));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(workerRepositoryProvider);
      final schedule = ScheduleModel(
        days: _days,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await repo.saveSchedule(widget.workerUid, schedule);
      ref.invalidate(workerScheduleProvider(widget.workerUid));

      if (!mounted) return;
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Horario guardado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Tienes cambios sin guardar. ¿Deseas descartarlos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final canLeave = await _onWillPop();
          if (canLeave && mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Mi Horario'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            onPressed: () async {
              if (_hasChanges) {
                final canLeave = await _onWillPop();
                if (canLeave && mounted) context.pop();
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Header informativo ──
            _Header(),

            // ── Lista de días ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  for (int day = 1; day <= 7; day++)
                    _DayCard(
                      day: day,
                      slots: _days[day] ?? [],
                      onAddSlot: () => _addSlot(day),
                      onRemoveSlot: (i) => _removeSlot(day, i),
                      onEditSlot: (i) => _editSlotDialog(day, i),
                    ).animate().slideY(
                          begin: 0.15,
                          duration: 400.ms,
                          delay: Duration(milliseconds: (day - 1) * 50),
                        ).fade(),
                  const SizedBox(height: 16),

                  // ── Notas ──
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    onChanged: (_) => _markChanged(),
                    decoration: InputDecoration(
                      labelText: 'Notas sobre tu disponibilidad (Opcional)',
                      hintText: 'Ej: En festivos trabajo hasta las 2pm',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ).animate().slideY(begin: 0.15, duration: 400.ms, delay: 380.ms).fade(),
                ],
              ),
            ),
          ],
        ),

        // ── FAB guardar ──
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _save,
                backgroundColor: AppColors.primary,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'Guardar horario',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ).animate().slideY(begin: 1, duration: 300.ms)
            : null,
      ),
    );
  }
}

// ─── Header informativo ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define tu disponibilidad',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toca + en cada día para agregar franjas horarias. Toca una franja para editarla.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2, duration: 400.ms).fade();
  }
}

// ─── Tarjeta de un día ────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.slots,
    required this.onAddSlot,
    required this.onRemoveSlot,
    required this.onEditSlot,
  });

  final int day;
  final List<TimeSlot> slots;
  final VoidCallback onAddSlot;
  final void Function(int index) onRemoveSlot;
  final void Function(int index) onEditSlot;

  bool get _isWeekend => day >= 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSlots = slots.isNotEmpty;
    final dayColor = _isWeekend ? AppColors.secondary : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSlots
              ? dayColor.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: hasSlots ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado del día ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasSlots
                        ? dayColor.withValues(alpha: 0.12)
                        : colorScheme.outline.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isWeekend ? Icons.weekend_rounded : Icons.work_rounded,
                    size: 18,
                    color: hasSlots ? dayColor : colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ScheduleModel.dayNames[day]!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: hasSlots ? null : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      if (!hasSlots)
                        Text(
                          'Sin disponibilidad',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      if (hasSlots)
                        Text(
                          '${slots.length} franja${slots.length > 1 ? 's' : ''} configurada${slots.length > 1 ? 's' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: dayColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Botón agregar franja
                if (slots.length < 3)
                  IconButton(
                    icon: Icon(Icons.add_circle_rounded, color: dayColor, size: 28),
                    onPressed: onAddSlot,
                    tooltip: 'Agregar franja',
                  ),
              ],
            ),
          ),

          // ── Lista de franjas horarias ──
          if (hasSlots) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  for (int i = 0; i < slots.length; i++)
                    _SlotTile(
                      slot: slots[i],
                      dayColor: dayColor,
                      onTap: () => onEditSlot(i),
                      onDelete: () => onRemoveSlot(i),
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Tile de una franja horaria ───────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.dayColor,
    required this.onTap,
    required this.onDelete,
  });

  final TimeSlot slot;
  final Color dayColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: dayColor.withValues(alpha: 0.06),
            border: Border.all(color: dayColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: dayColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${slot.startLabel}  →  ${slot.endLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dayColor,
                    fontSize: 14,
                  ),
                ),
              ),
              // Duración
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dayColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${slot.endHour - slot.startHour}h',
                  style: TextStyle(
                    fontSize: 11,
                    color: dayColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error.withValues(alpha: 0.7),
                onPressed: onDelete,
                tooltip: 'Eliminar franja',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo de edición de franja ────────────────────────────────────────────

class _SlotEditDialog extends StatefulWidget {
  const _SlotEditDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.onChanged,
  });

  final int initialStart;
  final int initialEnd;
  final void Function(int start, int end) onChanged;

  @override
  State<_SlotEditDialog> createState() => _SlotEditDialogState();
}

class _SlotEditDialogState extends State<_SlotEditDialog> {
  late int _start;
  late int _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Editar franja horaria'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hora inicio
          _HourSelector(
            label: 'Hora de inicio',
            value: _start,
            min: 0,
            max: 22,
            onChanged: (v) {
              setState(() {
                _start = v;
                if (_end <= _start) _end = _start + 1;
              });
              widget.onChanged(_start, _end);
            },
          ),
          const SizedBox(height: 20),
          // Hora fin
          _HourSelector(
            label: 'Hora de fin',
            value: _end,
            min: _start + 1,
            max: 24,
            onChanged: (v) {
              setState(() => _end = v);
              widget.onChanged(_start, _end);
            },
          ),
          const SizedBox(height: 16),
          // Resumen visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_fmtHour(_start)}  →  ${_fmtHour(_end)}  (${_end - _start}h)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ─── Selector de hora con +/- ─────────────────────────────────────────────────

class _HourSelector extends StatelessWidget {
  const _HourSelector({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  String _fmt(int h) => _fmtHour(h);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: value > min ? () => onChanged(value - 1) : null,
              color: AppColors.primary,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _fmt(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: value < max ? () => onChanged(value + 1) : null,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
