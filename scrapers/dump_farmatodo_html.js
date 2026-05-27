const puppeteer = require('puppeteer');

(async () => {
  console.log('=== DUMPING FARMATODO PRODUCT CARD HTML ===');
  let browser;
  try {
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--single-process'
      ]
    });
    
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    await page.setViewport({ width: 1280, height: 800 });
    
    // We can search for 'descuento' to see if there are any discounted items
    const searchUrl = 'https://www.farmatodo.com.ve/buscar?product=oferta';
    console.log('Navigating to:', searchUrl);
    
    await page.goto(searchUrl, { waitUntil: 'load', timeout: 30000 });
    console.log('Waiting 15 seconds for dynamic content...');
    await new Promise(r => setTimeout(r, 15000));
    
    console.log('Extracting product cards...');
    const cards = await page.evaluate(() => {
      const cardNodes = document.querySelectorAll('.product-card--search-layout');
      const data = [];
      
      cardNodes.forEach(card => {
        const nameNode = card.querySelector('.product-image__link');
        const name = nameNode ? (nameNode.getAttribute('title') || '') : '';
        
        // Let's get the entire outerHTML of the price box and any discount badges
        const priceBox = card.querySelector('.product-card__price-box');
        const priceBoxHtml = priceBox ? priceBox.outerHTML : 'NO PRICE BOX';
        
        // Find any badge elements
        const badges = [];
        card.querySelectorAll('*').forEach(el => {
          const classList = Array.from(el.classList).join(' ');
          if (classList.includes('badge') || classList.includes('discount') || classList.includes('promo') || classList.includes('ahorro') || classList.includes('oferta') || classList.includes('descuento')) {
            badges.push({
              tag: el.tagName,
              classes: classList,
              text: el.innerText || el.textContent || ''
            });
          }
        });
        
        data.push({
          name: name || 'Unknown',
          priceBoxHtml: priceBoxHtml,
          badges: badges,
          fullText: card.innerText || card.textContent || ''
        });
      });
      
      return data;
    });
    
    console.log(`Found ${cards.length} cards.`);
    
    cards.forEach((c, idx) => {
      console.log(`\n----------------------------------------`);
      console.log(`[Product ${idx + 1}]: ${c.name}`);
      console.log(`Price Box HTML: ${c.priceBoxHtml}`);
      if (c.badges.length > 0) {
        console.log(`Badges/Discount elements:`);
        c.badges.forEach(b => {
          console.log(`  <${b.tag} class="${b.classes}"> -> "${b.text.trim()}"`);
        });
      }
      console.log(`Full text snippet: ${c.fullText.replace(/\s+/g, ' ').substring(0, 150)}`);
    });
    
  } catch (error) {
    console.error('Error during dump:', error);
  } finally {
    if (browser) {
      await browser.close();
      console.log('Browser closed.');
    }
  }
})();
