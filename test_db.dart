import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://eaihqwzhfwtwzqmsrkgk.supabase.co', 'sb_publishable_D887foMxZKHPBkpqcr6VOg_AcyGGAA5');
  try {
    final res = await supabase.from('thongbao').select().limit(1);
    print(res);
  } catch (e) {
    print(e);
  }
}
