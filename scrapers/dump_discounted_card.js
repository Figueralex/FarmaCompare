const puppeteer = require('puppeteer');

(async () => {
  console.log('=== DUMPING FULL DISCOUNTED CARD HTML ===');
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
    
    const searchUrl = 'https://www.farmatodo.com.ve/buscar?product=oferta';
    console.log('Navigating to:', searchUrl);
    
    await page.goto(searchUrl, { waitUntil: 'load', timeout: 30000 });
    console.log('Waiting 15 seconds for dynamic content...');
    await new Promise(r => setTimeout(r, 15000));
    
    const cardHtml = await page.evaluate(() => {
      const cards = document.querySelectorAll('.product-card--search-layout');
      for (let card of cards) {
        const text = card.innerText || card.textContent || '';
        if (text.includes('¡Aprovecha!') || text.includes('Dcto.') || text.includes('%')) {
          return {
            name: card.querySelector('.product-image__link')?.getAttribute('title') || 'Unknown',
            outerHTML: card.outerHTML
          };
        }
      }
      return null;
    });
    
    if (cardHtml) {
      console.log(`\nFound discounted product: ${cardHtml.name}`);
      console.log(`========================================`);
      console.log(cardHtml.outerHTML);
      console.log(`========================================`);
    } else {
      console.log('No discounted products found in search results.');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (browser) {
      await browser.close();
      console.log('Browser closed.');
    }
  }
})();
