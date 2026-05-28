import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../services/scraper_service.dart';
import '../core/medication_synonyms.dart';

class ProductRepository {
  final List<String> activePharmacies;

  ProductRepository(this.activePharmacies);

  Future<List<Product>> searchProducts(
    String query, {
    Function()? onSecondPhaseComplete,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final q = query.trim();
      final scraperQuery = MedicationSynonyms.getScraperTerm(q);
      final terms = MedicationSynonyms.expandQuery(q);

      // 1. Buscar primero en la base de datos usando los términos expandidos
      print("🔍 Buscando en la base de datos para: $terms con farmacias habilitadas: $activePharmacies");
      final dbResults = await _queryDatabase(terms, activePharmacies);

      // Determinar qué farmacias tienen registros RECIENTES (menos de 72 horas)
      final now = DateTime.now();
      
      bool hasRecentProduct(String pharmacy) {
        final pharmacyProducts = dbResults.where((p) => p.pharmacyName == pharmacy).toList();
        if (pharmacyProducts.isEmpty) return false;
        
        // Si hay algún producto que tiene createdAt:
        // Verificamos que tenga menos de 72 horas para mejorar el rendimiento del usuario.
        return pharmacyProducts.any((p) {
          if (p.createdAt == null) return false;
          
          // Si han pasado 72 horas o más, ya no es reciente
          if (now.difference(p.createdAt!).inHours >= 72) return false;
          
          return true;
        });
      }

      final hasFarmadon = hasRecentProduct('Farmadon');
      final hasFarmatodo = hasRecentProduct('Farmatodo');
      final hasFarmatina = hasRecentProduct('Farmatina');
      final hasFarmapaz = hasRecentProduct('Farmapaz');

      final List<Future<void>> fastScrapersToRun = [];

      if (activePharmacies.contains('Farmadon') && !hasFarmadon) {
        print("🤖 [Farmadon] No hay registros recientes en DB. Agregando scraper de Farmadon con: $scraperQuery.");
        fastScrapersToRun.add(ScraperService().scrapeFarmadon(scraperQuery));
      } else {
        print("⚡ [Farmadon] Registros ya existentes y recientes en la DB o deshabilitado.");
      }

      if (activePharmacies.contains('Farmatodo') && !hasFarmatodo) {
        print("🤖 [Farmatodo] No hay registros recientes en DB. Agregando scraper de Farmatodo con: $scraperQuery.");
        fastScrapersToRun.add(ScraperService().scrapeFarmatodo(scraperQuery));
      } else {
        print("⚡ [Farmatodo] Registros ya existentes y recientes en la DB o deshabilitado.");
      }

      if (activePharmacies.contains('Farmatina') && !hasFarmatina) {
        print("🤖 [Farmatina] No hay registros recientes en DB. Agregando scraper de Farmatina con: $scraperQuery.");
        fastScrapersToRun.add(ScraperService().scrapeFarmatina(scraperQuery));
      } else {
        print("⚡ [Farmatina] Registros ya existentes y recientes en la DB o deshabilitado.");
      }

      // Si falta alguna farmacia rápida por buscar, ejecutamos los scrapers rápidos en paralelo
      if (fastScrapersToRun.isNotEmpty) {
        print("⚡ Ejecutando scrapers rápidos en paralelo...");
        try {
          await Future.wait(fastScrapersToRun);
        } catch (scraperError) {
          print("⚠️ Error en el scraping rápido paralelo: $scraperError");
        }
      }

      // 2. Ejecutar el scraper lento (Farmapaz) en segundo plano si está activo y no tiene registros
      if (activePharmacies.contains('Farmapaz') && !hasFarmapaz) {
        print("🤖 [Farmapaz] No hay registros recientes en DB. Iniciando scraper de Farmapaz en segundo plano con: $scraperQuery...");
        ScraperService().scrapeFarmapaz(scraperQuery).then((_) {
          print("⚡ [Farmapaz] Scraper de segundo plano completado.");
          onSecondPhaseComplete?.call();
        }).catchError((err) {
          print("⚠️ [Farmapaz] Error en scraper de segundo plano: $err");
        });
      } else {
        print("⚡ [Farmapaz] Registros ya existentes y recientes en la DB o deshabilitado.");
      }

      // Retornar los resultados actuales de la DB (que ya incluyen lo nuevo de las farmacias rápidas)
      return await _queryDatabase(terms, activePharmacies);
    } catch (e) {
      print("❌ Error en searchProducts: $e");
      return [];
    }
  }

  bool shouldRunFarmapazBackground(List<Product> currentDbResults) {
    final hasFarmapaz = currentDbResults.any((p) => p.pharmacyName == 'Farmapaz');
    return activePharmacies.contains('Farmapaz') && !hasFarmapaz;
  }

  // Método público para volver a consultar la DB después de la fase 2
  Future<List<Product>> getCurrentDbResults(String query) async {
    final terms = MedicationSynonyms.expandQuery(query);
    return _queryDatabase(terms, activePharmacies);
  }

  Future<List<Product>> _queryDatabase(List<String> terms, List<String> activePharmacies) async {
    try {
      final pharmacyList = activePharmacies.map((p) => '"$p"').join(',');
      
      // Construir el filtro OR para Supabase
      final orConditions = <String>[];
      for (final t in terms) {
        orConditions.add('name.ilike.%$t%');
        orConditions.add('active_ingredient.ilike.%$t%');
      }
      final orString = orConditions.join(',');

      final response = await Supabase.instance.client
          .from('products')
          .select()
          .filter('pharmacy_name', 'in', '($pharmacyList)')
          .or(orString)
          .order('price_usd', ascending: true);

      final data = response as List<dynamic>;

      // Eliminar duplicados basados en nombre + farmacia
      final seenKeys = <String>{};
      final uniqueData = <dynamic>[];
      for (var item in data) {
        final key = '${item['name']}_${item['pharmacy_name']}';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          uniqueData.add(item);
        }
      }

      return uniqueData
          .map((json) => Product.fromJson(json))
          .where((prod) => prod.price > 0 && !prod.name.toLowerCase().contains('propina'))
          .toList();
    } catch (e) {
      print("❌ Error al consultar Supabase: $e");
      return [];
    }
  }
}
