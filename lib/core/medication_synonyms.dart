class MedicationSynonyms {
  static const Map<String, String> _synonyms = {
    'alpram': 'alprazolam',
    'tafil': 'alprazolam',
    'xanax': 'alprazolam',
    'constan': 'alprazolam',
    
    'atamel': 'acetaminofen',
    'tachipirin': 'acetaminofen',
    'apiret': 'acetaminofen',
    'tempra': 'acetaminofen',
    'alivet': 'acetaminofen',
    'paracetamol': 'acetaminofen',
    
    'brugesic': 'ibuprofeno',
    'ibudil': 'ibuprofeno',
    'advil': 'ibuprofeno',
    'motrin': 'ibuprofeno',
    'alivax': 'ibuprofeno',
    
    'voltaren': 'diclofenac',
    'clofen': 'diclofenac',
    'viavil': 'diclofenac',
    'cataflam': 'diclofenac',
    'diklason': 'diclofenac',
    
    'glucofage': 'metformina',
    'glafornil': 'metformina',
    
    'concor': 'bisoprolol',
    'bisoprol': 'bisoprolol',
    
    'cozaar': 'losartan',
    'covance': 'losartan',
    'losacor': 'losartan',
    'pyregal': 'losartan',
    
    'lipitor': 'atorvastatina',
    'astor': 'atorvastatina',
    'zertine': 'atorvastatina',
    
    'norvasc': 'amlodipina',
    'amlodip': 'amlodipina',
    
    'buscapina': 'hioscina',
    'buscapina duo': 'hioscina',
    'femex': 'hioscina',
    
    'aspirina': 'acido acetilsalicilico',
    'cardioaspirina': 'acido acetilsalicilico',
    
    'clarityne': 'loratadina',
    'alerpriv': 'loratadina',
    
    'talzic': 'cetirizina',
    'cetral': 'cetirizina',
    'zyrtec': 'cetirizina',
    
    'ulcom al': 'omeprazol',
    'losec': 'omeprazol',
    'gastrozol': 'omeprazol',
    
    'pantecta': 'pantoprazol',
    'zoltum': 'pantoprazol',
    
    'nexium': 'esomeprazol',
    'esomax': 'esomeprazol',
    
    'amoxil': 'amoxicilina',
    'amoxival': 'amoxicilina',
    
    'desler': 'desloratadina',
    'mailen': 'desloratadina',
    'aerius': 'desloratadina',
  };

  /// Normaliza el texto quitando acentos y pasando a minúsculas
  static String normalize(String text) {
    var str = text.toLowerCase().trim();
    str = str.replaceAll('á', 'a');
    str = str.replaceAll('é', 'e');
    str = str.replaceAll('í', 'i');
    str = str.replaceAll('ó', 'o');
    str = str.replaceAll('ú', 'u');
    str = str.replaceAll('ñ', 'n');
    return str;
  }

  /// Retorna el principio activo si la query coincide con una marca conocida.
  /// De lo contrario, si la query ya es un principio activo conocido, se retorna a sí misma.
  /// Si no está mapeada, retorna null.
  static String? getActiveIngredient(String query) {
    final normalized = normalize(query);
    if (_synonyms.containsKey(normalized)) {
      return _synonyms[normalized];
    }
    if (_synonyms.values.contains(normalized)) {
      return normalized;
    }
    return null;
  }

  /// Retorna el término optimizado para los scrapers web.
  /// Si es una marca conocida, devuelve el principio activo (ej. "alprazolam" para "Alpram").
  /// Si no, devuelve la query original.
  static String getScraperTerm(String query) {
    final activeIng = getActiveIngredient(query);
    if (activeIng != null) {
      return activeIng;
    }
    return query.trim();
  }

  /// Retorna una lista con la query original y su principio activo (si existe)
  /// para usar en consultas SQL de Supabase.
  static List<String> expandQuery(String query) {
    final normalized = normalize(query);
    final list = <String>[query.trim()];
    
    final activeIng = getActiveIngredient(query);
    if (activeIng != null) {
      if (!list.any((e) => normalize(e) == normalize(activeIng))) {
        list.add(activeIng);
      }
    }
    
    return list;
  }
}
