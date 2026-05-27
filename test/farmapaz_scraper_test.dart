import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmacompare/services/farmapaz_scraper.dart';

class TestLocalStorage extends LocalStorage {
  const TestLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}

class TestGotrueAsyncStorage extends GotrueAsyncStorage {
  const TestGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}

void main() {
  test(
    'Test Farmapaz Scraper execution and Supabase insert',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
    
    // Inicializar Supabase con localStorage de prueba y opciones de autenticación para evitar errores en tests
    await Supabase.initialize(
      url: 'https://pqcftrcbiolmycgzywev.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2Z0cmNiaW9sbXljZ3p5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMzYwNjIsImV4cCI6MjA5NDcxMjA2Mn0.XEBr2E7_JcVkxNXR3zJclwXfOVHiMMN53xS5gGdzAmk',
      authOptions: const FlutterAuthClientOptions(
        localStorage: TestLocalStorage(),
        pkceAsyncStorage: TestGotrueAsyncStorage(),
      ),
    );

    print("🚀 Iniciando test de FarmapazScraper para 'acetaminofen'...");
    
    // Instanciar y ejecutar el scraper
    final scraper = FarmapazScraper();
    await scraper.scrape('acetaminofen');



    // Verificar en Supabase que existan registros de Farmapaz
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .eq('pharmacy_name', 'Farmapaz')
        .eq('active_ingredient', 'acetaminofen');

    print("📊 Resultados en Supabase para Farmapaz: ${response.length} productos");
    expect(response.length, greaterThan(0));

    for (var item in response) {
      print("  - ${item['name']} | USD: ${item['price_usd']} | URL: ${item['product_url']}");
      expect(item['name'], isNotEmpty);
      expect(item['price_usd'], greaterThan(0.0));
      expect(item['product_url'], isNotEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
