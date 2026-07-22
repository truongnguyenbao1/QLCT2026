import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://eaihqwzhfwtwzqmsrkgk.supabase.co', 'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5');
  try {
    final user = await supabase.from('users').select().eq('quyenhan', 'khách thuê').limit(1);
    print('Users row: $user');
  } catch(e) { print(e); }
}
