const puppeteer = require('puppeteer');

(async () => {
  console.log('=== DUMPING ALL DISCOUNTED CARDS HTML ===');
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
    
    const cards = await page.evaluate(() => {
      const results = [];
      const cardNodes = document.querySelectorAll('.product-card--search-layout');
      
      cardNodes.forEach(card => {
        const text = card.innerText || card.textContent || '';
        if (text.includes('¡Aprovecha!') || text.includes('%') || text.includes('Dcto')) {
          results.push({
            name: card.querySelector('.product-image__link')?.getAttribute('title') || 'Unknown',
            text: text.substring(0, 200),
            outerHTML: card.outerHTML
          });
        }
      });
      return results;
    });
    
    console.log(`Found ${cards.length} discounted cards.`);
    cards.forEach((c, idx) => {
      console.log(`\n========================================`);
      console.log(`[Card ${idx + 1}]: ${c.name}`);
      console.log(`Text: "${c.text.replace(/\n/g, ' ')}"`);
      console.log(`-----------------------------`);
      console.log(c.outerHTML);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (browser) {
      await browser.close();
      console.log('Browser closed.');
    }
  }
})();
