const fs = require('fs');
const data = fs.readFileSync('data.json');
const markets = JSON.parse(data)[0].markets;

let sumBestAsk = 0;
let sumPrice0 = 0;
let count = 0;

for(const m of markets) {
  if (m.bestAsk && m.bestAsk > 0 && m.bestAsk < 1 && m.outcomePrices) {
      let price0 = parseFloat(JSON.parse(m.outcomePrices)[0]);
      if (price0 > 0.005) {
          sumBestAsk += m.bestAsk;
          sumPrice0 += price0;
          count++;
      }
  }
}
console.log(`Count: ${count}`);
console.log(`Sum BestAsk: ${sumBestAsk}`);
console.log(`Sum Price0: ${sumPrice0}`);
