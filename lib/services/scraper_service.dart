import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/bcv_repository.dart';
import 'farmapaz_scraper.dart';

class ScraperService {
  static final ScraperService _instance = ScraperService._internal();
  factory ScraperService() => _instance;
  ScraperService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'es-VE,es;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'no-cache',
    },
  ));

  // Tasa BCV cacheada para no pedir en cada producto
  double _bcvRate = 0.0;

  Future<void> _ensureBcvRate() async {
    if (_bcvRate <= 0.0) {
      try {
        _bcvRate = await BcvRepository().getOfficialRate();
        print("💱 Tasa BCV cargada: $_bcvRate Bs./USD");
      } catch (e) {
        print("⚠️ No se pudo obtener tasa BCV: $e");
        _bcvRate = 0.0;
      }
    }
  }

  /// Ejecuta todos los scrapers activos en paralelo
  Future<void> runDistributedScrapers(String query) async {
    print("🤖 Iniciando scrapers para: $query");
    await _ensureBcvRate();
    await Future.wait([
      scrapeFarmadon(query),
      scrapeFarmatodo(query),
      scrapeFarmatina(query),
    ]);
  }

  /// Ejecuta el scraper de Farmadon de forma independiente
  Future<void> scrapeFarmadon(String query) async {
    await _ensureBcvRate();
    await _scrapeFarmadon(query);
  }

  /// Ejecuta el scraper de Farmatodo de forma independiente
  Future<void> scrapeFarmatodo(String query) async {
    await _ensureBcvRate();
    await _scrapeFarmatodo(query);
  }

  /// Ejecuta el scraper de Farmatina de forma independiente
  Future<void> scrapeFarmatina(String query) async {
    await _ensureBcvRate();
    await _scrapeFarmatina(query);
  }

  /// Ejecuta el scraper de Farmapaz de forma independiente
  Future<void> scrapeFarmapaz(String query) async {
    await FarmapazScraper().scrape(query);
  }

  // ─── FARMADON (HTML scraping via Dio) ───────────────────────────────────────
  //
  // Farmadon es WooCommerce con WMC (WooCommerce Multi-Currency).
  //
  // FLUJO CORREGIDO:
  //  1. GET /?s=<query>&post_type=product → HTML con links /producto/<slug>/
  //  2. Por cada slug: GET /producto/<slug>/ → parsear precio desde:
  //     a) data-wmc_price_cache (doblemente encoded con &quot; y HTML escapado)
  //     b) FALLBACK: product:price:amount (meta OG) + conversión BCV
  //     c) FALLBACK: woocommerce-Price-amount span (precio en VES como texto)

  Future<void> _scrapeFarmadon(String query) async {
    try {
      print("🟢 [Farmadon] Buscando: $query");

      // Paso 1: Obtener lista de productos desde la página de búsqueda HTML
      final searchUrl =
          'https://www.farmadon.com.ve/?s=${Uri.encodeComponent(query)}&post_type=product';
      final searchResp = await _dio.get(searchUrl);

      if (searchResp.statusCode != 200) {
        print("⚠️ [Farmadon] Búsqueda HTTP ${searchResp.statusCode}");
        return;
      }

      final html = searchResp.data.toString();

      // Extraer URLs de productos con regex en el HTML
      // Formato: href="https://www.farmadon.com.ve/producto/SLUG/"
      final urlRegex = RegExp(
        r'href="(https://www\.farmadon\.com\.ve/producto/[^"]+)"',
        caseSensitive: false,
      );
      final productUrls = urlRegex
          .allMatches(html)
          .map((m) => m.group(1)!)
          .toSet() // deduplicar
          .take(15) // máximo 15 productos por búsqueda
          .toList();

      print("🟢 [Farmadon] ${productUrls.length} productos para procesar");

      if (productUrls.isEmpty) {
        print("⚠️ [Farmadon] Sin URLs de productos — posible bloqueo o sin resultados");
        return;
      }

      // Paso 2: Para cada producto, obtener su página individual y parsear precio
      for (final productUrl in productUrls) {
        try {
          await _processFarmadonProduct(productUrl, query);
          // Pequeño delay para no saturar el servidor
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print("⚠️ [Farmadon] Error procesando $productUrl: $e");
        }
      }

      print("✅ [Farmadon] Completado para: $query");
    } on DioException catch (e) {
      print("❌ [Farmadon] Error de red: ${e.message}");
    } catch (e) {
      print("❌ [Farmadon] Error inesperado: $e");
    }
  }

  Future<void> _processFarmadonProduct(String url, String query) async {
    final resp = await _dio.get(url);
    if (resp.statusCode != 200) return;

    final html = resp.data.toString();

    // ── Nombre ─────────────────────────────────────────────────────────────
    // <h1 class="product_title entry-title">NOMBRE</h1>
    String name = '';
    final nameMatch = RegExp(
      r'<h1[^>]*class="[^"]*product_title[^"]*"[^>]*>(.*?)</h1>',
      dotAll: true,
    ).firstMatch(html);
    if (nameMatch != null) {
      name = _stripHtml(nameMatch.group(1) ?? '').trim();
    }

    // Fallback: og:title
    if (name.isEmpty) {
      final ogTitle = RegExp(r'<meta property="og:title" content="([^"]+)"')
          .firstMatch(html);
      if (ogTitle != null) {
        name = _decodeHtmlEntities(ogTitle.group(1) ?? '').trim();
        // Quitar el sufijo " - Farmadon - La Farmacia de la Esquina"
        name = name.replaceAll(RegExp(r'\s*-\s*Farmadon.*$'), '').trim();
      }
    }

    if (name.isEmpty) {
      print("⚠️ [Farmadon] Sin nombre en: $url");
      return;
    }

    // ── Precio USD ──────────────────────────────────────────────────────────
    //
    // ESTRATEGIA 1: ins y del (descuento WooCommerce)
    // ESTRATEGIA 2: wmc_price_cache
    // ESTRATEGIA 3: product:price:amount
    // ESTRATEGIA 4: woocommerce-Price-amount
    //
    double price = 0.0;
    double? originalPrice;

    final insMatch = RegExp(r'<ins[^>]*>([\s\S]*?)</ins>', caseSensitive: false).firstMatch(html);
    final delMatch = RegExp(r'<del[^>]*>([\s\S]*?)</del>', caseSensitive: false).firstMatch(html);

    if (insMatch != null) {
      price = _extractFarmadonPriceFromBlock(insMatch.group(1)!);
      if (delMatch != null) {
        originalPrice = _extractFarmadonPriceFromBlock(delMatch.group(1)!);
      }
    }

    if (price <= 0.0) {
      // --- Estrategia 2: wmc_price_cache ---
      final cacheMatch = RegExp(r'data-wmc_price_cache="([^"]+)"').firstMatch(html);
      if (cacheMatch != null) {
        final level1 = _decodeHtmlEntities(cacheMatch.group(1) ?? '');
        final usdFieldMatch = RegExp(r'"USD"\s*:\s*"(.*?)"(?:,|\})').firstMatch(level1);
        if (usdFieldMatch != null) {
          final usdHtml = _decodeHtmlEntities(usdFieldMatch.group(1) ?? '');
          final usdText = _stripHtml(usdHtml);
          price = _parseEuropeanPrice(usdText);
        }
      }
    }

    if (price <= 0.0) {
      // --- Estrategia 3: product:price:amount (en VES) + conversión BCV ---
      final ogPriceMatch = RegExp(
        r'<meta property="product:price:amount" content="([^"]+)"'
      ).firstMatch(html);
      final ogCurrencyMatch = RegExp(
        r'<meta property="product:price:currency" content="([^"]+)"'
      ).firstMatch(html);

      if (ogPriceMatch != null) {
        final rawAmount = double.tryParse(ogPriceMatch.group(1) ?? '') ?? 0.0;
        final currency = ogCurrencyMatch?.group(1) ?? 'VES';

        if (currency == 'USD') {
          price = rawAmount;
        } else if (currency == 'VES' && rawAmount > 0 && _bcvRate > 0) {
          price = rawAmount / _bcvRate;
        }
      }
    }

    if (price <= 0.0) {
      // --- Estrategia 4: woocommerce-Price-amount span (VES como texto) ---
      final spanMatch = RegExp(
        r'class="woocommerce-Price-amount amount"><bdi>(.*?)</bdi>',
        dotAll: true,
      ).firstMatch(html);
      if (spanMatch != null) {
        final rawText = _stripHtml(spanMatch.group(1) ?? '');
        final vesPrice = _parseEuropeanPrice(rawText);
        if (vesPrice > 0 && _bcvRate > 0) {
          price = vesPrice / _bcvRate;
        }
      }
    }

    if (price <= 0.0) {
      print("⚠️ [Farmadon] Sin precio para: $name (URL: $url)");
      return;
    }

    // ── Imagen ──────────────────────────────────────────────────────────────
    String imgUrl = '';
    final ogImg = RegExp(r'<meta property="og:image" content="([^"]+)"').firstMatch(html);
    if (ogImg != null) imgUrl = ogImg.group(1) ?? '';

    final presentationText = originalPrice != null && originalPrice > price
        ? 'Farmadon Web || original_price:${originalPrice.toStringAsFixed(2)}'
        : 'Farmadon Web';

    final prod = {
      'name': name,
      'active_ingredient': query,
      'presentation': presentationText,
      'price_usd': double.parse(price.toStringAsFixed(2)),
      'pharmacy_name': 'Farmadon',
      'image_url': imgUrl,
      'product_url': url,
    };

    print("📦 [Farmadon] → $name | USD ${price.toStringAsFixed(2)}${originalPrice != null ? ' (Original: ${originalPrice.toStringAsFixed(2)})' : ''}");
    await _upsertProduct(prod);
  }

  // ─── FARMATINA (HTML scraping via Dio) ─────────────────────────────────────
  //
  // Farmatina es un sitio web basado en Odoo. Su listado de productos se
  // renderiza en el servidor en la ruta /shop?search=<query>.
  //
  // FLUJO:
  //  1. GET /shop?search=<query> → HTML completo
  //  2. Extraer bloques de tarjetas de productos usando la clase zenith-product-card.
  //  3. Parsear cada bloque:
  //     - Nombre: del tag a con itemprop="name"
  //     - Enlace: href del tag a con itemprop="name" (resuelto a absoluto con https://farmatina.com)
  //     - Imagen: src del tag img (resuelto a absoluto con https://farmatina.com)
  //     - Precio: limpiar los tags <del>...</del> del bloque (que contienen el precio tachado),
  //               luego extraer el valor de la clase .oe_currency_value, parsearlo como precio europeo,
  //               y dividirlo por la tasa del BCV para guardarlo en USD.

  Future<void> _scrapeFarmatina(String query) async {
    try {
      print("🟢 [Farmatina] Buscando: $query");

      final searchUrl = 'https://farmatina.com/shop?search=${Uri.encodeComponent(query)}';
      final searchResp = await _dio.get(searchUrl);

      if (searchResp.statusCode != 200) {
        print("⚠️ [Farmatina] Búsqueda HTTP ${searchResp.statusCode}");
        return;
      }

      final html = searchResp.data.toString();

      // Encontrar bloques de productos (formularios con clase zenith-product-card)
      final productFormRegex = RegExp(
        r'<form[^>]*class="[^"]*zenith-product-card[^"]*"[^>]*>(.*?)</form>',
        dotAll: true,
      );

      final matches = productFormRegex.allMatches(html).toList();
      print("🟢 [Farmatina] ${matches.length} productos encontrados en HTML");

      if (matches.isEmpty) {
        print("⚠️ [Farmatina] Sin productos en el HTML de resultados");
        return;
      }

      for (final match in matches) {
        try {
          final formHtml = match.group(1) ?? '';

          // 1. Nombre
          final nameMatch = RegExp(
            r'itemprop="name"[^>]*>\s*(.*?)\s*</a>',
            dotAll: true,
          ).firstMatch(formHtml);
          if (nameMatch == null) continue;
          final name = _decodeHtmlEntities(nameMatch.group(1) ?? '').trim();
          if (name.isEmpty) continue;

          // 2. Enlace de producto
          final linkMatch = RegExp(r'href="([^"]+)"[^>]*itemprop="name"').firstMatch(formHtml) ??
              RegExp(r'itemprop="url"\s+href="([^"]+)"').firstMatch(formHtml);
          if (linkMatch == null) continue;
          var productUrl = linkMatch.group(1)!.trim();
          if (!productUrl.startsWith('http')) {
            productUrl = 'https://farmatina.com$productUrl';
          }

          // 3. Imagen del producto
          final imgMatch = RegExp(r'<img[^>]*class="[^"]*img[^"]*"[^>]*src="([^"]+)"').firstMatch(formHtml) ??
              RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(formHtml);
          var imgUrl = '';
          if (imgMatch != null) {
            imgUrl = imgMatch.group(1)!.trim();
            if (!imgUrl.startsWith('http')) {
              imgUrl = 'https://farmatina.com$imgUrl';
            }
          }

          // 4. Precio (VES a USD)
          double priceVes = 0.0;
          double? originalPriceVes;

          // Original price (if it exists in <del>)
          final delMatch = RegExp(r'<del[^>]*>([\s\S]*?)</del>', dotAll: true).firstMatch(formHtml);
          if (delMatch != null) {
            final delHtml = delMatch.group(1)!;
            final origPriceMatch = RegExp(r'class="oe_currency_value">([^<]*)</span>').firstMatch(delHtml);
            if (origPriceMatch != null) {
              originalPriceVes = _parseEuropeanPrice(origPriceMatch.group(1) ?? '');
            }
          }

          // Final price (from cleaned HTML where <del> is removed)
          final cleanedFormHtml = formHtml.replaceAll(RegExp(r'<del[^>]*>.*?</del>', dotAll: true), '');
          final priceMatch = RegExp(r'class="oe_currency_value">([^<]*)</span>').firstMatch(cleanedFormHtml);
          if (priceMatch == null) {
            print("⚠️ [Farmatina] Sin precio para: $name");
            continue;
          }

          final priceVesStr = priceMatch.group(1) ?? '';
          priceVes = _parseEuropeanPrice(priceVesStr);

          if (priceVes <= 0.0) {
            print("⚠️ [Farmatina] Precio VES inválido ($priceVesStr) para: $name");
            continue;
          }

          if (_bcvRate <= 0.0) {
            print("⚠️ [Farmatina] Tasa BCV no disponible para: $name");
            continue;
          }

          final priceUsd = priceVes / _bcvRate;
          double? originalPriceUsd;
          if (originalPriceVes != null && originalPriceVes > priceVes) {
            originalPriceUsd = originalPriceVes / _bcvRate;
          }

          final presentationText = originalPriceUsd != null
              ? 'Farmatina Web || original_price:${originalPriceUsd.toStringAsFixed(2)}'
              : 'Farmatina Web';

          final prod = {
            'name': name,
            'active_ingredient': query,
            'presentation': presentationText,
            'price_usd': double.parse(priceUsd.toStringAsFixed(2)),
            'pharmacy_name': 'Farmatina',
            'image_url': imgUrl,
            'product_url': productUrl,
          };

          print("📦 [Farmatina] → $name | VES $priceVes → USD ${priceUsd.toStringAsFixed(2)}${originalPriceUsd != null ? ' (Original: ${originalPriceUsd.toStringAsFixed(2)})' : ''}");
          await _upsertProduct(prod);
        } catch (e) {
          print("⚠️ [Farmatina] Error procesando tarjeta de producto: $e");
        }
      }

      print("✅ [Farmatina] Completado para: $query");
    } on DioException catch (e) {
      print("❌ [Farmatina] Error de red: ${e.message}");
    } catch (e) {
      print("❌ [Farmatina] Error inesperado: $e");
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
        print("✅ Guardado: ${prod['name']} — USD ${prod['price_usd']}");
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
        print("🔄 Actualizado: ${prod['name']} — USD ${prod['price_usd']}");
      }
    } catch (e) {
      print("❌ Error Supabase: $e");
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  double _extractFarmadonPriceFromBlock(String blockHtml) {
    final spanMatch = RegExp(
      r'class="woocommerce-Price-amount amount"><bdi>(.*?)</bdi>',
      dotAll: true,
    ).firstMatch(blockHtml);
    
    if (spanMatch != null) {
      final fullSpan = spanMatch.group(0)!;
      final priceText = _decodeHtmlEntities(_stripHtml(spanMatch.group(1)!));
      final rawVal = _parseEuropeanPrice(priceText);
      if (rawVal > 0.0) {
        if (fullSpan.contains('Bs') || priceText.contains('Bs') || fullSpan.contains('Bs.')) {
          if (_bcvRate > 0.0) {
            return rawVal / _bcvRate;
          }
          return 0.0;
        } else {
          return rawVal;
        }
      }
    }
    
    // Fallback: search for any price-like text
    final cleanText = _decodeHtmlEntities(_stripHtml(blockHtml));
    final rawVal = _parseEuropeanPrice(cleanText);
    if (rawVal > 0.0) {
      if (blockHtml.contains('Bs') || cleanText.contains('Bs')) {
        if (_bcvRate > 0.0) {
          return rawVal / _bcvRate;
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
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  double _parseEuropeanPrice(String text) {
    // Quitar todo excepto dígitos, puntos y comas
    final cleaned = text.replaceAll(RegExp(r'[^\d.,]'), '');

    if (cleaned.isEmpty) return 0.0;

    // Si tiene coma: es separador decimal en formato europeo
    // Formato europeo: 1.234,56 → quitar punto, cambiar coma por punto
    if (cleaned.contains(',')) {
      final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }

    // Sin coma: el punto puede ser decimal (USD: 4.99) o miles (raro sin coma)
    // Si hay exactamente un punto y 2 decimales → decimal normal
    final dotCount = cleaned.split('.').length - 1;
    if (dotCount == 1) {
      final parts = cleaned.split('.');
      if (parts.last.length <= 2) {
        return double.tryParse(cleaned) ?? 0.0;
      }
      // Punto como separador de miles (e.g. "1.113") → sin decimales
      return double.tryParse(cleaned.replaceAll('.', '')) ?? 0.0;
    }

    // Múltiples puntos (e.g. "1.234.567") → son separadores de miles
    if (dotCount > 1) {
      return double.tryParse(cleaned.replaceAll('.', '')) ?? 0.0;
    }

    return double.tryParse(cleaned) ?? 0.0;
  }

  // ─── FARMATODO (HeadlessInAppWebView) ───────────────────────────────────────

  Future<void> _scrapeFarmatodo(String query) async {
    final completer = Completer<void>();
    HeadlessInAppWebView? headlessWebView;

    final searchUrl = "https://www.farmatodo.com.ve/buscar?product=${Uri.encodeComponent(query)}&departamento=Todos&filtros=";
    print("🟢 [Farmatodo] Iniciando WebView directamente en: $searchUrl");

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(searchUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldInterceptRequest: false,
      ),
      onLoadStop: (controller, url) async {
        String currentUrl = url?.toString() ?? '';
        print("🤖 [Farmatodo Scraper] onLoadStop URL: $currentUrl");

        if (currentUrl.contains('/buscar')) {
          await _extractAndSaveData(controller, query, completer, headlessWebView);
        } else {
          // Si redirigió a otra página (como el home), forzar la navegación a la búsqueda
          print("⚠️ [Farmatodo] Redirección inesperada a $currentUrl, recargando búsqueda...");
          await controller.loadUrl(
            urlRequest: URLRequest(url: WebUri(searchUrl))
          );
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        String currentUrl = url?.toString() ?? '';
        print("🤖 [Farmatodo Scraper] onUpdateVisitedHistory URL: $currentUrl");
        if (currentUrl.contains('/buscar')) {
          await _extractAndSaveData(controller, query, completer, headlessWebView);
        }
      },
      onLoadError: (controller, url, code, message) async {
        print("❌ [Farmatodo] Error al cargar: $message (code: $code)");
        headlessWebView?.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await headlessWebView.run();
    return completer.future;
  }

  Future<void> _extractAndSaveData(InAppWebViewController controller, String query, Completer<void> completer, HeadlessInAppWebView? headlessWebView) async {
     if (completer.isCompleted) return;
     
     dynamic resultObj;
     try {
       resultObj = await controller.callAsyncJavaScript(
          arguments: {'query': query},
          functionBody: """
          try {
            var items = [];
            for (var j = 0; j < 30; j++) {
               items = document.querySelectorAll('.product-card--search-layout');
               if (items.length > 0) break;
               await new Promise(resolve => setTimeout(resolve, 500));
            }

            if (items.length === 0) {
               return JSON.stringify([]);
            }

            var results = [];
            for (var i = 0; i < items.length; i++) {
              var imgLink = items[i].querySelector('.product-image__link');
              var name = imgLink ? (imgLink.getAttribute('title') || '') : '';
              
              if (!name || name.trim().length === 0) {
                  var nameNode = items[i].querySelector('p.text-title, .product-card__info-link div p:last-of-type, .product-card__info-link p:last-of-type');
                  name = nameNode ? (nameNode.innerText || nameNode.textContent || '').trim() : '';
              }
              if (!name || name.trim().length === 0) {
                  name = (items[i].innerText || items[i].textContent || '').replace(/\\n/g, ' ').trim();
                  if (name.length > 120) name = name.substring(0, 120) + '...';
                  if (!name) name = "Producto Farmatodo";
              }
              
              var sourceNode = items[i].querySelector('picture source');
              var sourceSet = sourceNode ? (sourceNode.getAttribute('srcset') || '') : '';
              if (sourceSet.includes(' ')) sourceSet = sourceSet.split(' ')[0];
              
              var imgNode = items[i].querySelector('.product-image__link img, picture img');
              var imgUrl = sourceSet;
              
              if (!imgUrl && imgNode) {
                  var attrs = imgNode.attributes;
                  for (var a = 0; a < attrs.length; a++) {
                      var val = attrs[a].value;
                      if (val.match(/\\.(jpg|jpeg|png|webp|gif)/i)) {
                          imgUrl = val;
                          break;
                      }
                  }
              }
              if (!imgUrl && imgNode) {
                  imgUrl = imgNode.src || imgNode.getAttribute('data-src') || '';
              }
              
              if (imgUrl.startsWith('//')) imgUrl = 'https:' + imgUrl;
              else if (imgUrl.startsWith('/')) imgUrl = 'https://www.farmatodo.com.ve' + imgUrl;
              
              var priceNodes = items[i].querySelectorAll('.product-card__price-box span, .product-card__price-value, p.text-price, .product-card__info-link span, .product-card__info-link p span, .text-price-discount, .text-price-strike, .text-strike, del');
              var uniquePrices = [];
              
              for (var pIdx = 0; pIdx < priceNodes.length; pIdx++) {
                   var pNode = priceNodes[pIdx];
                   var pStr = pNode.innerText || pNode.textContent || '';
                   
                   // Evitar el PUM (precio unitario de empaque) para no distorsionar
                   if (pNode.className.indexOf('pum') !== -1 || pStr.indexOf(' a Bs') !== -1 || pStr.indexOf(' x Bs') !== -1) {
                       continue;
                   }
                   
                   var oDigs = pStr.replace(/[^\\d]/g, '');
                   var prc = oDigs.length > 0 ? parseFloat(oDigs) / 100 : 0.0;
                   if (prc > 0 && !uniquePrices.includes(prc)) {
                       uniquePrices.push(prc);
                   }
              }
              
              uniquePrices.sort(function(a, b) { return a - b; });
              
              var price = 0.0;
              var originalPrice = null;
              
              if (uniquePrices.length >= 1) {
                  price = uniquePrices[0];
              }
              
              if (price === 0) {
                  var fallbackMatch = (items[i].innerText || items[i].textContent || '').match(/Bs[\\.\\s]*([\\d\\.,]+)/i);
                  if (fallbackMatch && fallbackMatch[1]) {
                      var nDigs = fallbackMatch[1].replace(/[^\\d]/g, '');
                      price = nDigs.length > 0 ? parseFloat(nDigs) / 100 : 0.0;
                  }
              }
              
              // Intentar extraer el porcentaje de descuento si existe app-offer-petal
              var discountNode = items[i].querySelector('app-offer-petal .text, app-offer-petal p, app-offer-petal');
              var discountPercent = 0;
              if (discountNode) {
                  var discountText = discountNode.innerText || discountNode.textContent || '';
                  var pctMatch = discountText.match(/(\\d+)\\s*%/);
                  if (pctMatch) {
                      discountPercent = parseInt(pctMatch[1]);
                  }
              }
              
              if (price > 0 && discountPercent > 0 && discountPercent < 100) {
                  originalPrice = price / (1 - (discountPercent / 100));
              } else if (uniquePrices.length >= 2) {
                  price = uniquePrices[0];
                  originalPrice = uniquePrices[uniquePrices.length - 1];
              }
              
              if (isNaN(price) || price === 0) continue;

              results.push({
                  'name': name,
                  'active_ingredient': "${query.replaceAll('"', '\\"')}",
                  'presentation': 'Farmatodo Web',
                  'price_usd': price,
                  'original_price_usd': originalPrice,
                  'pharmacy_name': 'Farmatodo',
                  'image_url': imgUrl,
                  'product_url': window.location.href
              });
            }
            return JSON.stringify(results);
          } catch(e) {
             return JSON.stringify([]);
          }
          """
       );
     } catch(e) {
       print("❌ [Farmatodo] Error llamando JS: $e");
       resultObj = null;
     }

     final result = resultObj?.value;
     List<Map<String, dynamic>> products = [];
     
     if (result != null && result is String) {
       try {
         final parsed = jsonDecode(result);
         if (parsed is List) {
           for (var item in parsed) {
             var map = Map<String, dynamic>.from(item);
             if (map['price_usd'] is int) {
                map['price_usd'] = (map['price_usd'] as int).toDouble();
             }
             
             double? originalPriceUsd;
             if (map['original_price_usd'] != null) {
                double rawOriginal = (map['original_price_usd'] as num).toDouble();
                if (rawOriginal > 0 && _bcvRate > 0) {
                  originalPriceUsd = double.parse((rawOriginal / _bcvRate).toStringAsFixed(2));
                }
             }

             // Convertir precio VES a USD usando la tasa oficial del BCV antes de guardar en DB
             if (map['price_usd'] > 0 && _bcvRate > 0) {
               final originalVES = map['price_usd'];
               map['price_usd'] = double.parse((originalVES / _bcvRate).toStringAsFixed(2));
               print("💱 [Farmatodo] VES: $originalVES → USD: ${map['price_usd']} (BCV: $_bcvRate)");
             }
             
             final presentationText = originalPriceUsd != null && originalPriceUsd > map['price_usd']
                 ? 'Farmatodo Web || original_price:${originalPriceUsd.toStringAsFixed(2)}'
                 : 'Farmatodo Web';
                 
             map['presentation'] = presentationText;
             map.remove('original_price_usd');
             
             products.add(map);
           }
         }
       } catch(e) {
          print("❌ [Farmatodo] Error parsing results: $e");
       }
     }

     print("🟢 [Farmatodo] Extraídos ${products.length} productos reales.");

     for (var prod in products) {
       await _upsertProduct(prod);
     }

     headlessWebView?.dispose();
     if (!completer.isCompleted) completer.complete();
  }
}
