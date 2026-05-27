require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function uploadAndInsert() {
  console.log('=== UPLOADING BUILD 50 (64-bit arm64-v8a) TO SUPABASE ===');
  
  const apkPath = path.join(__dirname, '..', 'FarmaCompareV-1.0.0+50.apk');
  const bucketName = 'apk';
  const remoteFileName = 'farmacompare-v1.0.0-build50.apk';
  
  console.log(`Checking file existence at: ${apkPath}`);
  if (!fs.existsSync(apkPath)) {
    throw new Error(`File not found at ${apkPath}. Please make sure compilation and copy succeeded first.`);
  }
  
  const fileBuffer = fs.readFileSync(apkPath);
  console.log(`Uploading ${remoteFileName} (${(fileBuffer.length / (1024 * 1024)).toFixed(2)} MB) to Supabase Storage bucket "${bucketName}"...`);
  
  const { data: uploadData, error: uploadError } = await supabase.storage
    .from(bucketName)
    .upload(remoteFileName, fileBuffer, {
      contentType: 'application/vnd.android.package-archive',
      upsert: true
    });
    
  if (uploadError) {
    throw new Error(`Upload error: ${uploadError.message}`);
  }
  
  console.log('Upload successful! Path:', uploadData.path);
  
  const publicUrl = `${process.env.SUPABASE_URL}/storage/v1/object/public/${bucketName}/${remoteFileName}`;
  console.log('Public URL:', publicUrl);
  
  console.log('Inserting row into table "app_version"...');
  const { data: insertData, error: insertError } = await supabase
    .from('app_version')
    .insert([
      {
        version_code: 50,
        version_name: '1.0.0',
        apk_url: publicUrl,
        release_notes: 'v1.0.0 (Build 50): Integración de analíticas y reporte diario automático de búsquedas y clics a farmacias en Supabase. Envío automatizado de reportes diarios por correo con Resend. Correcciones generales de rendimiento.',
        force_update: false
      }
    ])
    .select();
    
  if (insertError) {
    throw new Error(`DB Insert error: ${insertError.message}`);
  }
  
  console.log('Row successfully inserted in "app_version":');
  console.log(JSON.stringify(insertData, null, 2));
  console.log('=== PROCESS COMPLETELY COMPLETED! ===');
}

uploadAndInsert().catch(err => {
  console.error('❌ Error in process:', err.message);
  process.exit(1);
});
