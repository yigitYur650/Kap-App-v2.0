const path = require('path');
let chromium;
try {
  chromium = require('playwright').chromium;
} catch (e1) {
  try {
    chromium = require(path.join(__dirname, '../node_modules/playwright')).chromium;
  } catch (e2) {
    try {
      chromium = require(path.join(__dirname, '../../kap-app-front/node_modules/playwright')).chromium;
    } catch (e3) {
      console.log(JSON.stringify({ error: "Playwright module missing: " + e1.message }));
      process.exit(1);
    }
  }
}

process.on('uncaughtException', (err) => {
  console.log(JSON.stringify({ error: "Uncaught Exception: " + err.message }));
  process.exit(0);
});
process.on('unhandledRejection', (reason) => {
  console.log(JSON.stringify({ error: "Unhandled Rejection: " + (reason ? reason.message || reason : "Unknown") }));
  process.exit(0);
});

async function scrapePrice(query) {
  if (!query) {
    console.log(JSON.stringify({ error: "Query parameter is required" }));
    process.exit(1);
  }

  let browser;
  try {
    const launchOpts = {
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    };
    if (process.platform === 'linux') {
      launchOpts.args.push('--disable-gpu', '--disable-software-rasterizer', '--no-zygote');
    }
    if (process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH) {
      launchOpts.executablePath = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH;
    }
    browser = await chromium.launch(launchOpts);

    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      locale: 'tr-TR',
      extraHTTPHeaders: {
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Sec-Ch-Ua': '"Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"Windows"'
      }
    });

    await context.addInitScript(() => {
      Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    });

    const page = await context.newPage();
    const searchUrl = `https://www.akakce.com/arama/?q=${encodeURIComponent(query)}`;
    
    const sleep = ms => new Promise(res => setTimeout(res, ms));

    try {
      await page.goto(searchUrl, { 
        waitUntil: 'domcontentloaded', 
        timeout: 8000,
        referer: 'https://www.akakce.com/'
      });
    } catch (e) {
      // Continue even if navigation timeout occurs
    }

    // 1. Event-based DOM attach listener (Event-driven Playwright wait)
    await page.waitForSelector('ul#b > li, span.pt_v8, span.pb_v8, b.p_v8', { state: 'attached', timeout: 4000 }).catch(() => {});
    // 2. Safety margin micro-pause (200ms sleep for innerText stabilization)
    await sleep(200);

    let itemsData = { items: [], rawPrices: [] };
    for (let attempt = 0; attempt < 2; attempt++) {
      if (page.isClosed()) break;
      try {
        itemsData = await page.evaluate(() => {
          const parsedItems = [];
          const allPrices = [];

          // Strategy 1: Target product list cards
          const cards = Array.from(document.querySelectorAll('ul#b > li, li.p-card, div.p-card, div.prc-box'));
          for (const card of cards) {
            try {
              const titleEl = card.querySelector('h3, .pn_v8, a.p-link, .title, strong');
              const priceEl = card.querySelector('.pt_v8, .pb_v8, .p_v8, .price, span.price') || card;
              
              const titleText = titleEl ? (titleEl.innerText || '').trim() : '';
              const priceText = priceEl ? (priceEl.innerText || '').trim() : '';

              const m = priceText.match(/(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:TL|₺)/i);
              if (m) {
                let valStr = m[1];
                if (valStr.includes(',')) {
                  valStr = valStr.replace(/\./g, '').replace(',', '.');
                }
                const val = parseFloat(valStr);
                if (!isNaN(val) && val >= 5.0 && val <= 3500.0) {
                  allPrices.push(val);
                  if (titleText) {
                    parsedItems.push({ title: titleText, price: val });
                  }
                }
              }
            } catch (_) {}
          }

          // Strategy 2: Scan direct price elements to ensure maximum sample size
          const priceEls = Array.from(document.querySelectorAll('span.pt_v8, span.pb_v8, b.p_v8, span.price, div.price, span.prc, .p_v8'));
          for (const el of priceEls) {
            try {
              const txt = (el.innerText || '').trim();
              const m = txt.match(/(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:TL|₺)/i);
              if (m) {
                let valStr = m[1];
                if (valStr.includes(',')) {
                  valStr = valStr.replace(/\./g, '').replace(',', '.');
                }
                const val = parseFloat(valStr);
                if (!isNaN(val) && val >= 5.0 && val <= 3500.0) {
                  allPrices.push(val);
                }
              }
            } catch (_) {}
          }

          return { items: parsedItems, rawPrices: allPrices };
        });
        if (itemsData && itemsData.rawPrices && itemsData.rawPrices.length > 0) {
          break;
        }
      } catch (evalErr) {
        await sleep(500);
      }
    }
    const { items, rawPrices } = itemsData;

    await browser.close();

    if (!rawPrices || rawPrices.length === 0) {
      console.log(JSON.stringify({ error: "No prices found for query: " + query }));
      process.exit(0);
    }

    // Sort prices ascending
    rawPrices.sort((a, b) => a - b);
    let filteredPrices = rawPrices;
    if (rawPrices.length >= 4) {
      const cut = Math.floor(rawPrices.length * 0.10);
      filteredPrices = rawPrices.slice(cut, rawPrices.length - cut);
    }

    let minPrice = filteredPrices[0];
    let maxPrice = filteredPrices[filteredPrices.length - 1];

    // Priority 1: Check if there's a direct chain market match (Migros, BİM, A101, Şok, Carrefour)
    const stores = [];
    const storeKeywords = ['MİGROS', 'A101', 'BİM', 'ŞOK', 'CARREFOUR', 'TRENDYOL', 'GETİR'];
    let chainStorePrice = 0;

    for (const item of items) {
      const upper = item.title.toUpperCase();
      for (const kw of storeKeywords) {
        if (upper.includes(kw)) {
          if (!stores.some(s => s.store === kw)) {
            stores.push({ store: kw, price: item.price });
          }
          if (chainStorePrice === 0 && item.price >= 5.0 && item.price <= 2500.0) {
            chainStorePrice = item.price;
          }
        }
      }
    }

    // Priority 2: Use 30th percentile median price for standard retail grocery unit (e.g. 1kg chicken, 1L milk, 130g chips)
    // 30th percentile accurately represents standard single retail unit shelf price rather than bulk 5kg restaurant packages
    const retailIndex = Math.floor(filteredPrices.length * 0.30);
    const retailMedianPrice = filteredPrices[retailIndex] || filteredPrices[0];

    const estimatedPrice = chainStorePrice > 0 ? chainStorePrice : retailMedianPrice;

    const result = {
      item_name: query,
      estimated_price: Math.round(estimatedPrice * 100) / 100,
      min_price: Math.round(minPrice * 100) / 100,
      max_price: Math.round(maxPrice * 100) / 100,
      stores: stores.slice(0, 4),
      source: chainStorePrice > 0 ? "Canlı Zincir Market (Migros/BİM/A101)" : "Canlı Perakende Medyan Fiyatı (Playwright)"
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
