import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://eaihqwzhfwtwzqmsrkgk.supabase.co',
    'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5',
  );

  try {
    final auth = await client.from('nhatro').select().limit(1);
    print('nhatro: $auth');
  } catch (e) {
    print('nhatro error: $e');
  }
}
