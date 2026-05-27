const puppeteer = require('puppeteer');

(async () => {
  console.log('=== FINDING PERCENTAGE LOCATION ===');
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
    
    const elementData = await page.evaluate(() => {
      const cards = document.querySelectorAll('.product-card--search-layout');
      for (let card of cards) {
        const text = card.innerText || card.textContent || '';
        if (text.includes('¡Aprovecha!') || text.includes('%')) {
          // Let's find every element inside this card and its text to see where the percentage is
          const elements = [];
          card.querySelectorAll('*').forEach(el => {
            const t = (el.innerText || el.textContent || '').trim();
            if (t.includes('%') || t.includes('Aprovecha')) {
              elements.push({
                tag: el.tagName,
                classes: Array.from(el.classList).join(' '),
                text: t,
                html: el.outerHTML.substring(0, 200)
              });
            }
          });
          return {
            name: card.querySelector('.product-image__link')?.getAttribute('title') || 'Unknown',
            elements: elements
          };
        }
      }
      return null;
    });
    
    if (elementData) {
      console.log(`\nProduct: ${elementData.name}`);
      console.log('Elements containing % or Aprovecha:');
      elementData.elements.forEach((el, idx) => {
        console.log(`\n  [Element ${idx+1}]: <${el.tag} class="${el.classes}">`);
        console.log(`    Text: "${el.text.replace(/\n/g, ' ')}"`);
        console.log(`    HTML: ${el.html}`);
      });
    } else {
      console.log('No elements found.');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (browser) {
      browser.close();
      console.log('Browser closed.');
    }
  }
})();
