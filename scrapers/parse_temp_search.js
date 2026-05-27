const fs = require('fs');
const path = require('path');

function run() {
  const filePath = path.join(__dirname, '../temp_search.html');
  if (!fs.existsSync(filePath)) {
    console.log('temp_search.html does not exist.');
    return;
  }
  
  // Read specifically as UTF-16LE
  const buf = fs.readFileSync(filePath);
  const content = buf.toString('utf16le');
  
  console.log('File read successfully as UTF-16LE. Length:', content.length);
  
  // Let's print the first 500 characters of the decoded text
  console.log('First 500 characters normalized:');
  console.log(content.substring(0, 500).replace(/\s+/g, ' '));
  
  // Search for price-related terms
  const priceMatches = [...content.matchAll(/class="[^"]*price[^"]*"/gi)].slice(0, 15);
  console.log('\nMatches for class containing "price":');
  priceMatches.forEach((m, idx) => {
    const start = Math.max(0, m.index - 50);
    const end = Math.min(content.length, m.index + 150);
    console.log(`${idx + 1}: ...${content.substring(start, end).replace(/\s+/g, ' ')}...`);
  });

  // Search for price values, like 'Bs'
  const bsMatches = [...content.matchAll(/Bs[^\d]{0,5}\d+/gi)].slice(0, 10);
  console.log('\nMatches for "Bs":');
  bsMatches.forEach((m, idx) => {
    const start = Math.max(0, m.index - 50);
    const end = Math.min(content.length, m.index + 150);
    console.log(`${idx + 1}: ...${content.substring(start, end).replace(/\s+/g, ' ')}...`);
  });
}
run();
