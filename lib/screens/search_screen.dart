import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../providers/search_history_provider.dart';
import '../widgets/search_history_drawer.dart';
import '../services/update_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndShowUpdateDialog(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isNotEmpty) {
      final cleanQuery = query.trim();
      // Guardar en el historial local
      ref.read(searchHistoryProvider.notifier).addSearch(cleanQuery);
      
      // Iniciar la búsqueda
      ref.read(searchProvider.notifier).search(cleanQuery);
      
      // push en lugar de go para que el botón de ir atrás funcione
      await context.push('/results/${Uri.encodeComponent(cleanQuery)}');
      // Limpiar la barra al regresar
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SearchHistoryDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // Botón de historial minimalista en la esquina superior izquierda
            Positioned(
              top: 8,
              left: 8,
              child: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Colors.black54,
                      size: 26,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: 'Historial de búsquedas',
                  );
                }
              ),
            ),
            // Botón de engranaje minimalista en la esquina superior derecha
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black54,
                  size: 26,
                ),
                onPressed: () {
                  context.push('/settings');
                },
                tooltip: 'Ajustes',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Espacio superior (1/3 de la pantalla aprox)
                  const Spacer(flex: 1),
                  
                  // Icono y Logo principal (Nuevo Logo Institucional)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FarmaCompare',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encuentra el mejor precio cerca de ti.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Barra de búsqueda grande
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onSubmitted: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar medicamento...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Icon(Icons.search, color: Colors.grey, size: 28),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1E88E5)),
                        onPressed: () => _onSearchChanged(_searchController.text),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
