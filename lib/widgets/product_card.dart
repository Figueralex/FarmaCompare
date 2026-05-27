import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../providers/bcv_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(product.productUrl);
    
    // Registrar el redireccionamiento en segundo plano en Supabase
    try {
      final supabase = Supabase.instance.client;
      supabase.from('click_logs').insert({
        'pharmacy_name': product.pharmacyName,
        'product_name': product.name,
        'product_url': product.productUrl,
      }).then((_) {
        debugPrint('📈 Redirección registrada para: ${product.pharmacyName}');
      }).catchError((e) {
        debugPrint('⚠️ Error registrando redirección: $e');
      });
    } catch (e) {
      debugPrint('⚠️ Error de Supabase al registrar clic: $e');
    }

    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  String _formatBs(double amount) {
    List<String> parts = amount.toStringAsFixed(2).split('.');
    String whole = parts[0];
    String decimal = parts[1];
    
    String formattedWhole = '';
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        formattedWhole += '.';
      }
      formattedWhole += whole[i];
    }
    
    return 'Bs. $formattedWhole,$decimal';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bcvRateAsync = ref.watch(bcvRateProvider);

    final Color badgeBgColor;
    final Color badgeTextColor;

    switch (product.pharmacyName.toLowerCase()) {
      case 'farmadon':
        badgeBgColor = const Color(0xFFC8E6C9);
        badgeTextColor = const Color(0xFFB71C1C);
        break;
      case 'farmatina':
        badgeBgColor = const Color(0xFFF3E5F5); // Light purple
        badgeTextColor = const Color(0xFF6A1B9A); // Deep purple
        break;
      case 'farmapaz':
        badgeBgColor = const Color(0xFFFFE0B2); // Light orange
        badgeTextColor = const Color(0xFFE65100); // Deep orange
        break;
      case 'farmatodo':
      default:
        badgeBgColor = const Color(0xFFE3F2FD);
        badgeTextColor = const Color(0xFF1E88E5);
        break;
    }

    return InkWell(
      onTap: _launchUrl,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.medication,
                          color: Color(0xFF1E88E5),
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.medication,
                        color: Color(0xFF1E88E5),
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Nombre (ahora con 3 líneas)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Precio y Farmacia
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Precio en Bs.
                bcvRateAsync.when(
                  data: (rate) {
                    final currentRate = rate > 0 ? rate : 1.0;
                    final displayPrice = product.price * currentRate;
                    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;
                    
                    if (hasDiscount) {
                      final displayOriginalPrice = product.originalPrice! * currentRate;
                      final discountPercent = ((product.originalPrice! - product.price) / product.originalPrice! * 100).round();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE), // Very light red
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFCDD2)),
                                ),
                                child: Text(
                                  '-$discountPercent%',
                                  style: const TextStyle(
                                    color: Color(0xFFC62828), // Deep red
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatBs(displayOriginalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatBs(displayPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: Color(0xFF2E7D32), // Premium green for discount
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        _formatBs(displayPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      );
                    }
                  },
                  loading: () => const SizedBox(
                    width: 60,
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) {
                    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;
                    if (hasDiscount) {
                      final discountPercent = ((product.originalPrice! - product.price) / product.originalPrice! * 100).round();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFFCDD2)),
                                ),
                                child: Text(
                                  '-$discountPercent%',
                                  style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatBs(product.originalPrice!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatBs(product.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        _formatBs(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.pharmacyName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
