import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('Check app_version table in Supabase', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;

    await Supabase.initialize(
      url: 'https://pqcftrcbiolmycgzywev.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2Z0cmNiaW9sbXljZ3p5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMzYwNjIsImV4cCI6MjA5NDcxMjA2Mn0.XEBr2E7_JcVkxNXR3zJclwXfOVHiMMN53xS5gGdzAmk',
    );

    print('\n📋 Consultando tabla app_version en Supabase...\n');

    final response = await Supabase.instance.client
        .from('app_version')
        .select()
        .order('version_code', ascending: false);

    final data = response as List<dynamic>;

    if (data.isEmpty) {
      print('❌ La tabla app_version está VACÍA. No hay ningún registro.');
    } else {
      print('✅ Registros encontrados: ${data.length}');
      for (var row in data) {
        print('---');
        print('  version_code  : ${row['version_code']}');
        print('  version_name  : ${row['version_name']}');
        print('  apk_url       : ${row['apk_url']}');
        print('  force_update  : ${row['force_update']}');
        print('  release_notes : ${row['release_notes']}');
      }
    }

    print('\n💡 El teléfono tiene Build 39. Para disparar el update dialog,');
    print('   debe existir un registro con version_code >= 40 en la tabla.');
  });
}
