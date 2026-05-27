import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://pqcftrcbiolmycgzywev.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2Z0cmNiaW9sbXljZ3p5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMzYwNjIsImV4cCI6MjA5NDcxMjA2Mn0.XEBr2E7_JcVkxNXR3zJclwXfOVHiMMN53xS5gGdzAmk',
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FarmaCompareApp(),
    ),
  );
}

class FarmaCompareApp extends StatelessWidget {
  const FarmaCompareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FarmaCompare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
