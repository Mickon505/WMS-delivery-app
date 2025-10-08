// lib/supabase_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tvoja URL a anonymný kľúč
final supabaseUrl = dotenv.env['SUPABASE_URL'];
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

// Urob klienta súkromným, aby sa k nemu pristupovalo len cez getter
late final SupabaseClient _supabaseClient;

class SupabaseService {
  SupabaseService._(); // Súkromný konštruktor na zabránenie inštanciám

  // Statická metóda na inicializáciu klienta
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: supabaseUrl!,
      anonKey: supabaseAnonKey!,
    );
    // Priraď klienta až po úspešnej inicializácii
    _supabaseClient = Supabase.instance.client;
  }

  // Statický getter na získanie klienta v iných súboroch
  static SupabaseClient get supabase => _supabaseClient;
}