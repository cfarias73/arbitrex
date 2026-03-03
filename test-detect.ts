const POLYMARKET_API = 'https://gamma-api.polymarket.com'
async function fetchPolymarketMarkets() {
  const url = `${POLYMARKET_API}/events?slug=presidential-election-winner-2028`
  const res = await fetch(url)
  const data = await res.json()

  const markets: any[] = []
  for (const event of data) {
    if (!event.markets || !Array.isArray(event.markets)) continue

    for (const m of event.markets) {
      if (!m.conditionId) continue

      let probYes = 0
      try {
        const prices = JSON.parse(m.outcomePrices || '[]')
        const bestAsk = (typeof m.bestAsk === 'number' && m.bestAsk > 0) ? m.bestAsk : 1.0;
        
        if (prices.length > 0) {
           probYes = (typeof m.bestAsk === 'number' && m.bestAsk > 0) ? m.bestAsk : parseFloat(prices[0] || '1')
        } else {
           probYes = bestAsk
        }
      } catch (_) { 
        probYes = 1.0 
      }

      markets.push({
        id: m.conditionId,
        title: m.question,
        prob_yes: probYes,
        _event_id: event.id || null
      })
    }
  }
  return markets
}

async function test() {
  const mkts = await fetchPolymarketMarkets();
  console.log(`Markets count: ${mkts.length}`)
  let total = mkts.reduce((s, m) => s + m.prob_yes, 0) * 100;
  console.log(`Total exhaustive probability: ${total.toFixed(2)}%`)
}
test()
