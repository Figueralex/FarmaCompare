const puppeteer = require('puppeteer');

(async () => {
  console.log('=== STARTING FARMATODO SCRAPING TEST ===');
  let browser;
  try {
    console.log('Launching Puppeteer browser...');
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--single-process'
      ]
    });
    
    const page = await browser.newPage();
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    await page.setViewport({ width: 1280, height: 800 });
    
    const searchUrl = 'https://www.farmatodo.com.ve/buscar?product=ofertas';
    console.log('Navigating to:', searchUrl);
    
    await page.goto(searchUrl, { waitUntil: 'load', timeout: 30000 });
    console.log('Page loaded. Waiting 15 seconds for Angular/dynamic content to compile...');
    await new Promise(r => setTimeout(r, 15000));
    
    console.log('Extracting product cards...');
    const cardsData = await page.evaluate(() => {
      const cards = document.querySelectorAll('.product-card--search-layout');
      const results = [];
      
      for (let i = 0; i < Math.min(cards.length, 10); i++) {
        const card = cards[i];
        
        // Extract basic details
        const imgLink = card.querySelector('.product-image__link');
        const name = imgLink ? (imgLink.getAttribute('title') || '') : '';
        
        // Extract price elements HTML
        const priceNodes = card.querySelectorAll('*');
        const priceInfo = [];
        priceNodes.forEach(node => {
          const classList = Array.from(node.classList).join(' ');
          const text = (node.innerText || node.textContent || '').trim();
          if (text && (classList.includes('price') || classList.includes('discount') || classList.includes('strike') || node.tagName === 'DEL' || text.includes('Bs'))) {
            priceInfo.push({
              tag: node.tagName,
              classes: classList,
              text: text
            });
          }
        });
        
        results.push({
          name: name || card.innerText.substring(0, 50),
          htmlSample: card.innerHTML.substring(0, 1000),
          priceNodes: priceInfo
        });
      }
      
      return results;
    });
    
    console.log(`Found ${cardsData.length} cards.`);
    if (cardsData.length === 0) {
      console.log('No cards found. Dumping page text:');
      const text = await page.evaluate(() => document.body.innerText.substring(0, 1000));
      console.log(text);
    } else {
      cardsData.forEach((c, idx) => {
        console.log(`\n[Card ${idx + 1}] Name: ${c.name}`);
        console.log('Price elements found:');
        c.priceNodes.forEach(pn => {
          console.log(`  <${pn.tag} class="${pn.classes}"> -> "${pn.text.replace(/\n/g, ' ')}"`);
        });
      });
    }
    
  } catch (error) {
    console.error('Fatal Error during test:', error);
  } finally {
    if (browser) {
      await browser.close();
      console.log('Browser closed.');
    }
  }
})();
