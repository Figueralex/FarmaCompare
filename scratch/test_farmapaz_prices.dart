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
    print("STATUS: ${resp.statusCode}");
    final html = resp.data.toString();
    
    // Buscar data-wmc_price_cache
    final cacheReg = RegExp(r'data-wmc_price_cache="([^"]+)"');
    final matches = cacheReg.allMatches(html);
    print("Matches data-wmc_price_cache: ${matches.length}");
    for (var m in matches.take(3)) {
      print("Cache: ${m.group(1)}");
    }

    // Buscar precios normales
    final priceReg = RegExp(r'class="woocommerce-Price-amount amount">[\s\S]*?<bdi>([\s\S]*?)</bdi>');
    final pMatches = priceReg.allMatches(html);
    print("Matches woocommerce-Price-amount: ${pMatches.length}");
    for (var m in pMatches.take(3)) {
      print("Price: ${m.group(1)}");
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
