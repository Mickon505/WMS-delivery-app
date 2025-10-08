// lib/supabase_service.dart
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tvoja URL a anonymný kľúč
const supabaseUrl = "https://hbvktgldqesxtnvpwfgp.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhidmt0Z2xkcWVzeHRudnB3ZmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MzcwMDcsImV4cCI6MjA3MjQxMzAwN30.F6RzXX3Uilnh7eBP7JYalCI4WY_K1f09scymfZ_-w34";

// Urob klienta súkromným, aby sa k nemu pristupovalo len cez getter
late final SupabaseClient _supabaseClient;

class SupabaseService {
  SupabaseService._(); // Súkromný konštruktor na zabránenie inštanciám

  // Statická metóda na inicializáciu klienta
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    // Priraď klienta až po úspešnej inicializácii
    _supabaseClient = Supabase.instance.client;
  }

  // Statický getter na získanie klienta v iných súboroch
  static SupabaseClient get supabase => _supabaseClient;
}