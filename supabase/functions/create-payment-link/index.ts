import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const PAYOS_CLIENT_ID = Deno.env.get('PAYOS_CLIENT_ID') ?? ''
const PAYOS_API_KEY = Deno.env.get('PAYOS_API_KEY') ?? ''
const PAYOS_CHECKSUM_KEY = Deno.env.get('PAYOS_CHECKSUM_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Lấy thông tin xác thực từ header
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token)

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { amount, description, type, reference_id } = body // type: 'SUBSCRIPTION' hoặc 'INVOICE'

    // Tạo orderCode ngẫu nhiên (<= 53 bits)
    const orderCode = Math.floor(Math.random() * 9000000000000000)

    // Cập nhật order_code vào bảng tương ứng
    if (type === 'SUBSCRIPTION') {
      const { error } = await supabaseClient
        .from('subscriptions')
        .update({ order_code: orderCode })
        .eq('id', reference_id)
        .eq('owner_id', user.id)

      if (error) throw error
    } else if (type === 'INVOICE') {
      const { error } = await supabaseClient
        .from('hoadon')
        .update({ order_code: orderCode })
        .eq('id', reference_id)

      if (error) throw error
    }

    // Gọi API PayOS tạo payment link
    const signatureData = `amount=${amount}&cancelUrl=https://your-domain.com/cancel&description=${description}&orderCode=${orderCode}&returnUrl=https://your-domain.com/success`
    
    // Tạo chữ ký (sử dụng crypto của Deno)
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw', encoder.encode(PAYOS_CHECKSUM_KEY),
      { name: 'HMAC', hash: 'SHA-256' },
      false, ['sign']
    )
    const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(signatureData))
    const signatureArray = Array.from(new Uint8Array(signatureBuffer))
    const signature = signatureArray.map(b => b.toString(16).padStart(2, '0')).join('')

    const payosData = {
      orderCode,
      amount,
      description,
      returnUrl: 'https://your-domain.com/success',
      cancelUrl: 'https://your-domain.com/cancel',
      signature,
    }

    const payosRes = await fetch('https://api-merchant.payos.vn/v2/payment-requests', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': PAYOS_CLIENT_ID,
        'x-api-key': PAYOS_API_KEY
      },
      body: JSON.stringify(payosData)
    })

    const payosJson = await payosRes.json()

    if (payosJson.code !== '00') {
      throw new Error(`PayOS Error: ${payosJson.desc}`)
    }

    return new Response(JSON.stringify(payosJson.data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
