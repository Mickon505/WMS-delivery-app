import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:romivending/global_variables.dart';
import 'package:romivending/supabase_service.dart';
import 'dart:convert';

class Kiosk {
  final String displayName;
  final String searchName;
  Kiosk({required this.displayName, required this.searchName});
}

class VendingMachineStatesScreen extends StatefulWidget {
  const VendingMachineStatesScreen({super.key});

  @override
  State<VendingMachineStatesScreen> createState() => _VendingMachineStatesScreen();
}

class _VendingMachineStatesScreen extends State<VendingMachineStatesScreen> {
  List<Map<String, dynamic>> loadedProducts = [];
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _kioskController = TextEditingController();

  String? _selectedKiosk;
  List<Kiosk> _kiosks = [];
  TextEditingController? _kioskAutocompleteController;
  TextEditingController? _productAutocompleteController;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    try {
      // Načítanie obsahu JSON súboru
      final String jsonString = await rootBundle.loadString('assets/VMRoutes.json');
      // Dekódovanie JSON do Map
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<Kiosk> loadedKiosks = [];

      data.forEach((route, kiosk) {
        kiosk.forEach((kioskName, kioskData) {
          loadedKiosks.add(Kiosk(
            displayName: kioskName,
            searchName: '$kioskName ${(kioskData['tags'] as List<dynamic>).join(' ')}',
          ));
        });
      });

      setState(() {
        _kiosks = loadedKiosks;
        
        // Debug print to verify loaded data
        //print('Loaded kiosks:');
        //for (var kiosk in _kiosks) {
        //  print('DisplayName: ${kiosk.displayName}, SearchName: ${kiosk.searchName}');
        //}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba pri načítaní trás: $e')));
    }
  }

  // Zoznam produktov pre automatické dopĺňanie
  final List<String> _productOptions = globalVariables.products;

  void _addItem() {
    String productName = _productNameController.text;
    String quantity = _quantityController.text;

    if (productName.isNotEmpty && quantity.isNotEmpty) {
      setState(() {
        loadedProducts.add({
        "name": productName,
        "quantity": quantity
      });
        
        // Clear both main controllers and Autocomplete controller
        _productNameController.text = '';
        _quantityController.text = '';
        if (_productAutocompleteController != null) {
          _productAutocompleteController!.text = '';
        }

        
        _productAutocompleteController?.clear();
        _quantityController.clear();
        _productNameController.clear();
      });
    }
  }

  void _saveState() async {
    if (loadedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Žiadne produkty na uloženie stavu.")));
      return;
    }
    try {
      await SupabaseService.supabase
        .from('VendingState')
        .insert({
          "products_loaded": loadedProducts,
          "vending_machine": _selectedKiosk
        });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stav úspešne uložený")));
      setState(() {
        _kiosks = [];
        _selectedKiosk = null;
        loadedProducts.clear();
        _kioskController.clear();
        _kioskAutocompleteController?.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chyba pri ukladaní do databázy: $e")));
      return;
    }
    
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth * 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Text('Stav automatu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  // Autocomplete pre výber kiosku
                  child: Autocomplete<Kiosk>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Kiosk>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      
                      // Vyhľadávanie prebieha na základe searchName a tagov
                      return _kiosks.where((Kiosk option) {
                        return option.searchName.toLowerCase().contains(query);
                      });
                    },
                    displayStringForOption: (Kiosk option) => option.displayName,


                    onSelected: (Kiosk selection) {
                      _kioskController.text = selection.displayName;
                      _selectedKiosk = selection.displayName;
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                      // Store the Autocomplete's controller
                      _kioskAutocompleteController = textEditingController;
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Vyber automat',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<Kiosk> onSelected,
                      Iterable<Kiosk> options) {
                        return Material(
                          elevation: 8.0,
                          child: SizedBox(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Kiosk option = options.elementAt(index);
                                return ListTile(
                                  // Nastavíme farbu každej položky, aby bola rovnaká
                                  tileColor: Colors.black,
                                  title: Text(
                                    option.displayName,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            )
                        )
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                // Autocomplete widget namiesto pôvodného TextField
                SizedBox(
                  width: screenWidth * 0.64,
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _productOptions.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _productNameController.text = selection;
                        if (_productAutocompleteController != null) {
                          _productAutocompleteController!.text = selection;
                        }
                      });
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) {
                      // Vytvorí TextField, ktoré vyzerá ako tvoje pôvodné
                      _productAutocompleteController = textEditingController;
                      return TextField(
                        controller: _productAutocompleteController,
                        focusNode: focusNode,
                        onSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Názov produktu',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options)
                      // Definuje, ako sa majú zobrazovať návrhy
                      {
                        return Material(
                          elevation: 8.0,
                          child: SizedBox(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  // Nastavíme farbu každej položky, aby bola rovnaká
                                  tileColor: Colors.black,
                                  title: Text(
                                    option,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            )
                        )
                      );
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                SizedBox(
                  width: screenWidth * 0.30,
                  child: TextField(
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ks',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  if (_productNameController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Zadaj názov produktu"))); return;}
                  if (_quantityController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Zadaj počet kusov"))); return;}

                  _addItem();
                },
                child: Text('PRIDAŤ', style: TextStyle(color: const Color(0xFF141414))),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: loadedProducts.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF000000),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.archive_outlined, color: Colors.white),
                      title: Text(
                        "${loadedProducts[index]['name']} (${loadedProducts[index]['quantity']} ks)",
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            loadedProducts.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _saveState,
                child: Text('ULOŽIŤ STAV', style: TextStyle(color: const Color(0xFF141414))),
              ),
            ),
            SizedBox(height: 50,),
          ],
        ),
      ),
    );
  }
}