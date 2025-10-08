import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'start_screen.dart';
import 'main_screen.dart';
import 'global_variables.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();


  runApp(const MyApp());
} 

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Stav na riadenie prihlásenia
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = SupabaseService.supabase.auth.currentSession;
    if (session != null) {
      // Session exists, load necessary data
      try {
        final data = await SupabaseService.supabase
            .from('Products')
            .select('name');
        
        final List<String> productNames = [];
        for (var product in data) {
          productNames.add(product["name"]);
        }
        
        globalVariables.products = productNames;
        
        setState(() {
          _isLoggedIn = true;
        });
      } catch (e) {
        // Handle error loading data
        //print('Error loading initial data: $e');
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri načítaní dát: $e')),
        );
      }
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RomiVending',
      theme: ThemeData.dark(),
      home: _isLoggedIn
          ? MainScreen()
          : StartScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}