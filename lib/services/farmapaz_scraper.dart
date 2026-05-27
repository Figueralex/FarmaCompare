import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/bcv_repository.dart';

class FarmapazScraper {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'es-VE,es;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'no-cache',
    },
  ));

  double _bcvRate = 0.0;

  Future<void> _ensureBcvRate() async {
    if (_bcvRate <= 0.0) {
      try {
        _bcvRate = await BcvRepository().getOfficialRate();
        print("💱 [Farmapaz] Tasa BCV cargada: $_bcvRate Bs./USD");
      } catch (e) {
        print("⚠️ [Farmapaz] No se pudo obtener tasa BCV: $e");
        _bcvRate = 0.0;
      }
    }
  }

  Future<void> scrape(String query) async {
    try {
      print("🟢 [Farmapaz] Buscando: $query");
      await _ensureBcvRate();
      final searchUrl =
          'https://farmapazvenezuela.com/?s=${Uri.encodeComponent(query)}&post_type=product&wmc-currency=USD';
      
      final searchResp = await _dio.get(searchUrl);

      if (searchResp.statusCode != 200) {
        print("⚠️ [Farmapaz] Búsqueda HTTP ${searchResp.statusCode}");
        return;
      }

      final html = searchResp.data.toString();
      
      // Encontrar todas las ocurrencias de '<div class="post-image post-media overlay-hover">'
      final List<int> indexes = [];
      var index = 0;
      while (true) {
        index = html.indexOf('<div class="post-image post-media overlay-hover">', index);
        if (index == -1) break;
        indexes.add(index);
        index += 48; // longitud de la cadena buscada
      }

      print("🟢 [Farmapaz] Encontrados ${indexes.length} bloques de productos.");

      final List<String> productBlocks = [];
      for (int i = 0; i < indexes.length; i++) {
        final start = indexes[i];
        final end = (i < indexes.length - 1) ? indexes[i + 1] : start + 4000;
        final block = html.substring(start, end < html.length ? end : html.length);
        productBlocks.add(block);
      }

      int successCount = 0;
      for (final block in productBlocks) {
        try {
          // 1. URL del producto: href="https://farmapazvenezuela.com/product/..."
          final urlMatch = RegExp(
            r'href="(https://farmapazvenezuela\.com/product/[^"]+)"',
            caseSensitive: false,
          ).firstMatch(block);
          if (urlMatch == null) continue;
          final productUrl = urlMatch.group(1)!;

          // 2. URL de la imagen: src="..." dentro del block
          final imgMatch = RegExp(
            r'<img[^>]*src="([^"]+)"',
            caseSensitive: false,
          ).firstMatch(block);
          final imageUrl = imgMatch != null ? imgMatch.group(1)! : '';

          // 3. Nombre: <h4 class="post-title..."><a...>(.*?)</a></h4>
          final nameMatch = RegExp(
            r'<h4 class="post-title[^"]*"><a[^>]*>(.*?)</a></h4>',
            caseSensitive: false,
            dotAll: true,
          ).firstMatch(block);
          if (nameMatch == null) continue;
          final name = _decodeHtmlEntities(_stripHtml(nameMatch.group(1)!)).trim();

          // 4. Precio USD
          double priceUsd = 0.0;
          double? originalPriceUsd;

          // Si hay etiqueta <ins> (precio con descuento) y <del> (precio original)
          final insMatch = RegExp(r'<ins[^>]*>([\s\S]*?)</ins>', caseSensitive: false).firstMatch(block);
          final delMatch = RegExp(r'<del[^>]*>([\s\S]*?)</del>', caseSensitive: false).firstMatch(block);

          if (insMatch != null) {
            priceUsd = _extractPriceFromHtml(insMatch.group(1)!, _bcvRate);
            if (delMatch != null) {
              originalPriceUsd = _extractPriceFromHtml(delMatch.group(1)!, _bcvRate);
            }
          } else {
            // Estrategia A: data-wmc_price_cache
            final cacheMatch = RegExp(
              r'data-wmc_price_cache="([^"]+)"',
              caseSensitive: false,
            ).firstMatch(block);
            if (cacheMatch != null) {
              final rawCache = _decodeHtmlEntities(cacheMatch.group(1)!);
              try {
                final cache = jsonDecode(rawCache) as Map<String, dynamic>;
                if (cache['USD'] != null) {
                  priceUsd = _extractPriceFromHtml(cache['USD'].toString(), _bcvRate);
                } else if (cache['VES'] != null && _bcvRate > 0.0) {
                  final vesPrice = _extractPriceFromHtml(cache['VES'].toString(), _bcvRate);
                  if (vesPrice > 0.0) {
                    priceUsd = vesPrice;
                    print("💱 [Farmapaz Cache] Convertido VES → USD ${priceUsd.toStringAsFixed(2)} usando BCV $_bcvRate");
                  }
                }
              } catch (e) {
                // Fallback regex para la cache si jsonDecode falla
                final usdFieldMatch = RegExp(r'"USD"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(rawCache);
                if (usdFieldMatch != null) {
                  final usdHtml = usdFieldMatch.group(1)!.replaceAll(r'\"', '"');
                  priceUsd = _extractPriceFromHtml(usdHtml, _bcvRate);
                } else {
                  final vesFieldMatch = RegExp(r'"VES"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(rawCache);
                  if (vesFieldMatch != null && _bcvRate > 0.0) {
                    final vesHtml = vesFieldMatch.group(1)!.replaceAll(r'\"', '"');
                    final vesPrice = _extractPriceFromHtml(vesHtml, _bcvRate);
                    if (vesPrice > 0.0) {
                      priceUsd = vesPrice;
                      print("💱 [Farmapaz Cache Fallback] Convertido VES → USD ${priceUsd.toStringAsFixed(2)} usando BCV $_bcvRate");
                    }
                  }
                }
              }
            }

            // Estrategia B: Fallback a woocommerce-Price-amount
            if (priceUsd <= 0.0) {
              priceUsd = _extractPriceFromHtml(block, _bcvRate);
              if (priceUsd > 0.0) {
                print("💱 [Farmapaz Span Fallback] Obtenido USD: ${priceUsd.toStringAsFixed(2)}");
              }
            }
          }

          if (priceUsd <= 0.0) {
            print("⚠️ [Farmapaz] Sin precio para: $name");
            continue;
          }

          final presentationText = originalPriceUsd != null && originalPriceUsd > priceUsd
              ? 'Farmapaz Web || original_price:${originalPriceUsd.toStringAsFixed(2)}'
              : 'Farmapaz Web';

          final prod = {
            'name': name,
            'active_ingredient': query,
            'presentation': presentationText,
            'price_usd': double.parse(priceUsd.toStringAsFixed(2)),
            'pharmacy_name': 'Farmapaz',
            'image_url': imageUrl,
            'product_url': productUrl,
          };

          await _upsertProduct(prod);
          successCount++;
        } catch (cardErr) {
          print("⚠️ [Farmapaz] Error parseando tarjeta de producto: $cardErr");
        }
      }

      print("✅ [Farmapaz] Completado para: $query. Guardados/Actualizados $successCount productos.");
    } on DioException catch (e) {
      print("❌ [Farmapaz] Error de red: ${e.message}");
    } catch (e) {
      print("❌ [Farmapaz] Error inesperado: $e");
    }
  }

  Future<void> _upsertProduct(Map<String, dynamic> prod) async {
    try {
      final existing = await Supabase.instance.client
          .from('products')
          .select('id')
          .eq('name', prod['name'])
          .eq('pharmacy_name', prod['pharmacy_name'])
          .limit(1);

      if (existing.isEmpty) {
        await Supabase.instance.client.from('products').insert(prod);
        print("✅ [Farmapaz] Guardado: ${prod['name']} — USD ${prod['price_usd']}");
      } else {
        await Supabase.instance.client
            .from('products')
            .update({
              'price_usd': prod['price_usd'],
              'image_url': prod['image_url'],
              'product_url': prod['product_url'],
              'active_ingredient': prod['active_ingredient'],
              'presentation': prod['presentation'],
              'created_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', existing.first['id']);
        print("🔄 [Farmapaz] Actualizado: ${prod['name']} — USD ${prod['price_usd']}");
      }
    } catch (e) {
      print("❌ [Farmapaz] Error Supabase: $e");
    }
  }

  double _extractPriceFromHtml(String html, double bcvRate) {
    // Si hay una etiqueta <ins>, nos quedamos con su contenido (precio con descuento en WooCommerce)
    final insMatch = RegExp(r'<ins[^>]*>([\s\S]*?)</ins>', caseSensitive: false).firstMatch(html);
    final targetHtml = insMatch != null ? insMatch.group(1)! : html;
    
    // Buscar el span del precio en el HTML objetivo
    final priceSpanMatch = RegExp(
      r'class="woocommerce-Price-amount amount">[\s\S]*?<bdi>([\s\S]*?)</bdi>',
      caseSensitive: false,
    ).firstMatch(targetHtml);
    
    if (priceSpanMatch != null) {
      final fullSpan = priceSpanMatch.group(0)!;
      final priceText = _decodeHtmlEntities(_stripHtml(priceSpanMatch.group(1)!));
      final rawVal = _parseEuropeanPrice(priceText);
      if (rawVal > 0.0) {
        // Verificar si la moneda es Bolívares (VES)
        if (fullSpan.contains('Bs') || priceText.contains('Bs') || fullSpan.contains('Bs.')) {
          if (bcvRate > 0.0) {
            return rawVal / bcvRate;
          }
          return 0.0;
        } else {
          return rawVal;
        }
      }
    }
    
    // Si no encuentra el span estructurado con <bdi>, intentamos parsear directamente del targetHtml limpio
    final cleanText = _decodeHtmlEntities(_stripHtml(targetHtml));
    final rawVal = _parseEuropeanPrice(cleanText);
    if (rawVal > 0.0) {
      if (targetHtml.contains('Bs') || cleanText.contains('Bs')) {
        if (bcvRate > 0.0) {
          return rawVal / bcvRate;
        }
        return 0.0;
      }
      return rawVal;
    }
    
    return 0.0;
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  String _decodeHtmlEntities(String text) {
    var prev = text;
    var decoded = _decodeHtmlEntitiesOnce(text);
    int iterations = 0;
    while (decoded != prev && iterations < 5) {
      prev = decoded;
      decoded = _decodeHtmlEntitiesOnce(decoded);
      iterations++;
    }
    return decoded;
  }

  String _decodeHtmlEntitiesOnce(String text) {
    var decoded = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#38;', '&')
        .replaceAll('&#36;', '\$')
        .replaceAll('&#038;', '&');

    decoded = decoded.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    });

    decoded = decoded.replaceAllMapped(RegExp(r'&#x([a-fA-F\d]+);'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return decoded;
  }

  double _parseEuropeanPrice(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d.,]'), '');
    if (cleaned.isEmpty) return 0.0;
    if (cleaned.contains(',')) {
      final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }
    final dotCount = cleaned.split('.').length - 1;
    if (dotCount == 1) {
      final parts = cleaned.split('.');
      if (parts.last.length <= 2) {
        return double.tryParse(cleaned) ?? 0.0;
      }
      return double.tryParse(cleaned.replaceAll('.', '')) ?? 0.0;
    }
    if (dotCount > 1) {
      return double.tryParse(cleaned.replaceAll('.', '')) ?? 0.0;
    }
    return double.tryParse(cleaned) ?? 0.0;
  }
}
