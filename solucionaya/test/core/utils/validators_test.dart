import 'package:flutter_test/flutter_test.dart';
import 'package:solucionaya/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    test('valida correos correctos e incorrectos', () {
      expect(AppValidators.email('ana@test.com'), isNull);
      expect(AppValidators.email('correo-invalido'), isNotNull);
    });

    test('valida contraseña mínima', () {
      expect(AppValidators.password('12345678'), isNull);
      expect(AppValidators.password('1234'), isNotNull);
    });

    test('valida celular colombiano de 10 dígitos', () {
      expect(AppValidators.phone('3001234567'), isNull);
      expect(AppValidators.phone('2001234567'), isNotNull);
      expect(AppValidators.phone('3001234'), isNotNull);
    });

    test('valida nombre completo', () {
      expect(AppValidators.fullName('Ana Gomez'), isNull);
      expect(AppValidators.fullName('Ana'), isNotNull);
    });

    test('valida OTP de 6 dígitos', () {
      expect(AppValidators.otp('123456'), isNull);
      expect(AppValidators.otp('12ab'), isNotNull);
    });
  });
}
