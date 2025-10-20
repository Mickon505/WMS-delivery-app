import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:romivending/global_variables.dart';
import 'package:romivending/show_todays_unloads.dart';

import 'supabase_service.dart';

class Kiosk {
  final String displayName;
  final String searchName;
  Kiosk({required this.displayName, required this.searchName});
}

class VendingMachinesScreen extends StatefulWidget {
  const VendingMachinesScreen({super.key});

  @override
  State<VendingMachinesScreen> createState() => _VendingMachinesScreen();
}


class _VendingMachinesScreen extends State<VendingMachinesScreen> {
  final List<String> _productOptions = globalVariables.products;

  // Main controllers for storing selected values
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _kioskController = TextEditingController();
  final TextEditingController _minterController = TextEditingController();
  
  // Controllers for Autocomplete widgets
  TextEditingController? _kioskAutocompleteController;
  TextEditingController? _productAutocompleteController;
  

  String? _selectedKiosk;
  String chooseOption = "Vyber trasu";
  String optionText = "";
  List<Kiosk> _kiosks = [];
  List<String> unloadedProductsText = [];
  List<Map<String, dynamic>> unloadedProducts = [];
  bool isRouteSelected = false;
  
  void _addItem() {
    String productName = _productNameController.text;
    String quantity = _quantityController.text;

    setState(() {
      unloadedProductsText.add('$productName ($quantity ks)');
      unloadedProducts.add({
        "name": productName,
        "quantity": quantity
      });
      
      // Clear both main controllers and Autocomplete controllers
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

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _kioskController.dispose();
    _minterController.dispose();
    _kioskAutocompleteController?.dispose();
    _productAutocompleteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    //double horizontalPadding = screenWidth * 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Text('Vykládka do automatu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Dropdown menu pre výber trasy
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

                SizedBox(width: 15),

                SizedBox(
                  width: screenWidth * 0.23,
                  child: TextField(
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    controller: _minterController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mincovník',
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
            Row(
              children: [

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
                      // Store the Autocomplete's controller
                      _productAutocompleteController = textEditingController;
                      return TextField(
                        controller: textEditingController,
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
                  width: screenWidth * 0.23,
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
            // Zoznam vyložených zásielok
            Expanded(
              child: ListView.builder(
                itemCount: unloadedProductsText.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.black,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.unarchive_outlined, color: Colors.white),
                      title: Text(unloadedProductsText[index]),
                      textColor: Colors.white,
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            unloadedProductsText.removeAt(index);
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
              child: (unloadedProductsText.isEmpty) ? buildShowUnloadsButton() : buildFinishUnloadButton(),
            ),
            SizedBox(height: 50,),
          ],
        ),
      ),
    );
  }
  
  ElevatedButton buildFinishUnloadButton(){
    return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: _loadTruck,
            child: Text('DOKONČIŤ VYKLÁDKU', style: TextStyle(color: Colors.black)),
          );
  }

  ElevatedButton buildShowUnloadsButton(){
    return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShowTodaysUnloads()),
              );
            },
            child: Text('ZOBRAZIŤ VYKLÁDKY', style: TextStyle(color: Colors.black)),
          );
  }

  void _loadTruck() async {
    if (_selectedKiosk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prosím, najprv vyber automat.')),
      );
      return;
    }
    if (unloadedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie sú pridané žiadne produkty na vyloženie.')),
      );
      return;
    }
    if (_minterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zadaj hodnotu mincovníka.')),
      );
      return;
    }

    try {
      await SupabaseService.supabase.from("VendingRestock").insert({
        "restocked_items": unloadedProducts,
        "restocked_at_place": _selectedKiosk,
        "minter_val": double.tryParse(_minterController.text) ?? 0.0,
        "minter_val_text": _minterController.text
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vykládka do automatu na mieste: $_selectedKiosk dokončená.')),
      );

      setState(() {
        // Clear all data
        unloadedProducts = [];
        unloadedProductsText = [];
        _selectedKiosk = null;

        // Clear main controllers
        _kioskController.clear();
        _productNameController.clear();
        _quantityController.clear();
        _minterController.clear();

        // Clear Autocomplete controllers
        _kioskAutocompleteController?.clear();
        _productAutocompleteController?.clear();
        
      }
    );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba pri ukladaní dát: $e')));
      return;
    }
  }
}