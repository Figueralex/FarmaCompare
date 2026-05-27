import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_card.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const ResultsScreen({super.key, required this.initialQuery});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late TextEditingController _searchController;
  bool _onlyMedications = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    // Colocar el cursor al final de la palabra para no interrumpir el flujo
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );

    // Ejecutar la búsqueda con la primera letra inmediatamente después de inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).search(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(searchProvider.notifier).search('');
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: false, // Don't autofocus if we already searched
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  ref.read(searchProvider.notifier).search(query);
                }
              },
            ),
          ),
          onSubmitted: (query) {
            final trimmed = query.trim();
            if (trimmed.isNotEmpty) {
              ref.read(searchProvider.notifier).search(trimmed);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildBody(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state is SearchInitial) {
      return const Center(child: Text('Escribe para buscar...'));
    }

    if (state is SearchLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonCard(),
      );
    }

    if (state is SearchError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state is SearchLoaded) {
      final products = _onlyMedications
          ? state.products.where(_isMedication).toList()
          : state.products;

      if (products.isEmpty) {
        if (state.isSearchingBackground) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Buscando en Farmapaz...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consultando catálogo en tiempo real.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Text(
            'No se encontraron resultados.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return Column(
        children: [
          if (state.isSearchingBackground)
            Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Buscando mejores opciones en Farmapaz...',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(product: product);
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            avatar: Icon(
              _onlyMedications ? Icons.healing : Icons.healing_outlined,
              size: 16,
              color: _onlyMedications ? Colors.white : Colors.blue.shade700,
            ),
            label: const Text('Solo Medicamentos'),
            selected: _onlyMedications,
            onSelected: (bool selected) {
              setState(() {
                _onlyMedications = selected;
              });
            },
            selectedColor: Colors.blue.shade700,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.blue.shade50,
            labelStyle: TextStyle(
              color: _onlyMedications ? Colors.white : Colors.blue.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _onlyMedications ? Colors.blue.shade700 : Colors.blue.shade100,
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMedication(Product product) {
    final nameLower = product.name.toLowerCase();

    // ── ETAPA 1: Exclusión — palabras que identifican claramente NO-medicamentos ──
    final exclusionPatterns = [
      // Cosméticos y cuidado personal
      RegExp(r'\b(shampoo|champ[uú]|acondicionador|enjuague capilar|jabón corporal|jabon corporal|gel de ba[nñ]o|crema corporal|loci[oó]n|hidratante|desmaquillante|t[oó]nico facial|s[eé]rum|mascarilla facial|exfoliante|delineador|base de maquillaje|labial|brillo de labios|perfume|colonia|desodorante|antitranspirante|depilador|rasuradora|afeitadora)\b'),
      // Accesorios y dispositivos no farmacéuticos
      RegExp(r'\b(pa[nñ]al|toalla sanitaria|liners?|protector diario|copa menstrual|term[oó]metro digital|tensi[oó]metro|gluc[oó]metro|nebulizador|andador|bast[oó]n|muleta|faja|rodillera|tobillera|mu[nñ]equera|codillera|collar[ií]n cervical)\b'),
      // Alimentos y bebidas
      RegExp(r'\b(prote[ií]na en polvo|barra energ[eé]tica|bebida energ[eé]tica|bebida isot[oó]nica|bebida deportiva|leche en polvo|f[oó]rmula infantil|cereal|galleta|snack|caramelo|chicle|goma de mascar|chocolate|jugo|refresco|agua de coco)\b'),
      // Artículos del hogar
      RegExp(r'\b(detergente|suavizante de ropa|limpiador multiusos|desinfectante para pisos|insecticida|ambientador|bolsa de basura)\b'),
      // Fragancias
      RegExp(r'\b(eau de parfum|eau de toilette|edp\b|edt\b)\b'),
    ];

    for (final pattern in exclusionPatterns) {
      if (pattern.hasMatch(nameLower)) return false;
    }

    // ── ETAPA 2: Inclusión — señales positivas de que ES un medicamento ──
    final inclusionPatterns = [
      // Concentración con unidad de dosis
      RegExp(r'\b\d+\s*(mg|mcg|ug|ui|iu)\b'),
      // Formas farmacéuticas sólidas / líquidas
      RegExp(r'\b(tabletas?|comprimidos?|c[aá]psulas?|grageas?|ampollas?|viales?|supositorios?|[oó]vulos?|suspensi[oó]n oral|jarabe|gotas orales|soluci[oó]n inyectable|colirio|pomada|ung[üu]ento|parche transd[eé]rmico|inhalador|aerosol nasal|polvo liofilizado)\b'),
      // Laboratorios / marcas farmacéuticas conocidas en Venezuela
      RegExp(r'\b(calox|la san[tú]e|behrens|valmorca|megalabs|snc pharma|dollder|cofasa|genven|pharmetique|aless|bayer|pfizer|sanofi|novartis|roche|gsk|astrazeneca|merck|abbott|lilly|boehringer|servier|janssen|teva|richmond|lafrancol|genfar|procaps|roemmers|eurofarma)\b'),
      // Sales farmacéuticas en el nombre
      RegExp(r'\b(clorhidrato|hidrocloruro|fosfato|sulfato|citrato|maleato|fumarato|tartrato|acetato|gluconato|lactato|nitrato|succinato|valerato|benzoato)\b'),
    ];

    for (final pattern in inclusionPatterns) {
      if (pattern.hasMatch(nameLower)) return true;
    }

    // Sin señal positiva clara → no clasificar como medicamento
    return false;
  }
}
