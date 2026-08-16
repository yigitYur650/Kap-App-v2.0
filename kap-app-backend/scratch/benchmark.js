const { execSync } = require('child_process');
const path = require('path');

const queries = ['tavuk', 'cips', 'süt', 'bulgur', 'tavuk göğsü'];
const scriptPath = path.join(__dirname, '../scripts/price_scraper.js');

console.log('===========================================================');
console.log('🚀 PLAYWRIGHT HİBRİT MİMARİ YEREL PERFORMANS VE VERİ TESTİ');
console.log('===========================================================\n');

for (const q of queries) {
  const start = Date.now();
  try {
    const cmd = `node "${scriptPath}" "--query=${q}"`;
    const output = execSync(cmd).toString().trim();
    const duration = Date.now() - start;
    const json = JSON.parse(output);

    if (json.error) {
      console.log(`❌ [${q.toUpperCase()}] Sonuç (Süre: ${duration} ms / ${(duration/1000).toFixed(2)}s):`);
      console.log(`   Mesaj: ${json.error}`);
    } else {
      console.log(`✅ [${q.toUpperCase()}] BAŞARILI (Süre: ${duration} ms / ${(duration/1000).toFixed(2)}s):`);
      console.log(`   Ortalama Piyasa Fiyatı: ${json.estimated_price} TL`);
      console.log(`   En Düşük: ${json.min_price} TL | En Yüksek: ${json.max_price} TL`);
      console.log(`   Kaynak: ${json.source}`);
    }
  } catch (err) {
    const duration = Date.now() - start;
    console.log(`❌ [${q.toUpperCase()}] Hata (${duration} ms): ${err.message}`);
  }
  console.log('-----------------------------------------------------------');
}
