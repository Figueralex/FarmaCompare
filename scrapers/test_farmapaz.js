const axios = require('axios');

function stripHtml(html) {
  return html.replace(/<[^>]+>/g, '').trim();
}

function decodeHtmlEntities(text) {
  return text
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/&#38;/g, '&')
    .replace(/&#36;/g, '$')
    .replace(/&#038;/g, '&');
}

function parseEuropeanPrice(text) {
  const cleaned = text.replace(/[^\d.,]/g, '');
  if (!cleaned) return 0.0;
  if (cleaned.includes(',')) {
    const normalized = cleaned.replace(/\./g, '').replace(/,/g, '.');
    return parseFloat(normalized) || 0.0;
  }
  const parts = cleaned.split('.');
  if (parts.length - 1 === 1) {
    if (parts[1].length <= 2) {
      return parseFloat(cleaned) || 0.0;
    }
    return parseFloat(cleaned.replace(/\./g, '')) || 0.0;
  }
  if (parts.length - 1 > 1) {
    return parseFloat(cleaned.replace(/\./g, '')) || 0.0;
  }
  return parseFloat(cleaned) || 0.0;
}

async function testFarmapaz() {
  console.log('=== TEST FARMAPAZ PARSER ===\n');
  
  const searchUrl = 'https://farmapazvenezuela.com/?s=acetaminofen&post_type=product&wmc-currency=USD';
  console.log('GET:', searchUrl);
  
  try {
    const resp = await axios.get(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-VE,es;q=0.9,en;q=0.8',
      },
      timeout: 60000,
    });
    
    const html = resp.data;
    console.log('Status:', resp.status);
    
    // We will find all blocks starting with `<div class="post-image post-media overlay-hover">`
    // and grab content until the next card or end of products
    const productBlocks = [];
    const blockStartRegex = /<div class="post-image post-media overlay-hover">/g;
    let match;
    const indexes = [];
    while ((match = blockStartRegex.exec(html)) !== null) {
      indexes.push(match.index);
    }
    
    console.log(`Found ${indexes.length} product card starts.`);
    
    for (let i = 0; i < indexes.length; i++) {
      const start = indexes[i];
      // End is either the next product card start, or index + 4000 characters
      const end = (i < indexes.length - 1) ? indexes[i+1] : start + 4000;
      const block = html.substring(start, end);
      productBlocks.push(block);
    }
    
    const products = [];
    
    productBlocks.forEach((block, idx) => {
      try {
        // 1. Extract product URL
        // Format: href="https://farmapazvenezuela.com/product/SLUG/"
        const urlMatch = block.match(/href="(https:\/\/farmapazvenezuela\.com\/product\/[^"]+)"/i);
        if (!urlMatch) return;
        const productUrl = urlMatch[1];
        
        // 2. Extract image URL
        const imgMatch = block.match(/<img[^>]*src="([^"]+)"/i);
        const imageUrl = imgMatch ? imgMatch[1] : '';
        
        // 3. Extract name
        const nameMatch = block.match(/<h4 class="post-title[^"]*"><a[^>]*>(.*?)<\/a><\/h4>/i);
        if (!nameMatch) return;
        const name = decodeHtmlEntities(stripHtml(nameMatch[1]));
        
        // 4. Extract price (either USD directly, or using data-wmc_price_cache if available)
        let priceUsd = 0.0;
        
        // Strategy A: data-wmc_price_cache
        const cacheMatch = block.match(/data-wmc_price_cache="([^"]+)"/i);
        if (cacheMatch) {
          const rawCache = decodeHtmlEntities(cacheMatch[1]);
          try {
            // It's a JSON string. Since we decoded html entities, it should be valid JSON
            const cache = JSON.parse(rawCache);
            if (cache.USD) {
              const usdHtml = cache.USD;
              const usdText = stripHtml(usdHtml);
              priceUsd = parseEuropeanPrice(usdText);
            }
          } catch (e) {
            // If JSON.parse fails, try regex on cache string
            const usdField = rawCache.match(/"USD"\s*:\s*"(.*?)"/);
            if (usdField) {
              const usdHtml = usdField[1];
              const usdText = stripHtml(usdHtml);
              priceUsd = parseEuropeanPrice(usdText);
            }
          }
        }
        
        // Strategy B: Fallback to woocommerce-Price-amount (if displayed in USD)
        if (priceUsd <= 0.0) {
          const priceSpanMatch = block.match(/class="woocommerce-Price-amount amount">([\s\S]*?)<\/span>/i);
          if (priceSpanMatch) {
            const priceText = stripHtml(priceSpanMatch[1]);
            priceUsd = parseEuropeanPrice(priceText);
          }
        }
        
        products.push({
          index: idx + 1,
          name,
          priceUsd,
          imageUrl,
          productUrl
        });
      } catch (err) {
        console.error(`Error parsing card ${idx+1}:`, err.message);
      }
    });
    
    console.log(`\nSuccessfully parsed ${products.length} products:`);
    products.forEach(p => {
      console.log(`[${p.index}] ${p.name}`);
      console.log(`    Price USD: ${p.priceUsd}`);
      console.log(`    Image:     ${p.imageUrl}`);
      console.log(`    Link:      ${p.productUrl}\n`);
    });
    
  } catch (e) {
    console.error('Error fetching page:', e.message);
  }
}

testFarmapaz();
