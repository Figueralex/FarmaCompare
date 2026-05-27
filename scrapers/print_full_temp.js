const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../temp_search.html');
if (fs.existsSync(filePath)) {
  const content = fs.readFileSync(filePath, 'utf16le');
  console.log('--- FULL CONTENT ---');
  console.log(content);
} else {
  console.log('File does not exist');
}
