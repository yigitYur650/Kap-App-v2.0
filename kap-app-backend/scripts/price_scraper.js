const path = require('path');
const { chromium } = require(path.join(__dirname, '../../kap-app-front/node_modules/playwright'));

async function scrapePrice(query) {
  if (!query) {
    console.log(JSON.stringify({ error: "Query parameter is required" }));
    process.exit(1);
  }

  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });

    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      locale: 'tr-TR'
    });

    const page = await context.newPage();
    const searchUrl = `https://www.akakce.com/arama/?q=${encodeURIComponent(query + ' fiyati')}`;
    
    try {
      await page.goto(searchUrl, { waitUntil: 'commit', timeout: 5000 });
      await page.waitForTimeout(1500);
    } catch (e) {
      // Continue even if navigation timeout occurs
    }

    const { priceTexts, storeBreakdown } = await page.evaluate(() => {
      const elements = Array.from(document.querySelectorAll('span, td, div, p, b, strong, li, a'));
      const found = [];
      const stores = [];
      const priceRegex = /(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:TL|₺)/gi;
      const storeKeywords = ['migros', 'carrefour', 'a101', 'bim', 'sok', 'trendyol', 'hepsiburada', 'n11', 'getir'];

      for (const el of elements) {
        const text = el.innerText || el.textContent || '';
        let match;
        while ((match = priceRegex.exec(text)) !== null) {
          const val = parseFloat(match[1].replace(',', '.'));
          if (!isNaN(val) && val >= 5.0 && val <= 4000.0) {
            found.push(val);

            // Check if element or parent mentions a store name
            const lowerText = text.toLowerCase();
            for (const kw of storeKeywords) {
              if (lowerText.includes(kw)) {
                const storeName = kw.toUpperCase();
                if (!stores.some(s => s.store === storeName)) {
                  stores.push({ store: storeName, price: val });
                }
              }
            }
          }
        }
      }
      return { priceTexts: found, storeBreakdown: stores };
    });

    await browser.close();

    if (!priceTexts || priceTexts.length === 0) {
      console.log(JSON.stringify({ error: "No prices found for query: " + query }));
      process.exit(0);
    }

    let minPrice = priceTexts[0];
    let maxPrice = priceTexts[0];
    let sum = 0;

    for (const p of priceTexts) {
      if (p < minPrice) minPrice = p;
      if (p > maxPrice) maxPrice = p;
      sum += p;
    }

    const avgPrice = Math.round((sum / priceTexts.length) * 100) / 100;

    const result = {
      item_name: query,
      estimated_price: avgPrice,
      min_price: Math.round(minPrice * 100) / 100,
      max_price: Math.round(maxPrice * 100) / 100,
      stores: storeBreakdown.slice(0, 4),
      source: "Playwright Live Scraper"
    };

    console.log(JSON.stringify(result));
  } catch (err) {
    if (browser) await browser.close().catch(() => {});
    console.log(JSON.stringify({ error: err.message }));
  }
}

const args = process.argv.slice(2);
let query = '';
for (const arg of args) {
  if (arg.startsWith('--query=')) {
    query = arg.split('=')[1].replace(/^"|"$/g, '');
  }
}

if (!query && args.length > 0) {
  query = args[0];
}

scrapePrice(query || 'Süt 1L');
