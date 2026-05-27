require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function getVersions() {
  console.log('Fetching app_version records from Supabase...');
  const { data, error } = await supabase
    .from('app_version')
    .select()
    .order('version_code', { ascending: false });
    
  if (error) {
    console.error('Error fetching versions:', error.message);
  } else {
    console.log('App Versions found:');
    console.log(JSON.stringify(data, null, 2));
  }
}

getVersions().catch(console.error);
