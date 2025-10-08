import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'global_variables.dart';
import 'supabase_service.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const StartScreen({super.key, required this.onLoginSuccess});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errMessage = '';
  bool _isLoading = false;

  final String _domain = '@company.fk';

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_nameController.text.length <= 1 || _passwordController.text.length <= 1) {
      setState(() {
        _errMessage = "Zlé prihlasovacie údaje";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errMessage = '';
    });

    final fakeEmail = '${_nameController.text.toLowerCase()}$_domain';

    try {
      final AuthResponse res = await SupabaseService.supabase.auth.signInWithPassword(
        email: fakeEmail,
        password: _passwordController.text,
      );

      if (res.session != null) {
        //print("Successfully logged in. Now loading data");

        final data = await SupabaseService.supabase
            .from('Products')
            .select('name');

        
        final List<String> productNames = [];
        for (var product in data) {
          productNames.add(product["name"]);
        }

        globalVariables.products = productNames;
        //print("Data stored.");
      

        setState(() {
          _isLoading = false;
        });
        widget.onLoginSuccess();
      }
    } on AuthApiException catch (e) {
      if(e.message == "Invalid login credentials"){
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Zlé prihlasovacie údaje")));
      }
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Neočakávaná chyba: $e")));
    } finally {
      setState(() {
          _isLoading = false;
        });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/theMaskLogo.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Meno",
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Heslo",
                    hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _errMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "Prihlásiť sa",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}