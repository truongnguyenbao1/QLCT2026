import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://eaihqwzhfwtwzqmsrkgk.supabase.co',
    'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5',
  );

  try {
    final response = await client.from('khachthue').select();
    print('All tenants: $response');
  } catch (e) {
    print('Error reading tenants: $e');
  }
}
