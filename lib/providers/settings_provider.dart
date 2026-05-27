import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('El sharedPreferencesProvider debe ser sobreescrito en el ProviderScope');
});

class PharmacySettingsNotifier extends Notifier<Map<String, bool>> {
  static const _keyPrefix = 'pharmacy_enabled_';

  @override
  Map<String, bool> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return {
      'Farmatodo': prefs.getBool('${_keyPrefix}Farmatodo') ?? true,
      'Farmadon': prefs.getBool('${_keyPrefix}Farmadon') ?? true,
      'Farmatina': prefs.getBool('${_keyPrefix}Farmatina') ?? true,
      'Farmapaz': prefs.getBool('${_keyPrefix}Farmapaz') ?? true,
    };
  }

  Future<void> togglePharmacy(String name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final currentValue = state[name] ?? true;
    final newValue = !currentValue;

    // Al menos una farmacia debe permanecer activa
    final enabledCount = state.values.where((v) => v).length;
    if (currentValue && enabledCount <= 1) {
      return;
    }

    await prefs.setBool('$_keyPrefix$name', newValue);
    state = {
      ...state,
      name: newValue,
    };
  }
}

final pharmacySettingsProvider = NotifierProvider<PharmacySettingsNotifier, Map<String, bool>>(() {
  return PharmacySettingsNotifier();
});
