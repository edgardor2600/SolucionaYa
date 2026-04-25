/// Validadores reutilizables para formularios de la app.
/// Cada función retorna `null` si es válido, o un [String] con el error.
abstract final class AppValidators {
  // ── Email ─────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio.';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido (ej: nombre@dominio.com).';
    }
    return null;
  }

  // ── Contraseña ────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final base = password(value);
    if (base != null) return base;
    if (value != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // ── Teléfono colombiano ───────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de teléfono es obligatorio.';
    }
    // Acepta 10 dígitos (sin el +57)
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Ingresa 10 dígitos sin el código de país.';
    }
    if (!digits.startsWith('3')) {
      return 'El número debe empezar con 3 (celular colombiano).';
    }
    return null;
  }

  // ── Nombre ────────────────────────────────────────────────────
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    if (!value.trim().contains(' ')) {
      return 'Ingresa tu nombre completo (nombre y apellido).';
    }
    return null;
  }

  // ── Bio / descripción ─────────────────────────────────────────
  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción es obligatoria.';
    }
    if (value.trim().length < 20) {
      return 'Escribe al menos 20 caracteres para describir tu trabajo.';
    }
    if (value.length > 300) {
      return 'Máximo 300 caracteres.';
    }
    return null;
  }

  // ── OTP (6 dígitos) ───────────────────────────────────────────
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el código.';
    }
    if (value.trim().length != 6) {
      return 'El código tiene 6 dígitos.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'El código solo contiene números.';
    }
    return null;
  }

  // ── Precio ────────────────────────────────────────────────────
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio.';
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(digits);
    if (amount == null || amount <= 0) {
      return 'Ingresa un precio válido mayor a 0.';
    }
    if (amount > 100000000) {
      return 'El precio parece demasiado alto.';
    }
    return null;
  }

  // ── Campo requerido genérico ──────────────────────────────────
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    return null;
  }

  // ── WhatsApp ──────────────────────────────────────────────────
  static String? whatsapp(String? value) {
    // Es opcional, pero si se ingresa debe ser válido
    if (value == null || value.trim().isEmpty) return null;
    return phone(value);
  }
}
