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
    const searchUrl = `https://www.akakce.com/arama/?q=${encodeURIComponent(query)}`;
    
    try {
      await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 7000 });
      await page.waitForTimeout(1000);
    } catch (e) {
      // Continue even if navigation timeout occurs
    }

    // Wait for network to settle so redirects finish
    await page.waitForLoadState('domcontentloaded').catch(() => {});

    const { items, rawPrices } = await page.evaluate(() => {
      const cards = Array.from(document.querySelectorAll('li.p-card, div.p-card, ul#b > li, div.prc-box, .p_v8, span.pb_v8, span.pt_v8, b.p_v8'));
      const parsedItems = [];
      const allPrices = [];
      const priceRegex = /(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:TL|₺)/i;

      for (const card of cards) {
        const titleEl = card.querySelector('h3, .pn_v8, a.p-link, .title, strong');
        const priceEl = card.querySelector('.pt_v8, .pb_v8, .p_v8, .price, span.price') || card;
        
        const titleText = titleEl ? titleEl.innerText.trim() : '';
        const priceText = priceEl ? priceEl.innerText.trim() : '';

        const match = priceText.match(priceRegex);
        if (match) {
          const val = parseFloat(match[1].replace(',', '.'));
          if (!isNaN(val) && val >= 5.0 && val <= 3500.0) {
            allPrices.push(val);
            if (titleText) {
              parsedItems.push({ title: titleText, price: val });
            }
          }
        }
      }

      return { items: parsedItems, rawPrices: allPrices };
    });

    await browser.close();

    if (!rawPrices || rawPrices.length === 0) {
      console.log(JSON.stringify({ error: "No prices found for query: " + query }));
      process.exit(0);
    }

    // Sort prices and filter out upper/lower 15% outliers
    rawPrices.sort((a, b) => a - b);
    let filteredPrices = rawPrices;
    if (rawPrices.length >= 4) {
      const cut = Math.floor(rawPrices.length * 0.15);
      filteredPrices = rawPrices.slice(cut, rawPrices.length - cut);
    }

    let minPrice = filteredPrices[0];
    let maxPrice = filteredPrices[0];
    let sum = 0;

    for (const p of filteredPrices) {
      if (p < minPrice) minPrice = p;
      if (p > maxPrice) maxPrice = p;
      sum += p;
    }

    const avgPrice = Math.round((sum / filteredPrices.length) * 100) / 100;

    const stores = [];
    const storeKeywords = ['MİGROS', 'A101', 'BİM', 'ŞOK', 'CARREFOUR', 'TRENDYOL', 'GETİR'];
    for (const item of items) {
      const upper = item.title.toUpperCase();
      for (const kw of storeKeywords) {
        if (upper.includes(kw) && !stores.some(s => s.store === kw)) {
          stores.push({ store: kw, price: item.price });
        }
      }
    }

    const result = {
      item_name: query,
      estimated_price: avgPrice,
      min_price: Math.round(minPrice * 100) / 100,
      max_price: Math.round(maxPrice * 100) / 100,
      stores: stores.slice(0, 4),
      source: "Playwright Targeted Scraper"
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

scrapePrice(query || 'Ekmek');
