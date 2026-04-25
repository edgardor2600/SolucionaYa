/// Helpers para cálculos y formateo de fechas específicos del dominio.
abstract final class DateHelpers {
  // ── Rangos de tiempo ──────────────────────────────────────────

  /// Retorna true si la fecha dada fue hoy.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Retorna true si la fecha dada fue ayer.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Retorna true si la fecha está en la semana actual.
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  // ── Horarios de trabajadores ──────────────────────────────────

  /// Nombre en español del día de la semana (1=Lunes, 7=Domingo).
  static String weekdayName(int weekday) {
    const names = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };
    return names[weekday] ?? '';
  }

  /// Nombre corto del día (3 letras).
  static String weekdayShort(int weekday) {
    const names = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };
    return names[weekday] ?? '';
  }

  /// Genera un resumen del horario para mostrar en el perfil.
  /// Ejemplo: "Lun–Vie 7am–6pm · Sáb 8am–2pm"
  static String scheduleToString(Map<String, dynamic>? schedule) {
    if (schedule == null || schedule.isEmpty) return 'Horario no configurado';
    final buffer = StringBuffer();
    // Ordenar por día de la semana
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayLabels = {
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mié',
      'thursday': 'Jue',
      'friday': 'Vie',
      'saturday': 'Sáb',
      'sunday': 'Dom',
    };
    for (final day in days) {
      final slot = schedule[day] as Map<String, dynamic>?;
      if (slot != null && slot['enabled'] == true) {
        if (buffer.isNotEmpty) buffer.write(' · ');
        buffer.write(
          '${dayLabels[day]} ${slot['start']}–${slot['end']}',
        );
      }
    }
    return buffer.isEmpty ? 'Sin horario definido' : buffer.toString();
  }

  /// Verifica si el trabajador está en horario en este momento.
  static bool isCurrentlyInSchedule(Map<String, dynamic>? schedule) {
    if (schedule == null || schedule.isEmpty) return true;

    final now = DateTime.now();
    final dayKey = _weekdayKey(now.weekday);
    final slot = schedule[dayKey] as Map<String, dynamic>?;
    if (slot == null || slot['enabled'] != true) return false;

    final start = _parseTime(slot['start'] as String?);
    final end = _parseTime(slot['end'] as String?);
    if (start == null || end == null) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= start && currentMinutes <= end;
  }

  // ── Helpers internos ──────────────────────────────────────────

  static String _weekdayKey(int weekday) {
    const keys = {
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };
    return keys[weekday] ?? '';
  }

  /// Convierte "07:30" → 450 (minutos desde medianoche).
  static int? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
