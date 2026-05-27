import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://pqcftrcbiolmycgzywev.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2Z0cmNiaW9sbXljZ3p5d2V2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTEzNjA2MiwiZXhwIjoyMDk0NzEyMDYyfQ.XIWNSijOavp99n3G-VX6LokXIDxRDmV4zCbxRhv9jjM',
  );

  try {
    final response = await supabase
        .from('products')
        .select('*')
        .eq('pharmacy_name', 'Farmapaz');
    
    print("TOTAL PRODUCTOS ENCONTRADOS: ${response.length}");
    for (var p in response) {
      print("ID: ${p['id']} - NAME: ${p['name']} - PRICE: ${p['price_usd']}");
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
