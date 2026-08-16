const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

const envPath = path.join(__dirname, '../../.env');
let geminiKey = '';
let groqKey = '';

if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  for (const line of envContent.split('\n')) {
    if (line.startsWith('GEMINI_API_KEY=')) geminiKey = line.split('=')[1].trim();
    if (line.startsWith('GROQ_API_KEY=')) groqKey = line.split('=')[1].trim();
  }
}

const items = ["Beyaz Peynir", "Tavuk Göğsü", "Süt", "Ekmek", "Bulgur", "tereyağı", "kepek ekmeği", "kıvırcık", "fındık", "mercimek", "brokoli"];

const prompt = `Sen 2026 yılı GÜNCEL Türkiye zincir marketi MİGROS, BİM ve A101 TEKİL PERAKENDE RAF ETİKET FİYATI UZMANISIN.

2026 TÜRKİYE GÜNCEL KESİN ZİNCİR MARKET (MİGROS / BİM / A101) REFERANS RAF FİYATLARI:
- Beyaz Peynir (500g Tam Yağlı): 145.00 TL (Migros)
- Tavuk Göğsü (1 kg Piliç Göğüs): 195.00 TL (BİM / Migros)
- Süt (1L Tam Yağlı): 39.50 TL (Migros / BİM)
- Ekmek (200g Somun): 12.50 TL (Fırın / BİM)
- Kepek Ekmeği (400g Paket): 22.50 TL (Migros)
- Bulgur (1 kg Pilavlık/Köy): 38.00 TL (Migros / BİM)
- Tereyağı (500g Tuzsuz/Tuzlu): 245.00 TL (Migros / BİM)
- Kıvırcık / Marul (1 Adet): 35.00 TL (Migros)
- Fındık (500g Kavrulmuş): 185.00 TL (A101)
- Mercimek (1 kg Kırmızı/Yeşil): 42.50 TL (BİM)
- Brokoli (1 kg Taze): 45.00 TL (Migros)
- Dana Kıyma (1 kg): 520.00 TL (Migros)
- Cips (130g Parti Boy): 45.00 TL (Migros)
- Yumurta (15'li L Boy): 89.50 TL (A101 / BİM)

KURALLAR:
1. YUKARIDAKİ 2026 REFERANS FİYATLARINI %%100 ESAS AL (Örn: 1 kg Tavuk Göğsü = 195 TL, 1L Süt = 39.50 TL, 1kg Bulgur = 38 TL, 500g Tereyağı = 245 TL).
2. ASLA 2021/2022 ESKİ FİYATLARINI (15 TL süt, 40 TL tavuk) KULLANMA.
3. EĞER MİKTAR BELİRTİLMİŞSE (Örn: 2 kg tavuk), BİRİM FİYAT X MİKTAR HESAPLA.

İstenen Ürünler: ${items.join(', ')}

Sadece aşağıdaki JSON formatında yanıt ver:
{
  "items": [
    {
      "item_name": "ürün adı",
      "brand": "marka adı",
      "estimated_price": 0.0,
      "min_price": 0.0,
      "max_price": 0.0,
      "unit_spec": "Miktar / Paket Bilgisi",
      "source_market": "Migros / BİM / A101"
    }
  ]
}`;

function testGroq() {
  return new Promise((resolve) => {
    const data = JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.1,
      response_format: { type: "json_object" }
    });

    const req = https.request('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${groqKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          const content = json.choices[0].message.content;
          resolve(JSON.parse(content));
        } catch (e) {
          resolve({ error: e.message, raw: body });
        }
      });
    });
    req.write(data);
    req.end();
  });
}

function testGemini() {
  return new Promise((resolve) => {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`;
    const data = JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: "application/json"
      }
    });

    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          const content = json.candidates[0].content.parts[0].text;
          resolve(JSON.parse(content));
        } catch (e) {
          resolve({ error: e.message, raw: body });
        }
      });
    });
    req.write(data);
    req.end();
  });
}

async function runBenchmark() {
  console.log("=================================================================");
  console.log("⚔️ GROQ AI (Llama 3.3 70B) vs GEMINI 2.0 FLASH KARŞILAŞTIRMA TESTİ");
  console.log("=================================================================\n");

  const groqRes = await testGroq();
  const geminiRes = await testGemini();

  console.log("-----------------------------------------------------------------");
  console.log("🤖 GROQ AI (Llama 3.3 70B) SONUÇLARI:");
  console.log("-----------------------------------------------------------------");
  if (groqRes.items) {
    groqRes.items.forEach(it => {
      console.log(`• ${it.item_name.padEnd(16)} | Tahmini: ${(it.estimated_price + " TL").padEnd(10)} | Paket: ${(it.unit_spec || '-').padEnd(20)} | Market: ${it.source_market || '-'}`);
    });
  } else {
    console.log(groqRes);
  }

  console.log("\n-----------------------------------------------------------------");
  console.log("✨ GEMINI 2.0 FLASH SONUÇLARI:");
  console.log("-----------------------------------------------------------------");
  if (geminiRes.items) {
    geminiRes.items.forEach(it => {
      console.log(`• ${it.item_name.padEnd(16)} | Tahmini: ${(it.estimated_price + " TL").padEnd(10)} | Paket: ${(it.unit_spec || '-').padEnd(20)} | Market: ${it.source_market || '-'}`);
    });
  } else {
    console.log(geminiRes);
  }
}

runBenchmark();
