import 'package:supabase/supabase.dart';
import 'dart:convert';

void main() async {
  final client = SupabaseClient('https://eaihqwzhfwtwzqmsrkgk.supabase.co', 'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5');
  
  // Login as Tenant (Nguyen Van A)
  // Need the exact email of Tenant. Let's find it.
  try {
    // First, use anon key to get tenant email if possible?
    // Khachthue might be readable?
    final kh = await client.from('users').select('email, quyenhan, iduser').eq('quyenhan', 'khách thuê').limit(1);
    if (kh.isEmpty) {
      print('No tenant found');
      return;
    }
    final tenantEmail = kh.first['email'];
    print('Tenant email: $tenantEmail');
    
    await client.auth.signInWithPassword(email: tenantEmail, password: 'password123'); // Assuming standard password
    final tenantData = await client.from('thongbao').select('title, sender_id, receiver_id, room_id');
    print('Tenant sees:');
    print(jsonEncode(tenantData));
    await client.auth.signOut();
  } catch(e) {
    print('Error: $e');
  }
}
