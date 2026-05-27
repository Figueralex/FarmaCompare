require('dotenv').config();
const axios = require('axios');

async function testFarmadon() {
  console.log('=== TEST FARMADON SCRAPER ===\n');
  
  // ---- Test 1: Página de búsqueda ----
  const searchUrl = 'https://www.farmadon.com.ve/?s=aspirina&post_type=product';
  console.log('Test 1: GET', searchUrl);
  
  let html = '';
  try {
    const resp = await axios.get(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-VE,es;q=0.9',
      },
      timeout: 20000,
      maxRedirects: 10
    });
    
    html = resp.data;
    console.log('  Status:', resp.status);
    console.log('  Longitud HTML:', html.length, 'caracteres');
    
    // Buscar URLs de productos con el mismo regex que usa Flutter
    const urlRegex = /href="(https:\/\/www\.farmadon\.com\.ve\/producto\/[^"]+)"/gi;
    const allMatches = [];
    let m;
    while ((m = urlRegex.exec(html)) !== null) {
      allMatches.push(m[1]);
    }
    const uniqueUrls = [...new Set(allMatches)];
    
    console.log('\n  URLs /producto/ encontradas:', uniqueUrls.length);
    if (uniqueUrls.length > 0) {
      uniqueUrls.slice(0, 5).forEach(u => console.log('    -', u));
    } else {
      console.log('  ⚠️  CERO URLS encontradas - el regex NO funciona');
      
      // Buscar cualquier link a farmadon.com.ve
      const anyLink = /href="(https:\/\/www\.farmadon\.com\.ve\/[^"]+)"/gi;
      const anyMatches = [];
      while ((m = anyLink.exec(html)) !== null) {
        anyMatches.push(m[1]);
      }
      const uniqueAny = [...new Set(anyMatches)].slice(0, 10);
      console.log('  Links a farmadon.com.ve que SÍ aparecen:');
      uniqueAny.forEach(u => console.log('    -', u));
    }
    
    // Buscar datos de precio en la búsqueda
    console.log('\n  Datos de precio en página de búsqueda:');
    console.log('    wmc_price_cache:', html.includes('wmc_price_cache') ? 'SÍ encontrado' : 'NO encontrado (JS-rendered)');
    console.log('    og:price:amount:', html.includes('og:price:amount') ? 'SÍ' : 'NO');
    
    const spanPrice = html.match(/class="price"[^>]*>[\s\S]{0,200}/);
    console.log('    span.price sample:', spanPrice ? spanPrice[0].substring(0, 100) : 'NO encontrado');
    
  } catch (e) {
    console.error('  ❌ ERROR en búsqueda:', e.message);
    if (e.response) console.error('  Status:', e.response.status);
  }

  // ---- Test 2: Página individual de producto ----
  const productUrl = 'https://www.farmadon.com.ve/producto/aspirina-sabor-naranja-acido-acetilsalicilico-81mg-x-36-tabletas-masticables-health-a2z/';
  console.log('\n\nTest 2: GET producto individual');
  console.log('  URL:', productUrl);

  try {
    const resp2 = await axios.get(productUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-VE,es;q=0.9',
      },
      timeout: 20000,
    });
    
    const html2 = resp2.data;
    console.log('  Status:', resp2.status);
    
    // Nombre del producto
    const nameMatch = html2.match(/<h1[^>]*class="[^"]*product_title[^"]*"[^>]*>([\s\S]*?)<\/h1>/i);
    console.log('\n  Nombre (h1.product_title):', nameMatch ? nameMatch[1].replace(/<[^>]+>/g,'').trim() : 'NO encontrado');
    
    const ogTitle = html2.match(/<meta property="og:title" content="([^"]+)"/);
    console.log('  og:title:', ogTitle ? ogTitle[1] : 'NO encontrado');
    
    // Precio
    console.log('\n  Búsqueda de precio:');
    const hasWmc = html2.includes('wmc_price_cache');
    console.log('    wmc_price_cache:', hasWmc ? 'SÍ' : 'NO (crítico - precio en JS)');
    
    const ogPrice = html2.match(/<meta property="og:price:amount" content="([^"]+)"/);
    console.log('    og:price:amount:', ogPrice ? ogPrice[1] : 'NO encontrado');
    
    // Intentar encontrar precio en cualquier forma
    const refPrice = html2.match(/REF\s*[\d,.]+/i);
    console.log('    REF precio:', refPrice ? refPrice[0] : 'NO encontrado');
    
    const spanAmountMatch = html2.match(/class="woocommerce-Price-amount amount">[\s\S]{0,100}/);
    console.log('    woocommerce-Price-amount:', spanAmountMatch ? spanAmountMatch[0].substring(0, 80) : 'NO');
    
    // Guardar muestra del HTML para inspección
    const priceSectionIdx = html2.indexOf('price');
    if (priceSectionIdx > 0) {
      console.log('\n    Muestra HTML cerca de "price":');
      console.log('   ', html2.substring(priceSectionIdx - 20, priceSectionIdx + 200).replace(/\n/g,' ').substring(0,200));
    }
    
    // Imagen
    const ogImg = html2.match(/<meta property="og:image" content="([^"]+)"/);
    console.log('\n  og:image:', ogImg ? ogImg[1].substring(0, 60) + '...' : 'NO encontrado');
    
  } catch (e) {
    console.error('  ❌ ERROR en producto:', e.message);
  }
  
  console.log('\n\n=== DIAGNÓSTICO COMPLETADO ===');
}

testFarmadon().catch(console.error);
