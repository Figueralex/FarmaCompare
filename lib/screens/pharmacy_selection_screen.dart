import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class PharmacySelectionScreen extends ConsumerWidget {
  const PharmacySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pharmacySettingsProvider);
    final notifier = ref.read(pharmacySettingsProvider.notifier);

    // Colores e íconos identificativos por farmacia
    final Map<String, _PharmacyStyle> styles = {
      'Farmatodo': _PharmacyStyle(
        color: const Color(0xFF003893), // Azul Farmatodo
        textColor: Colors.white,
        letter: 'T',
        subtitle: 'Precios en Bolívares (Scraper Directo)',
      ),
      'Farmadon': _PharmacyStyle(
        color: const Color(0xFF00875A), // Verde Farmadon
        textColor: const Color(0xFFE53935), // Letras rojas
        letter: 'D',
        subtitle: 'Precios en USD convertidos a BS',
      ),
      'Farmatina': _PharmacyStyle(
        color: const Color(0xFF8E24AA), // Púrpura Farmatina
        textColor: Colors.white,
        letter: 'F',
        subtitle: 'Precios en USD convertidos a BS',
      ),
      'Farmapaz': _PharmacyStyle(
        color: const Color(0xFFE65100), // Naranja Farmapaz
        textColor: Colors.white,
        letter: 'P',
        subtitle: 'Precios en USD directo (Carga en segundo plano)',
      ),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Farmacias Disponibles',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          // Explicación de la funcionalidad
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Activa o desactiva las farmacias que deseas consultar. Las búsquedas en paralelo omitirán las opciones desmarcadas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'LISTADO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settings.keys.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[100],
              ),
              itemBuilder: (context, index) {
                final pharmacyName = settings.keys.elementAt(index);
                final isEnabled = settings[pharmacyName] ?? true;
                final style = styles[pharmacyName] ?? _PharmacyStyle(
                  color: Colors.grey,
                  textColor: Colors.white,
                  letter: pharmacyName[0],
                  subtitle: '',
                );

                return CheckboxListTile(
                  value: isEnabled,
                  onChanged: (value) async {
                    if (isEnabled && settings.values.where((v) => v).length <= 1) {
                      // Mostrar advertencia si intenta desactivar la única activa
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes tener al menos una farmacia activa para realizar búsquedas.'),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    await notifier.togglePharmacy(pharmacyName);
                  },
                  activeColor: const Color(0xFF1E88E5),
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  secondary: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      style.letter,
                      style: TextStyle(
                        color: style.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    pharmacyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    style.subtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyStyle {
  final Color color;
  final Color textColor;
  final String letter;
  final String subtitle;

  _PharmacyStyle({
    required this.color,
    required this.textColor,
    required this.letter,
    required this.subtitle,
  });
}
