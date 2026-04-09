import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Configuración Supabase
const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const POLYMARKET_API = 'https://gamma-api.polymarket.com'
const KALSHI_API = 'https://api.elections.kalshi.com/trade-api/v2'

Deno.serve(async () => {
    const startTime = Date.now()
    try {
        console.log("Starting CROSS-EXCHANGE Engine (PM vs Kalshi)...")

        const polyMarkets = await fetchPolymarketMarkets()
        console.log(`Fetched Polymarket: ${polyMarkets.length}`)

        const kalshiMarkets = await fetchKalshiMarkets()
        console.log(`Fetched Kalshi: ${kalshiMarkets.length}`)

        const opportunities = detectCrossPlatform(polyMarkets, kalshiMarkets)
        console.log(`Detected ${opportunities.length} CROSS opportunities (type_b)`)

        if (opportunities.length > 0) {
            const marketsToUpsert = []
            const polyMap = new Map(polyMarkets.map(m => [m.id, m]))
            const kalshiMap = new Map(kalshiMarkets.map(m => [m.id, m]))

            for (const opp of opportunities) {
                const mk1 = polyMap.get(opp.market_id_1)
                const mk2 = kalshiMap.get(opp.market_id_2)
                if (mk1) marketsToUpsert.push(mk1)
                if (mk2) marketsToUpsert.push(mk2)
            }

            const uniqueMarkets = Array.from(new Map(marketsToUpsert.map(m => [m.id, m])).values())
            await upsertMarkets(uniqueMarkets)
        }

        const saved = await saveCrossOpportunities(opportunities)

        const elapsed = Date.now() - startTime
        return new Response(JSON.stringify({
            success: true,
            detected: opportunities.length,
            saved: saved.length,
            elapsed_ms: elapsed
        }), { headers: { 'Content-Type': 'application/json' } })

    } catch (error: any) {
        console.error('Cross-exchange detection failed:', error)
        return new Response(JSON.stringify({ success: false, error: error.message }), { status: 500 })
    }
})

async function fetchPolymarketMarkets() {
    const url = `${POLYMARKET_API}/events?active=true&closed=false&limit=300`
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Gamma API error: ${res.status}`)
    const data = await res.json()
    if (!Array.isArray(data)) return []

    const markets: any[] = []
    for (const event of data) {
        if (!event.markets || !Array.isArray(event.markets)) continue
        for (const m of event.markets) {
            if (!m.conditionId || !m.outcomePrices) continue
            try {
                const prices = JSON.parse(m.outcomePrices)
                if (prices.length < 2) continue

                let buyYes = (typeof m.bestAsk === 'number' && m.bestAsk > 0) ? m.bestAsk : parseFloat(prices[0])
                let buyNo = parseFloat(prices[1])

                if (buyYes < 0.005 || buyYes > 0.995) continue

                markets.push({
                    id: m.conditionId,
                    platform: 'polymarket',
                    title: m.question || event.title || 'Market',
                    category: m.category || event.category || 'other',
                    buy_yes: buyYes,
                    buy_no: buyNo,
                    volume: parseFloat(m.volume || '0'),
                    end_date: m.endDate || event.endDate || null,
                    updated_at: new Date().toISOString(),
                    _event_id: event.id
                })
            } catch (_) { }
        }
    }
    return markets
}

async function fetchKalshiMarkets() {
    // Kalshi limits properly. Using 100 to avoid undefined 'markets' property error.
    const res = await fetch(`${KALSHI_API}/markets?limit=100&status=open`)
    if (!res.ok) return []
    const data = await res.json()
    if (!data.markets) return []

    return data.markets.map((m: any) => ({
        id: `kalshi_${m.ticker}`,
        platform: 'kalshi',
        title: m.title || m.ticker,
        category: m.category || 'other',
        buy_yes: (m.yes_ask && m.yes_ask > 0 && m.yes_ask < 100) ? m.yes_ask / 100 : 0,
        buy_no: (m.no_ask && m.no_ask > 0 && m.no_ask < 100) ? m.no_ask / 100 : 0,
        volume: m.volume || 0,
        end_date: m.close_time || m.expected_expiration_time || null,
        updated_at: new Date().toISOString()
    })).filter((m: any) => m.buy_yes > 0 || m.buy_no > 0)
}

function detectCrossPlatform(poly: any[], kalshi: any[]) {
    const results: any[] = []

    const getWords = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, ' ').split(/\s+/).filter(w => w.length > 3 && w !== 'will' && w !== 'when')

    for (const pm of poly) {
        const pWords = getWords(pm.title)
        if (pWords.length === 0) continue

        for (const km of kalshi) {
            const kWords = getWords(km.title)

            const intersect = pWords.filter(w => kWords.includes(w))

            // Relieve matching rules slightly for demo
            if (intersect.length >= 2) {
                // pm YES + kalshi NO
                if (pm.buy_yes > 0 && km.buy_no > 0) {
                    const sum1 = pm.buy_yes + km.buy_no
                    if (sum1 < 0.985 && sum1 > 0.0) {
                        const delta = (1 - sum1) * 100
                        const extraObj = {
                            pm_id: pm.id, pm_title: pm.title, pm_buy: 'YES', pm_price: pm.buy_yes,
                            ks_id: km.id, ks_title: km.title, ks_buy: 'NO', ks_price: km.buy_no,
                            end_date: pm.end_date || km.end_date || null,
                        }
                        results.push({
                            type: 'type_b',
                            subtype: 'cross_exchange_yn',
                            market_id_1: pm.id,
                            market_id_2: km.id,
                            delta_points: parseFloat(delta.toFixed(2)),
                            category: pm.category,
                            explanation: JSON.stringify(extraObj),
                            detected_at: new Date().toISOString(),
                            is_active: true,
                            delta_history: []
                        })
                        continue
                    }
                }

                // kalshi YES + pm NO
                if (km.buy_yes > 0 && pm.buy_no > 0) {
                    const sum2 = km.buy_yes + pm.buy_no
                    if (sum2 < 0.985 && sum2 > 0.0) {
                        const delta = (1 - sum2) * 100
                        const extraObj = {
                            pm_id: pm.id, pm_title: pm.title, pm_buy: 'NO', pm_price: pm.buy_no,
                            ks_id: km.id, ks_title: km.title, ks_buy: 'YES', ks_price: km.buy_yes,
                            end_date: pm.end_date || km.end_date || null,
                        }
                        results.push({
                            type: 'type_b',
                            subtype: 'cross_exchange_en',
                            market_id_1: pm.id,
                            market_id_2: km.id,
                            delta_points: parseFloat(delta.toFixed(2)),
                            category: pm.category,
                            explanation: JSON.stringify(extraObj),
                            detected_at: new Date().toISOString(),
                            is_active: true,
                            delta_history: []
                        })
                    }
                }
            }
        }
    }

    results.sort((a, b) => b.delta_points - a.delta_points)

    // Deduplicate: keep only the best opportunity per Polymarket market
    const seen = new Set<string>()
    const unique = results.filter(r => {
        if (seen.has(r.market_id_1)) return false
        seen.add(r.market_id_1)
        return true
    })

    return unique.slice(0, 20)
}

async function upsertMarkets(markets: any[]) {
    const chunkOptions = markets.map(m => ({
        id: m.id,
        platform: m.platform,
        title: m.title,
        category: m.category,
        prob_yes: m.buy_yes,
        prob_no: m.buy_no,
        volume: m.volume,
        end_date: m.end_date || null,
        updated_at: m.updated_at
    }))

    // Solo actualizamos de 100 en 100 max
    const { error } = await supabase.from('markets').upsert(chunkOptions)
    if (error) console.error('Upsert markets error:', error.message)
}

async function saveCrossOpportunities(detected: any[]) {
    await supabase.from('opportunities').delete().eq('type', 'type_b')
    if (detected.length === 0) return []

    const saved = []
    for (const item of detected) {
        const { data, error } = await supabase.from('opportunities').insert(item).select()
        if (error) {
            console.error(`Cross insert FAIL for ${item.market_id_1}:`, error.message)
        } else if (data) {
            saved.push(...data)
        }
    }
    return saved
}
