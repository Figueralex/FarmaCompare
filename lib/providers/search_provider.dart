import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'settings_provider.dart';

// Proveedor del repositorio
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final enabledMap = ref.watch(pharmacySettingsProvider);
  final enabledPharmacies = enabledMap.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  return ProductRepository(enabledPharmacies);
});

// Estado de la búsqueda
abstract class SearchState {}

// ... Rest of states remain the same ...
class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Product> products;
  final bool isSearchingBackground;
  SearchLoaded(this.products, {this.isSearchingBackground = false});
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

// Notifier para manejar la lógica de búsqueda con debouncer
class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return SearchInitial();
  }

  void _logSearch(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return;

    Supabase.instance.client.from('search_logs').insert({
      'query': cleanQuery,
    }).then((_) {
      print("📈 Búsqueda registrada en Supabase: $cleanQuery");
    }).catchError((e) {
      print("⚠️ Error registrando búsqueda en Supabase: $e");
    });
  }

  void search(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.trim().isEmpty) {
      state = SearchInitial();
      return;
    }

    // Debouncer de 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = SearchLoading();
      
      // Registrar búsqueda en analíticas de Supabase
      _logSearch(query);

      try {
        final repository = ref.read(productRepositoryProvider);
        final results = await repository.searchProducts(
          query,
          onSecondPhaseComplete: () async {
            if (state is SearchLoaded) {
              try {
                final updatedResults = await repository.getCurrentDbResults(query);
                if (state is SearchLoaded) {
                  state = SearchLoaded(updatedResults, isSearchingBackground: false);
                }
              } catch (e) {
                print("⚠️ Error actualizando resultados de Farmapaz en segundo plano: $e");
              }
            }
          },
        );
        final isSearchingBg = repository.shouldRunFarmapazBackground(results);
        state = SearchLoaded(results, isSearchingBackground: isSearchingBg);
      } catch (e) {
        state = SearchError('Error al realizar la búsqueda');
      }
    });
  }
}

// Proveedor del SearchNotifier
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});

