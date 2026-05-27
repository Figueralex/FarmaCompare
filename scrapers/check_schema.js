require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('Fetching a single product to inspect its columns...');
  const { data, error } = await supabase.from('products').select().limit(1);
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Single product data:', data[0]);
  }
}
run();
