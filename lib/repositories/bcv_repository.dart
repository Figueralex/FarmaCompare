import 'package:dio/dio.dart';

class BcvRepository {
  final Dio _dio = Dio();

  Future<double> getOfficialRate() async {
    // 1. Intentar obtener la tasa oficial en tiempo real directamente de la página del BCV
    try {
      print("🌐 Intentando obtener tasa en tiempo real de la página del BCV (bcv.org.ve)...");
      final response = await _dio.get(
        'https://www.bcv.org.ve/',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3'
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final html = response.data.toString();
        final regExp = RegExp(r'id="dolar"[\s\S]*?<strong[^>]*?>\s*([0-9.,]+)\s*<\/strong>', caseSensitive: false);
        final match = regExp.firstMatch(html);
        if (match != null) {
          final valueStr = match.group(1)?.replaceAll(',', '.') ?? '';
          final rate = double.tryParse(valueStr) ?? 0.0;
          if (rate > 0.0) {
            // Verificar que la fecha de vigencia no sea futura
            final dateRegExp = RegExp(r'class="date-display-single"[^>]*?content="([^"]+)"');
            final dateMatch = dateRegExp.firstMatch(html);
            if (dateMatch != null) {
              final dateStr = dateMatch.group(1);
              if (dateStr != null && dateStr.length >= 10) {
                final datePart = dateStr.substring(0, 10);
                final parts = datePart.split('-');
                final bcvYear = int.parse(parts[0]);
                final bcvMonth = int.parse(parts[1]);
                final bcvDay = int.parse(parts[2]);

                final nowUtc = DateTime.now().toUtc();
                final nowVenezuela = nowUtc.subtract(const Duration(hours: 4));
                
                final bcvDateOnly = DateTime(bcvYear, bcvMonth, bcvDay);
                final venDateOnly = DateTime(nowVenezuela.year, nowVenezuela.month, nowVenezuela.day);

                if (bcvDateOnly.isAfter(venDateOnly)) {
                  print("⏳ La tasa del BCV obtenida ($rate) es para el futuro ($datePart). Hoy es ${venDateOnly.year}-${venDateOnly.month.toString().padLeft(2, '0')}-${venDateOnly.day.toString().padLeft(2, '0')} en Venezuela. Usando fallback...");
                  return 0.0; // Fuerza el fallback a DolarAPI para usar la tasa del día actual
                }
              }
            }
            print("✅ Tasa BCV obtenida directamente de bcv.org.ve: $rate");
            return rate;
          }
        }
      }
    } catch (e) {
      print("⚠️ No se pudo obtener la tasa desde bcv.org.ve ($e). Usando fallback...");
    }

    // 2. Fallback: DolarAPI (tasa cached, puede tener ligero retraso)
    try {
      print("🌐 Obteniendo tasa BCV desde DolarAPI (fallback)...");
      final response = await _dio.get(
        'https://ve.dolarapi.com/v1/dolares/oficial',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['promedio'] != null) {
          final rate = (data['promedio'] as num).toDouble();
          print("✅ Tasa BCV obtenida desde DolarAPI: $rate");
          return rate;
        }
      }
    } catch (e) {
      print("❌ Error al obtener tasa de DolarAPI: $e");
    }

    return 0.0;
  }
}
