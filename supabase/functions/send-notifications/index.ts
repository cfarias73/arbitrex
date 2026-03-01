import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!
const MAX_DAILY_NOTIFICATIONS = 5 // por usuario en plan free

Deno.serve(async (req) => {
    const { opportunities } = await req.json()
    if (!opportunities?.length) return new Response('No opportunities', { status: 200 })

    try {
        const { data: alerts } = await supabase
            .from('user_alerts')
            .select(`
        *,
        profiles!inner(id, plan, fcm_token, notifications_enabled)
      `)
            .eq('is_active', true)
            .not('profiles.fcm_token', 'is', null)
            .eq('profiles.notifications_enabled', true)

        if (!alerts?.length) return new Response('No active alerts', { status: 200 })

        let sent = 0

        for (const alert of alerts) {
            const profile = alert.profiles
            const isPro = ['pro', 'trader_plus'].includes(profile.plan)

            for (const opp of opportunities) {
                if (!matchesAlert(opp, alert)) continue
                if (!isPro) {
                    if (opp.type !== 'type_a') continue
                    if (opp.delta_points < 7) continue
                }
                if (!isPro) {
                    const todayCount = await getNotificationCountToday(profile.id)
                    if (todayCount >= MAX_DAILY_NOTIFICATIONS) continue
                }
                const { data: alreadySent } = await supabase
                    .from('notifications_sent')
                    .select('id')
                    .eq('user_id', profile.id)
                    .eq('opportunity_id', opp.id)
                    .single()
                if (alreadySent) continue

                const success = await sendFCM(profile.fcm_token, {
                    title: `⚡ +${opp.delta_points.toFixed(1)}pts — ${typeLabel(opp.type)}`,
                    body: opp.explanation.substring(0, 100),
                    data: {
                        opportunity_id: opp.id,
                        type: opp.type,
                        delta: opp.delta_points.toString()
                    }
                })

                if (success) {
                    await supabase.from('notifications_sent').insert({
                        user_id: profile.id,
                        opportunity_id: opp.id
                    })
                    sent++
                }
            }
        }

        return new Response(JSON.stringify({ sent }), {
            headers: { 'Content-Type': 'application/json' }
        })

    } catch (error) {
        console.error('Notification error:', error)
        return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }
})

function matchesAlert(opp: any, alert: any): boolean {
    if (alert.type_filter?.length > 0 && !alert.type_filter.includes(opp.type)) return false
    if (alert.category_filter?.length > 0 && !alert.category_filter.includes(opp.category)) return false
    if (opp.delta_points < alert.min_delta) return false
    return true
}

async function getNotificationCountToday(userId: string): Promise<number> {
    const todayStart = new Date()
    todayStart.setHours(0, 0, 0, 0)
    const { count } = await supabase.from('notifications_sent').select('id', { count: 'exact' }).eq('user_id', userId).gte('sent_at', todayStart.toISOString())
    return count || 0
}

async function sendFCM(token: string, notification: any): Promise<boolean> {
    try {
        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
            method: 'POST',
            headers: {
                'Authorization': `key=${FCM_SERVER_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                to: token,
                notification: {
                    title: notification.title,
                    body: notification.body,
                    sound: 'default'
                },
                data: notification.data,
                priority: 'high',
                apns: {
                    payload: {
                        aps: { sound: 'default', badge: 1 }
                    }
                }
            })
        })
        const result = await res.json()
        return result.success === 1
    } catch (e) {
        console.error('FCM error:', e)
        return false
    }
}

function typeLabel(type: string): string {
    const labels: Record<string, string> = {
        type_a: 'Ineficiencia lógica',
        type_b: 'Discrepancy inter-plataforma',
        type_c: 'Movimiento anómalo'
    }
    return labels[type] || type
}
