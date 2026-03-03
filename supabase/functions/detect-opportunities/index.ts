import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const POLYMARKET_API = 'https://gamma-api.polymarket.com'
const MIN_DELTA_STORE = 0.5
const MIN_DELTA_NOTIFY = 5.0

Deno.serve(async () => {
  const startTime = Date.now()

  try {
    const markets = await fetchPolymarketMarkets()
    console.log(`Fetched ${markets.length} liquid markets`)

    if (markets.length > 0) {
      await upsertMarkets(markets)
    }

    const opportunities = [
      ...detectSingleMarketArbitrage(markets),
      ...detectTypeA_Hierarchy(markets),
      ...detectTypeA_Exhaustive(markets),
    ]
    console.log(`Detected ${opportunities.length} raw opportunities`)

    const significant = opportunities.filter(o => o.delta_points >= MIN_DELTA_STORE)
    console.log(`Significant opportunities (>= ${MIN_DELTA_STORE}): ${significant.length}`)

    const saved = await saveOpportunities(significant)
    console.log(`Saved ${saved.length} opportunities to DB`)

    const elapsed = Date.now() - startTime

    // Log the successful run
    await supabase.from('detection_logs').insert({
      markets_fetched: markets.length,
      opportunities_detected: significant.length,
      new_opportunities: saved.length,
      elapsed_ms: elapsed,
      success: true
    })

    return new Response(JSON.stringify({
      success: true,
      markets_fetched: markets.length,
      opportunities_detected: significant.length,
      new_opportunities: saved.length,
      elapsed_ms: elapsed
    }), { headers: { 'Content-Type': 'application/json' } })

  } catch (error: any) {
    console.error('Detection cycle failed:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// ─────────────────────────────────────────
// FETCH MARKETS (Gamma API)
// ─────────────────────────────────────────

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

      let buyYes = 0
      let buyNo = 0
      try {
        const prices = JSON.parse(m.outcomePrices)
        if (prices.length < 2) continue

        // Costo real de comprar YES: priorizamos Best Ask
        buyYes = (typeof m.bestAsk === 'number' && m.bestAsk > 0) ? m.bestAsk : parseFloat(prices[0])

        // Costo real de comprar NO
        buyNo = parseFloat(prices[1])

        // FILTRO CRÍTICO: Ignoramos mercados "muertos" o resueltos (prices cerca de 0 o 1)
        if (buyYes < 0.005 || buyYes > 0.995) continue

        // Filtro de volumen mínimo reducido para captar ineficiencias frescas
        if (parseFloat(m.volume || '0') < 1000) continue

        markets.push({
          id: m.conditionId,
          platform: 'polymarket',
          title: m.question,
          category: m.category || event.category || 'other',
          buy_yes: buyYes,
          buy_no: buyNo,
          volume: parseFloat(m.volume || '0'),
          updated_at: new Date().toISOString(),
          _event_id: event.id
        })
      } catch (_) { continue }
    }
  }

  return markets
}

// ─────────────────────────────────────────
// UPSERT MARKETS (sin campos extras)
// ─────────────────────────────────────────

async function upsertMarkets(markets: any[]) {
  const chunkSize = 50
  for (let i = 0; i < markets.length; i += chunkSize) {
    const chunk = markets.slice(i, i + chunkSize).map(m => ({
      id: m.id,
      platform: m.platform,
      title: m.title,
      category: m.category,
      prob_yes: m.buy_yes,
      prob_no: m.buy_no,
      volume: m.volume,
      updated_at: m.updated_at
    }))
    const { error } = await supabase.from('markets').upsert(chunk)
    if (error) {
      console.error(`Upsert chunk ${i} error:`, error.message)
    }
  }
  console.log('Markets upserted OK')
}

// ─────────────────────────────────────────
// DETECTION LOGIC 
// ─────────────────────────────────────────

function detectSingleMarketArbitrage(markets: any[]) {
  const results: any[] = []
  for (const m of markets) {
    if (m.buy_yes <= 0 || m.buy_no <= 0) continue
    const sum = (m.buy_yes + m.buy_no)
    if (sum < 0.995) { // Margen de beneficio real > 0.5% (Ajuste para Feed Free)
      const delta = (1 - sum) * 100
      results.push({
        type: 'type_a',
        subtype: 'complement',
        market_id_1: m.id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: m.category,
        explanation: `Ineficiencia YES+NO: Suman ${(sum * 100).toFixed(1)}%. Retorno esperado del ${delta.toFixed(1)}% comprando ambos.`,
        detected_at: new Date().toISOString(),
        is_active: true,
        delta_history: []
      })
    }
  }
  return results
}

function detectTypeA_Exhaustive(markets: any[]) {
  const results: any[] = []
  const groups = new Map<string, any[]>()

  for (const m of markets) {
    if (m._event_id) {
      const key = `ev_${m._event_id}`
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key)!.push(m)
    }
  }

  for (const [key, group] of groups.entries()) {
    // Ajuste Premium: Aumentamos a 20 opciones para captar mercados de IA/Política complejos.
    // También bajamos el volumen mínimo a $1500 para permitir señales en el Feed Free.
    const groupVolume = group.reduce((s, m) => s + m.volume, 0)
    if (group.length < 2 || group.length > 20 || groupVolume < 1500) continue

    const total = group.reduce((s: number, m: any) => s + m.buy_yes, 0)

    // Calculamos un tamaño de operación recomendado (2% del volumen para minimizar slippage)
    const recTradeSize = Math.floor(groupVolume * 0.02)
    const displayTradeSize = recTradeSize > 2500 ? 2500 : (recTradeSize < 50 ? 50 : recTradeSize)

    // CASO 1: Arbitraje por Sub-estimación (Suma < 100%)
    if (total > 0.70 && total < 0.995) {
      const delta = (1 - total) * 100
      results.push({
        type: 'type_a',
        subtype: 'exhaustive',
        market_id_1: group[0].id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: group[0].category,
        explanation: `ESTRATEGIA: Compra SI en las ${group.length} opciones. Suma: ${(total * 100).toFixed(1)}%. Retorno: ${delta.toFixed(1)}%. \n\nRECOMENDACIÓN: Opera máximo $${displayTradeSize} para evitar deslizamiento (basado en el 2% de la liquidez).`,
        detected_at: new Date().toISOString(),
        is_active: true,
        delta_history: []
      })
    }

    // CASO 2: Arbitraje por Sobre-estimación (Suma > 100%)
    if (total > 1.05 && total < 1.40) {
      const delta = (total - 1) * 100
      results.push({
        type: 'type_a',
        subtype: 'exhaustive',
        market_id_1: group[0].id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: group[0].category,
        explanation: `ESTRATEGIA: Compra NO en las opciones más infladas. Suma: ${(total * 100).toFixed(1)}%. Retorno: ${delta.toFixed(1)}%. \n\nRECOMENDACIÓN: Opera máximo $${displayTradeSize} para evitar deslizamiento.`,
        detected_at: new Date().toISOString(),
        is_active: true,
        delta_history: []
      })
    }
  }
  return results
}

function detectTypeA_Hierarchy(markets: any[]) {
  const results: any[] = []
  // Reglas estrictas de jerarquía temporal para evitar falsos positivos
  const hRules = [
    { spec: /\bin (january|febrero)\b/i, cont: /\bin (q1|primer trimestre)\b/i },
    { spec: /\bin q1\b/i, cont: /\bin h1\b/i },
    { spec: /\bin 2025\b/i, cont: /\by 202[6-9]\b/i },
  ]

  const byEvent = new Map<string, any[]>()
  for (const m of markets) {
    if (m._event_id) {
      const key = String(m._event_id)
      if (!byEvent.has(key)) byEvent.set(key, [])
      byEvent.get(key)!.push(m)
    }
  }

  for (const [, eventMarkets] of byEvent.entries()) {
    for (const rule of hRules) {
      const specArr = eventMarkets.filter((m: any) => rule.spec.test(m.title))
      const contArr = eventMarkets.filter((m: any) => rule.cont.test(m.title))
      for (const s of specArr) {
        for (const c of contArr) {
          // Si el evento específico (más difícil) es más probable que el contenedor (más fácil), es arbitraje.
          // P(Enero) > P(Q1) es imposible.
          if (s.buy_yes > c.buy_yes + 0.02) {
            const delta = (s.buy_yes - c.buy_yes) * 100
            results.push({
              type: 'type_a',
              subtype: 'hierarchy',
              market_id_1: s.id,
              market_id_2: c.id,
              delta_points: parseFloat(delta.toFixed(2)),
              category: s.category,
              explanation: `Error de Jerarquía: El mercado '${s.title}' (${(s.buy_yes * 100).toFixed(1)}%) es más caro que '${c.title}' (${(c.buy_yes * 100).toFixed(1)}%) en el mismo evento.`,
              detected_at: new Date().toISOString(),
              is_active: true,
              delta_history: []
            })
          }
        }
      }
    }
  }
  return results
}

// ─────────────────────────────────────────
// SAVE OPPORTUNITIES
// ─────────────────────────────────────────

async function saveOpportunities(detected: any[]) {
  // LIMPIEZA TOTAL: Borramos absolutamente todo para empezar de cero sin basura de 2025
  const { error: delError } = await supabase
    .from('opportunities')
    .delete()
    .neq('id', '00000000-0000-0000-0000-000000000000') // Borra todo de forma segura

  if (delError) console.error('Delete all error:', delError.message)

  if (detected.length === 0) return []

  // Paso 2: Insertar nuevas en chunks pequeños
  const saved: any[] = []
  const chunkSize = 10 // chunks muy pequeños para evitar cualquier timeout

  for (let i = 0; i < detected.length; i += chunkSize) {
    const chunk = detected.slice(i, i + chunkSize)
    const { data, error } = await supabase
      .from('opportunities')
      .insert(chunk)
      .select()

    if (error) {
      console.error(`Insert chunk ${i} FAILED:`, error.message)
      // Si falla el chunk, intentar uno por uno
      for (const item of chunk) {
        const { data: single, error: singleErr } = await supabase
          .from('opportunities')
          .insert(item)
          .select()
        if (singleErr) {
          console.error(`Single insert FAIL [${item.market_id_1?.substring(0, 10)}]:`, singleErr.message)
        } else if (single) {
          saved.push(...single)
        }
      }
    } else if (data) {
      saved.push(...data)
    }
  }

  return saved
}

async function invokeNotifications(opportunities: any[]) {
  if (opportunities.length === 0) return
  try {
    await supabase.functions.invoke('send-notifications', { body: { opportunities } })
  } catch (_) { }
}
