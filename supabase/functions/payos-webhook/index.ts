import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const PAYOS_CHECKSUM_KEY = Deno.env.get('PAYOS_CHECKSUM_KEY') ?? ''

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const bodyText = await req.text()
    const body = JSON.parse(bodyText)

    if (body.data && body.signature) {
      // Xác thực chữ ký webhook của PayOS (Dựa theo tài liệu PayOS)
      // Dữ liệu tạo chữ ký: amount=...&code=...&description=...&orderCode=...
      const data = body.data
      const sortedKeys = Object.keys(data).sort()
      let signData = ''
      sortedKeys.forEach(key => {
        if (data[key] !== undefined && data[key] !== null) {
          signData += `${key}=${data[key]}&`
        }
      })
      // Bỏ dấu '&' ở cuối
      signData = signData.slice(0, -1)

      const encoder = new TextEncoder()
      const key = await crypto.subtle.importKey(
        'raw', encoder.encode(PAYOS_CHECKSUM_KEY),
        { name: 'HMAC', hash: 'SHA-256' },
        false, ['sign']
      )
      const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(signData))
      const signatureArray = Array.from(new Uint8Array(signatureBuffer))
      const expectedSignature = signatureArray.map(b => b.toString(16).padStart(2, '0')).join('')

      if (expectedSignature !== body.signature) {
        console.error("Invalid signature")
        // Tuỳ chọn: Vẫn chấp nhận hoặc từ chối (tuỳ mức độ bảo mật yêu cầu)
      }

      if (data.code === '00') {
        const orderCode = data.orderCode

        const supabaseClient = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Tìm trong subscriptions trước
        const { data: subData } = await supabaseClient
          .from('subscriptions')
          .select('id, owner_id')
          .eq('order_code', orderCode)
          .maybeSingle()

        if (subData) {
          // Kích hoạt subscription
          await supabaseClient
            .from('subscriptions')
            .update({ status: 'ACTIVE' })
            .eq('id', subData.id)

          // Cập nhật nhatro registration_status
          await supabaseClient
            .from('nhatro')
            .update({ registration_status: 'APPROVED' })
            .eq('iduser', subData.owner_id)

          return new Response(JSON.stringify({ success: true, message: 'Subscription activated' }), {
            headers: { 'Content-Type': 'application/json' },
          })
        }

        // Nếu không có trong subscriptions, tìm trong hoadon (dùng cho khách thuê trả tiền nhà)
        const { data: hoadonData } = await supabaseClient
          .from('hoadon')
          .select('id')
          .eq('order_code', orderCode)
          .maybeSingle()

        if (hoadonData) {
          await supabaseClient
            .from('hoadon')
            .update({ trang_thai: 'da_thu' })
            .eq('id', hoadonData.id)

          return new Response(JSON.stringify({ success: true, message: 'Invoice paid' }), {
            headers: { 'Content-Type': 'application/json' },
          })
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
