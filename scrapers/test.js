const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-A205U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.5414.117 Mobile Safari/537.36');
  await page.goto('https://www.farmatodo.com.ve/buscar?product=atamel', {waitUntil: 'networkidle2'});
  await new Promise(r => setTimeout(r, 8000));
  const html = await page.evaluate(() => {
    const cards = document.querySelectorAll('div[class*="product"]');
    return Array.from(cards).map(c => c.className).slice(0, 10).join('\\n');
  });
  console.log('Result: ', html);
  await browser.close();
})();
