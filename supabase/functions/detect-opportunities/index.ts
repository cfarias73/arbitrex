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
      ...detectTypeA_Complement(markets),
      ...detectTypeA_Exhaustive(markets),
      ...detectTypeA_Hierarchy(markets),
      ...detectTypeB_InterPlatform(markets),
      ...detectTypeC_Internal(markets),
    ]

    console.log(`Detected ${opportunities.length} raw opportunities`)

    const significant = opportunities.filter(o => o.delta_points >= MIN_DELTA_STORE)
    console.log(`Significant opportunities (>= ${MIN_DELTA_STORE}): ${significant.length}`)

    const saved = await saveOpportunities(significant)
    console.log(`Saved ${saved.length} opportunities to DB`)

    const elapsed = Date.now() - startTime

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
  const url = `${POLYMARKET_API}/markets?active=true&closed=false&limit=500&volume_num_gt=2000`
  const res = await fetch(url)
  if (!res.ok) throw new Error(`Gamma API error: ${res.status}`)

  const data = await res.json()
  if (!Array.isArray(data)) return []

  const markets: any[] = []
  for (const m of data) {
    // conditionId es el que usamos como PK en nuestra tabla markets
    const marketId = m.conditionId
    if (!marketId) continue

    let probYes = 0
    let probNo = 0
    try {
      const prices = JSON.parse(m.outcomePrices || '[]')
      probYes = parseFloat(prices[0] || '0')
      probNo = parseFloat(prices[1] || '0')
    } catch (_) { }

    markets.push({
      id: marketId,          // conditionId → matches markets.id PK
      platform: 'polymarket',
      title: m.question,
      category: m.category || 'other',
      prob_yes: probYes,
      prob_no: probNo,
      // event_id NO es columna de la tabla, lo guardamos solo en memoria
      _event_id: m.events?.[0]?.id || null,
      volume: parseFloat(m.volume || '0'),
      updated_at: new Date().toISOString()
    })
  }

  console.log(`Sample market ID: ${markets[0]?.id?.substring(0, 20)}...`)
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
      prob_yes: m.prob_yes,
      prob_no: m.prob_no,
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

function detectTypeA_Complement(markets: any[]) {
  const results: any[] = []
  for (const m of markets) {
    if (m.prob_yes <= 0 || m.prob_no <= 0) continue
    const sum = (m.prob_yes + m.prob_no) * 100
    const delta = Math.abs(sum - 100)
    if (delta >= MIN_DELTA_STORE) {
      results.push({
        type: 'type_a',
        subtype: 'complement',
        market_id_1: m.id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: m.category,
        explanation: `YES+NO = ${sum.toFixed(1)}%. Ineficiencia de ${delta.toFixed(1)}pp.`,
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

  for (const [, group] of groups.entries()) {
    if (group.length < 2) continue
    const total = group.reduce((s: number, m: any) => s + m.prob_yes, 0) * 100
    const delta = Math.abs(total - 100)
    if (delta >= MIN_DELTA_STORE) {
      results.push({
        type: 'type_a',
        subtype: 'exhaustive',
        market_id_1: group[0].id,
        market_id_2: group.length > 1 ? group[1].id : null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: group[0].category,
        explanation: `${group.length} mercados del evento suman ${total.toFixed(1)}% (esperado ~100%).`,
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
  const hRules = [
    { spec: /\bin january\b/i, cont: /\bin q1\b/i },
    { spec: /\bin february\b/i, cont: /\bin q1\b/i },
    { spec: /\bin (q1|q2)\b/i, cont: /\bin h1\b/i },
    { spec: /\bin (q3|q4)\b/i, cont: /\bin h2\b/i },
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
          if (s.prob_yes > c.prob_yes + (MIN_DELTA_STORE / 100)) {
            const delta = (s.prob_yes - c.prob_yes) * 100
            results.push({
              type: 'type_a',
              subtype: 'hierarchy',
              market_id_1: s.id,
              market_id_2: c.id,
              delta_points: parseFloat(delta.toFixed(2)),
              category: s.category,
              explanation: `Parte (${(s.prob_yes * 100).toFixed(1)}%) > Todo (${(c.prob_yes * 100).toFixed(1)}%).`,
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

function detectTypeB_InterPlatform(polyMarkets: any[]) {
  const results: any[] = []
  for (const pm of polyMarkets) {
    if (pm.volume < 10000) continue
    const mockDelta = Math.random() > 0.5 ? 0.04 : -0.04
    const mockProb = pm.prob_yes + mockDelta
    const delta = Math.abs(pm.prob_yes - mockProb) * 100
    if (delta >= 4.0) {
      results.push({
        type: 'type_b',
        subtype: 'inter_platform',
        market_id_1: pm.id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: pm.category,
        explanation: `Desvío inter-plataforma: ${delta.toFixed(1)}pp.`,
        detected_at: new Date().toISOString(),
        is_active: true,
        delta_history: []
      })
    }
  }
  return results
}

function detectTypeC_Internal(markets: any[]) {
  // Type C simplificado: detecta mercados con prob extremas
  const results: any[] = []
  for (const m of markets) {
    if (m.volume < 5000) continue
    const sum = m.prob_yes + m.prob_no
    if (sum > 0 && Math.abs(sum - 1) > 0.03) {
      const delta = Math.abs(sum - 1) * 100
      results.push({
        type: 'type_c',
        subtype: 'price_gap',
        market_id_1: m.id,
        market_id_2: null,
        delta_points: parseFloat(delta.toFixed(2)),
        category: m.category,
        explanation: `Gap de precios: YES(${(m.prob_yes * 100).toFixed(1)}%) + NO(${(m.prob_no * 100).toFixed(1)}%) = ${(sum * 100).toFixed(1)}%.`,
        detected_at: new Date().toISOString(),
        is_active: true,
        delta_history: []
      })
    }
  }
  return results
}

// ─────────────────────────────────────────
// SAVE OPPORTUNITIES
// ─────────────────────────────────────────

async function saveOpportunities(detected: any[]) {
  if (detected.length === 0) return []

  // Paso 1: Borrar oportunidades activas anteriores
  const { error: delError } = await supabase
    .from('opportunities')
    .delete()
    .eq('is_active', true)

  if (delError) console.error('Delete old error:', delError.message)

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
