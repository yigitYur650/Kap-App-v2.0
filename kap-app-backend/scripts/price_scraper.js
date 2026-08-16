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

async function scrapePrice(query) {
  if (!query) {
    console.log(JSON.stringify({ error: "Query parameter is required" }));
    process.exit(1);
  }

  let browser;
  try {
    const launchOpts = {
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--disable-software-rasterizer',
        '--no-zygote',
        '--single-process'
      ]
    };
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

    await page.waitForSelector('ul#b > li, span.pt_v8, span.pb_v8, b.p_v8', { timeout: 4000 }).catch(() => {});
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
            const titleEl = card.querySelector('h3, .pn_v8, a.p-link, .title, strong');
            const priceEl = card.querySelector('.pt_v8, .pb_v8, .p_v8, .price, span.price') || card;
            
            const titleText = titleEl ? titleEl.innerText.trim() : '';
            const priceText = priceEl ? priceEl.innerText.trim() : '';

            const m = priceText.match(/(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:TL|₺)?/i);
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
          }

          // Strategy 2: Fallback direct price element scan if cards didn't yield prices
          if (allPrices.length === 0) {
            const priceEls = Array.from(document.querySelectorAll('span.pt_v8, span.pb_v8, b.p_v8, span.price, div.price, span.prc'));
            for (const el of priceEls) {
              const txt = el.innerText.trim();
              const m = txt.match(/(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:TL|₺)?/i);
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
            }
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
