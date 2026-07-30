import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import * as admin from "npm:firebase-admin@11.10.1";

// Khởi tạo Firebase Admin (Yêu cầu cấu hình biến môi trường FIREBASE_SERVICE_ACCOUNT)
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

if (FIREBASE_SERVICE_ACCOUNT && admin.apps.length === 0) {
  try {
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.error("Lỗi khi parse FIREBASE_SERVICE_ACCOUNT:", error);
  }
}

serve(async (req) => {
  try {
    const payload = await req.json();

    // Chỉ xử lý nếu là method POST từ Webhook của Supabase
    if (req.method !== 'POST') {
      return new Response("Method Not Allowed", { status: 405 });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // ==========================================
    // USE CASE 1: THÔNG BÁO HÓA ĐƠN MỚI
    // Triggered when a new row is inserted into 'hoadon'
    // ==========================================
    if (payload.table === 'hoadon' && payload.type === 'INSERT') {
      const hoadon = payload.record;
      const tenantId = hoadon.tenant_id;
      const roomId = hoadon.room_id;

      if (!tenantId) {
        return new Response(JSON.stringify({ message: "Không có tenant_id, bỏ qua thông báo." }), { status: 200 });
      }

      // Lấy user_id của khách thuê
      const { data: tenantData } = await supabase
        .from('khachthue')
        .select('user_id')
        .eq('id', tenantId)
        .single();
        
      // Lấy số phòng
      const { data: roomData } = await supabase
        .from('phong')
        .select('room_number')
        .eq('id', roomId)
        .single();

      const userId = tenantData?.user_id;
      const roomNumber = roomData?.room_number || "Không xác định";

      if (!userId) {
         return new Response(JSON.stringify({ message: "Khách thuê chưa liên kết tài khoản app." }), { status: 200 });
      }

      // Lấy FCM Token từ bảng users
      const { data: userData } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('iduser', userId)
        .single();

      const fcmToken = userData?.fcm_token;
      
      const title = `Hóa đơn tháng ${hoadon.month}/${hoadon.year}`;
      const body = `Phòng ${roomNumber} có hóa đơn mới cần thanh toán. Vui lòng kiểm tra!`;

      // Lưu In-app Notification vào bảng `thongbao` (Cập nhật field type cho phù hợp schema của bạn, có thể là 'SYSTEM' hoặc 'ANNOUNCEMENT' nếu không có 'INVOICE')
      await supabase.from('thongbao').insert({
        receiver_id: userId,
        room_id: roomId,
        title: title,
        content: body,
        type: 'SYSTEM'
      });

      // Bắn Push Notification qua Firebase FCM
      if (fcmToken && FIREBASE_SERVICE_ACCOUNT) {
        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          data: {
            type: 'invoice_new',
            invoiceId: hoadon.id
          }
        });
        return new Response(JSON.stringify({ message: "Đã gửi Push Notification thành công!" }), { status: 200 });
      } else {
        return new Response(JSON.stringify({ message: "Chưa cấu hình Firebase hoặc User không có FCM Token" }), { status: 200 });
      }
    }
    
    // ==========================================
    // Các Use Case khác (như khách báo thanh toán) có thể add thêm Else If ở đây
    // ==========================================

    return new Response(JSON.stringify({ message: "Event ignored" }), { status: 200 });
  } catch (error: any) {
    console.error("Lỗi Edge Function:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
