import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _historyKey = 'search_history';

  @override
  List<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addSearch(String query) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final currentList = List<String>.from(state);
    
    // Eliminar si ya existe para reposicionarlo al principio (evitar duplicados)
    currentList.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());
    
    // Insertar al principio
    currentList.insert(0, cleanQuery);

    // Limitar a los últimos 50 elementos
    if (currentList.length > 50) {
      currentList.removeRange(50, currentList.length);
    }

    await prefs.setStringList(_historyKey, currentList);
    state = currentList;
  }

  Future<void> removeSearch(String query) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final currentList = List<String>.from(state);
    
    currentList.removeWhere((item) => item.toLowerCase() == query.trim().toLowerCase());

    await prefs.setStringList(_historyKey, currentList);
    state = currentList;
  }

  Future<void> clearHistory() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_historyKey);
    state = [];
  }
}

final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(() {
  return SearchHistoryNotifier();
});
