const axios = require('axios');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

async function run() {
  try {
    const response = await axios.get(`${supabaseUrl}/rest/v1/`, {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    });
    
    if (response.data.definitions && response.data.definitions.products) {
      console.log('Products columns/properties:');
      console.log(Object.keys(response.data.definitions.products.properties));
    } else {
      console.log('Products definition not found in definitions.');
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}
run();
