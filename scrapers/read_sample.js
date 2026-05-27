const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../temp_search.html');
if (fs.existsSync(filePath)) {
  const buf = fs.readFileSync(filePath);
  console.log('Byte length:', buf.length);
  console.log('First 1000 chars as UTF-8:');
  console.log(buf.toString('utf8').substring(0, 1000));
} else {
  console.log('File does not exist');
}
