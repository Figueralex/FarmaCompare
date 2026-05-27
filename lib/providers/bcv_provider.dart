import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/bcv_repository.dart';

final bcvRepositoryProvider = Provider<BcvRepository>((ref) {
  return BcvRepository();
});

final bcvRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(bcvRepositoryProvider);
  return repository.getOfficialRate();
});
