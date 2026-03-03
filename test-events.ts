const POLYMARKET_API = 'https://gamma-api.polymarket.com'
async function test() {
  const url = `${POLYMARKET_API}/events?active=true&closed=false&limit=150`
  const res = await fetch(url)
  const data = await res.json()
  console.log(`Fetched ${data.length} events`)
  let count = 0
  for(const e of data) if(e.markets) count += e.markets.length
  console.log(`Total markets in events: ${count}`)
}
test()
