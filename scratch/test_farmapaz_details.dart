import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final resp = await dio.get(
      'https://farmapazvenezuela.com/?s=acetaminofen&post_type=product',
      options: Options(headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }),
    );
    final html = resp.data.toString();
    
    final List<int> indexes = [];
    var index = 0;
    while (true) {
      index = html.indexOf('<div class="post-image post-media overlay-hover">', index);
      if (index == -1) break;
      indexes.add(index);
      index += 48;
    }

    for (int i = 0; i < indexes.length; i++) {
      final start = indexes[i];
      final end = (i < indexes.length - 1) ? indexes[i + 1] : start + 4000;
      final block = html.substring(start, end < html.length ? end : html.length);
      
      final nameMatch = RegExp(r'<h4 class="post-title[^"]*"><a[^>]*>(.*?)</a></h4>', dotAll: true).firstMatch(block);
      final name = nameMatch != null ? nameMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim() : 'Unknown';
      
      final cacheMatch = RegExp(r'data-wmc_price_cache="([^"]+)"').firstMatch(block);
      String? usdCache;
      String? vesCache;
      if (cacheMatch != null) {
        final rawCache = cacheMatch.group(1)!.replaceAll('&quot;', '"').replaceAll('&#36;', '\$');
        try {
          final cache = jsonDecode(rawCache);
          usdCache = cache['USD'];
          vesCache = cache['VES'];
        } catch(e) {
          usdCache = "Error decode";
        }
      }

      final priceSpanMatch = RegExp(r'class="woocommerce-Price-amount amount">[\s\S]*?<bdi>([\s\S]*?)</bdi>').firstMatch(block);
      final rawPriceSpan = priceSpanMatch != null ? priceSpanMatch.group(1) : null;

      print("PRODUCTO: $name");
      print("  USD Cache: $usdCache");
      print("  VES Cache: $vesCache");
      print("  Raw Price Span: $rawPriceSpan");
      print("-" * 50);
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
