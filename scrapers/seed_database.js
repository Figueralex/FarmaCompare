require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Verificamos que las variables existan
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey || supabaseKey === 'TU_SERVICE_ROLE_KEY_AQUI') {
  console.error('❌ ERROR: Debes configurar SUPABASE_SERVICE_KEY en el archivo .env antes de continuar.');
  process.exit(1);
}

// Inicializamos el cliente de Supabase usando el SERVICE_ROLE_KEY
// El service_role ignora las reglas de RLS y permite insertar datos desde un backend.
const supabase = createClient(supabaseUrl, supabaseKey);

const medicamentosFicticios = [
  {
    name: 'Losartan Potásico',
    active_ingredient: 'Losartan',
    presentation: '50mg x 30 Tabletas',
    price_usd: 2.50,
    pharmacy_name: 'Farmatodo',
    image_url: '',
    product_url: 'https://farmatodo.com.ve'
  },
  {
    name: 'Losartan Potásico',
    active_ingredient: 'Losartan',
    presentation: '50mg x 30 Tabletas',
    price_usd: 1.80,
    pharmacy_name: 'Farmadon',
    image_url: '',
    product_url: 'https://farmadon.com.ve'
  },
  {
    name: 'Atamel Forte',
    active_ingredient: 'Acetaminofén',
    presentation: '650mg x 10 Tabletas',
    price_usd: 1.20,
    pharmacy_name: 'RedVital',
    image_url: '',
    product_url: 'https://redvital.com'
  },
  {
    name: 'Atamel',
    active_ingredient: 'Acetaminofén',
    presentation: '500mg x 10 Tabletas',
    price_usd: 0.90,
    pharmacy_name: 'Locatel',
    image_url: '',
    product_url: 'https://locatel.com.ve'
  },
  {
    name: 'Ibuprofeno',
    active_ingredient: 'Ibuprofeno',
    presentation: '400mg x 10 Cápsulas',
    price_usd: 1.50,
    pharmacy_name: 'Farmatodo',
    image_url: '',
    product_url: 'https://farmatodo.com.ve'
  },
  {
    name: 'Ibuprofeno',
    active_ingredient: 'Ibuprofeno',
    presentation: '400mg x 10 Cápsulas',
    price_usd: 1.10,
    pharmacy_name: 'Farmahorro',
    image_url: '',
    product_url: 'https://farmahorro.com.ve'
  },
];

async function seedDatabase() {
  console.log('🔄 Iniciando carga de datos en Supabase...');

  // Limpiar la tabla antes de sembrar (Opcional, útil para pruebas)
  // await supabase.from('products').delete().neq('id', '00000000-0000-0000-0000-000000000000');

  // Insertar los medicamentos
  const { data, error } = await supabase
    .from('products')
    .insert(medicamentosFicticios)
    .select();

  if (error) {
    console.error('❌ Error al insertar datos:', error.message);
  } else {
    console.log(`✅ ¡Éxito! Se insertaron ${data.length} productos en la base de datos.`);
    console.log('📱 Ya puedes buscar "Losartan", "Atamel" o "Ibuprofeno" en tu app Flutter y verás resultados reales desde la nube.');
  }
}

seedDatabase();
