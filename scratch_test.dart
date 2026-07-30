import 'package:protocol_registry/protocol_registry.dart';

void main() async {
  try {
    // Test the exact class/method Name
    await Registry.registerProtocol('io.supabase.trokeeper', 'TroKeeper App');
    print('Registered successfully');
  } catch (e) {
    print('Error: $e');
  }
}
