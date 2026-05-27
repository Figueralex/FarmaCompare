import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/scraper_service.dart';
import '../lib/repositories/bcv_repository.dart';
import 'dart:convert';

void main() async {
  print('=== STARTING LIVE SCRAPING TEST ===');
  
  // Initialize Supabase (read-only for this test or let it fail gracefully if key is not needed)
  try {
    await Supabase.initialize(
      url: 'https://pqcftrcbiolmycgzywev.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2Z0cmNiaW9sbXljZ3p5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMzYwNjIsImV4cCI6MjA5NDcxMjA2Mn0.XEBr2E7_JcVkxNXR3zJclwXfOVHiMMN53xS5gGdzAmk',
    );
  } catch (e) {
    print('Supabase init warning (might be already initialized): $e');
  }

  final bcvRate = await BcvRepository().getOfficialRate();
  print('Official BCV Rate: $bcvRate VES/USD');

  final dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }
  ));

  // --- TEST FARMADON SCRAPING FOR AMPICILINA ---
  print('\n--- TESTING FARMADON SCRAPING ---');
  final farmadonUrl = 'https://www.farmadon.com.ve/?s=ampicilina&post_type=product';
  try {
    final resp = await dio.get(farmadonUrl);
    final html = resp.data.toString();
    final urlRegex = RegExp(r'href="(https://www\.farmadon\.com\.ve/producto/[^"]+)"', caseSensitive: false);
    final urls = urlRegex.allMatches(html).map((m) => m.group(1)!).toSet().take(5).toList();
    
    print('Found Farmadon product URLs: $urls');
    
    for (final url in urls) {
      final pResp = await dio.get(url);
      final pHtml = pResp.data.toString();
      
      // Extract name
      String name = '';
      final nameMatch = RegExp(r'<h1[^>]*class="[^"]*product_title[^"]*"[^>]*>(.*?)</h1>', dotAll: true).firstMatch(pHtml);
      if (nameMatch != null) {
        name = nameMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      }
      
      // Test the ins/del logic
      final insMatch = RegExp(r'<ins[^>]*>([\s\S]*?)</ins>', caseSensitive: false).firstMatch(pHtml);
      final delMatch = RegExp(r'<del[^>]*>([\s\S]*?)</del>', caseSensitive: false).firstMatch(pHtml);
      
      print('\nProduct: $name');
      print('URL: $url');
      print('ins block found: ${insMatch != null}');
      print('del block found: ${delMatch != null}');
      
      if (insMatch != null) {
        final insHtml = insMatch.group(1)!;
        final spanMatch = RegExp(r'class="woocommerce-Price-amount amount"><bdi>(.*?)</bdi>', dotAll: true).firstMatch(insHtml);
        if (spanMatch != null) {
          final priceText = spanMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
          print('Discounted Price Text inside ins: $priceText');
        }
      }
      if (delMatch != null) {
        final delHtml = delMatch.group(1)!;
        final spanMatch = RegExp(r'class="woocommerce-Price-amount amount"><bdi>(.*?)</bdi>', dotAll: true).firstMatch(delHtml);
        if (spanMatch != null) {
          final priceText = spanMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
          print('Original Price Text inside del: $priceText');
        }
      }
    }
  } catch (e) {
    print('Farmadon test error: $e');
  }

  print('\n=== TEST COMPLETE ===');
}
