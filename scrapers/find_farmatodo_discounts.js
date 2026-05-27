const puppeteer = require('puppeteer');

(async () => {
  console.log('=== SEARCHING FOR FARMATODO DISCOUNTS ===');
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
    
    // Nivea almost always has some discounted products
    const searchUrl = 'https://www.farmatodo.com.ve/buscar?product=nivea';
    console.log('Navigating to:', searchUrl);
    
    await page.goto(searchUrl, { waitUntil: 'load', timeout: 30000 });
    console.log('Page loaded. Waiting 15 seconds for dynamic content...');
    await new Promise(r => setTimeout(r, 15000));
    
    console.log('Analyzing product cards...');
    const cardsData = await page.evaluate(() => {
      const cards = document.querySelectorAll('.product-card--search-layout');
      const results = [];
      
      cards.forEach(card => {
        const nameNode = card.querySelector('.product-image__link');
        const name = nameNode ? (nameNode.getAttribute('title') || '') : '';
        
        // Let's dump all text and tags inside the price box in detail
        const priceBox = card.querySelector('.product-card__price-box');
        if (priceBox) {
          const elements = [];
          priceBox.querySelectorAll('*').forEach(el => {
            elements.push({
              tag: el.tagName,
              classes: Array.from(el.classList).join(' '),
              text: el.innerText || el.textContent || ''
            });
          });
          
          results.push({
            name: name || 'Unknown',
            priceBoxHtml: priceBox.innerHTML,
            elements: elements
          });
        }
      });
      
      return results;
    });
    
    console.log(`Analyzing ${cardsData.length} price boxes:`);
    
    cardsData.forEach((c, idx) => {
      // Check if there are multiple prices or a discount class
      const hasDiscountClass = c.elements.any = c.elements.some(el => 
        el.classes.includes('discount') || 
        el.classes.includes('strike') || 
        el.classes.includes('regular') || 
        el.classes.includes('old') ||
        el.tag === 'DEL'
      );
      
      const hasMultiplePrices = c.elements.filter(el => el.text.includes('Bs') && !el.classes.includes('pum')).length > 1;
      
      if (hasDiscountClass || hasMultiplePrices || idx < 5) {
        console.log(`\n[Product ${idx + 1}]: ${c.name}`);
        console.log('  Price Box elements:');
        c.elements.forEach(el => {
          console.log(`    <${el.tag} class="${el.classes}"> -> "${el.text.trim().replace(/\n/g, ' ')}"`);
        });
        console.log('  Price Box Raw HTML:');
        console.log(`    ${c.priceBoxHtml.replace(/\s+/g, ' ').substring(0, 300)}`);
      }
    });
    
  } catch (error) {
    console.error('Error during test:', error);
  } finally {
    if (browser) {
      await browser.close();
      console.log('Browser closed.');
    }
  }
})();
