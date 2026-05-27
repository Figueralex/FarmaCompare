require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());

// --- Configuración de Supabase ---
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// --- Endpoint de Scraping "On-Demand" ---
// Flutter llamará a esta ruta cuando no encuentre algo en Supabase
app.get('/force-scrape', async (req, res) => {
  const query = req.query.q;
  
  if (!query) {
    return res.status(400).json({ error: 'Falta el parámetro de búsqueda (q)' });
  }

  console.log(`\n⚡ Flutter solicitó scraping en vivo para: "${query}"`);

  try {
    // ----------------------------------------------------------------------
    // AQUÍ IRÍA LA LÓGICA REAL DE SCRAPING (Axios / Puppeteer a Farmatodo)
    // ----------------------------------------------------------------------
    // Como esto es un MVP, generaremos resultados simulados al vuelo 
    // basados en la palabra que buscó el usuario, y los inyectaremos en la DB
    // para demostrar que la arquitectura "On-Demand -> Supabase -> Flutter" funciona.

    // Pequeño retardo simulando el tiempo que tarda un bot en leer la página web
    await new Promise(r => setTimeout(r, 1500)); 

    const productosExtraidos = [
      {
        name: query.toUpperCase(),
        active_ingredient: query,
        presentation: 'Caja x 30',
        price_usd: (Math.random() * (5 - 1) + 1).toFixed(2), // Precio aleatorio entre 1 y 5
        pharmacy_name: 'Farmatodo',
        image_url: '',
        product_url: 'https://farmatodo.com.ve'
      },
      {
        name: `${query} Genérico`,
        active_ingredient: query,
        presentation: 'Blister x 10',
        price_usd: (Math.random() * (3 - 0.5) + 0.5).toFixed(2), 
        pharmacy_name: 'Locatel',
        image_url: '',
        product_url: 'https://locatel.com.ve'
      }
    ];

    // Guardamos lo que extrajo el bot directamente en Supabase
    const { data, error } = await supabase
      .from('products')
      .insert(productosExtraidos)
      .select();

    if (error) {
      console.error('❌ Error guardando en Supabase:', error);
      return res.status(500).json({ error: 'Error guardando en Supabase' });
    }

    console.log(`✅ Se guardaron ${data.length} nuevos resultados para "${query}" en Supabase.`);
    
    // Le decimos a Flutter que ya terminamos de extraer la data
    res.json({ success: true, message: 'Scraping completado y guardado en DB' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fallo catastrófico en el scraper' });
  }
});

// Levantar servidor
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Motor de Scraping (Node.js) corriendo en http://0.0.0.0:${PORT}`);
  console.log('Esperando peticiones de la app móvil...\n');
});
