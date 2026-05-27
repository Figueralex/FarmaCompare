require('dotenv').config();
const axios = require('axios');

async function testPriceExtraction() {
  console.log('=== TEST EXTRACCIÓN DE PRECIO ===\n');
  
  const productUrl = 'https://www.farmadon.com.ve/producto/aspirina-sabor-naranja-acido-acetilsalicilico-81mg-x-36-tabletas-masticables-health-a2z/';
  
  const resp = await axios.get(productUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120',
      'Accept': 'text/html',
      'Accept-Language': 'es-VE,es;q=0.9',
    },
    timeout: 20000,
  });
  
  const html = resp.data;
  
  // 1. Buscar wmc_price_cache - puede estar con entidades HTML
  console.log('--- Búsqueda wmc_price_cache ---');
  const wmcIdx = html.indexOf('wmc_price_cache');
  if (wmcIdx > 0) {
    const sample = html.substring(wmcIdx - 5, wmcIdx + 500);
    console.log('Encontrado en posición', wmcIdx);
    console.log('Muestra raw:', sample.substring(0, 300));
    
    // El regex del scraper Flutter
    const cacheMatch = html.match(/data-wmc_price_cache="([^"]+)"/);
    if (cacheMatch) {
      console.log('\ndata-wmc_price_cache attr encontrado:', cacheMatch[1].substring(0, 200));
      
      // Decodificar entidades HTML
      let raw = cacheMatch[1]
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#039;/g, "'");
      
      console.log('Decodificado:', raw.substring(0, 200));
      
      // Buscar USD
      const usdMatch = raw.match(/"USD"\s*:\s*"([^"]+)"/);
      if (usdMatch) {
        console.log('Valor USD raw:', usdMatch[1]);
        const numMatch = usdMatch[1].match(/[\d]+[.,][\d]+|[\d]+/);
        if (numMatch) {
          console.log('Número extraído:', numMatch[0]);
          console.log('Precio USD parseado:', parseFloat(numMatch[0].replace(',', '.')));
        }
      } else {
        console.log('USD no encontrado en el cache. Keys disponibles:');
        const keys = [...raw.matchAll(/"([A-Z]{3,})":/g)].map(m => m[1]);
        console.log(keys);
      }
    } else {
      // Buscar variante con entidades
      const wmcAlt = html.match(/data-wmc_price_cache=\\?"([^"\\]+)\\?"/);
      console.log('Alternativa escapada:', wmcAlt ? 'SÍ' : 'NO');
    }
  } else {
    console.log('wmc_price_cache NO encontrado');
  }
  
  // 2. Buscar product:price:amount (Open Graph Facebook)
  console.log('\n--- Búsqueda product:price:amount ---');
  const productPrice = html.match(/property="product:price:amount" content="([^"]+)"/);
  console.log('product:price:amount:', productPrice ? productPrice[1] : 'NO');
  
  const productCurrency = html.match(/property="product:price:currency" content="([^"]+)"/);
  console.log('product:price:currency:', productCurrency ? productCurrency[1] : 'NO');
  
  // 3. Buscar en el HTML de precio (span.amount)
  console.log('\n--- Búsqueda precio en HTML ---');
  const priceSpanMatch = html.match(/<span class="woocommerce-Price-amount amount">([\s\S]{0,200})/);
  if (priceSpanMatch) {
    console.log('woocommerce-Price-amount raw:', priceSpanMatch[1].substring(0, 150));
    // Limpiar HTML
    const cleanPrice = priceSpanMatch[1].replace(/<[^>]+>/g, '').trim();
    console.log('Precio limpio:', cleanPrice.substring(0, 50));
  }
  
  // 4. Buscar REF en HTML
  console.log('\n--- Búsqueda REF ---');
  const allREF = [...html.matchAll(/REF[\s]*[\d,.]+/gi)].slice(0,5);
  allREF.forEach(m => console.log('  REF:', m[0]));
  if (allREF.length === 0) console.log('  Sin coincidencias REF');
  
  // 5. La URL tiene la respuesta directamente en meta tag - este sería el fix
  console.log('\n--- SOLUCIÓN PROPUESTA ---');
  if (productPrice) {
    console.log(`Precio en VES: ${productPrice[1]} ${productCurrency ? productCurrency[1] : '?'}`);
    console.log('Para convertir a USD se necesita la tasa BCV o WMC');
    
    // Ver si hay precio en otra moneda
    const allPrices = [...html.matchAll(/property="product:price:amount" content="([^"]+)"/g)];
    const allCurrencies = [...html.matchAll(/property="product:price:currency" content="([^"]+)"/g)];
    allPrices.forEach((p, i) => {
      console.log(`  Precio ${i+1}: ${p[1]} ${allCurrencies[i] ? allCurrencies[i][1] : '?'}`);
    });
  }
}

testPriceExtraction().catch(console.error);
