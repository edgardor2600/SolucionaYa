import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor principal de SharedPreferences.
/// Debe ser sobreescrito en el ProviderScope principal (en main.dart)
/// después de llamar a SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider no ha sido inicializado');
});

/// Proveedor que indica si el usuario ya vio el onboarding.
final onboardingSeenProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('hasSeenOnboarding') ?? false;
});

/// Extensión para facilitar la actualización del estado de onboarding.
extension OnboardingSeenExtension on StateController<bool> {
  Future<void> setSeen(SharedPreferences prefs) async {
    state = true;
    await prefs.setBool('hasSeenOnboarding', true);
  }
}
