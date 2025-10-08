// lib/vm_selection_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'product_row.dart';
import 'supabase_service.dart';

const supabaseUrl = "https://hbvktgldqesxtnvpwfgp.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhidmt0Z2xkcWVzeHRudnB3ZmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MzcwMDcsImV4cCI6MjA3MjQxMzAwN30.F6RzXX3Uilnh7eBP7JYalCI4WY_K1f09scymfZ_-w34";

const initialProduct = {
  'id': 0,
  'name': '',
  'quantity': 0,
};

class VMSelectionScreen extends StatefulWidget {
  final String routeName;

  const VMSelectionScreen({super.key, required this.routeName});

  @override
  State<VMSelectionScreen> createState() => _VMSelectionScreenState();
}

class _VMSelectionScreenState extends State<VMSelectionScreen> {
  final _minterController = TextEditingController();
  bool _isLoading = false;
  String _errMessage = "";
  String _loadText = "Vyložiť";

  String? _selectedPlace;
  List<dynamic> _products = [initialProduct];
  List<dynamic> _productsData = [];
  List<dynamic> _places = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final jsonData = await rootBundle.loadString('assets/VMRoutes.json');
    final Map<String, dynamic> routes = json.decode(jsonData);
    if (routes[widget.routeName] != null) {
      final loadedPlaces = (routes[widget.routeName] as Map).keys.map((place) => ({
        'label': place,
        'value': place,
      })).toList();
      setState(() {
        _places = loadedPlaces;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedProducts = prefs.getString("productsData");
    if (cachedProducts != null) {
      setState(() {
        _productsData = json.decode(cachedProducts);
      });
    }
  }

  void _addProductRow() {
    setState(() {
      _products.add({ ...initialProduct, 'id': DateTime.now().millisecondsSinceEpoch });
    });
  }

  void _handleCancel() {
    setState(() {
      _products = [{ ...initialProduct, 'id': DateTime.now().millisecondsSinceEpoch }];
      _loadText = "Vyložiť";
      _errMessage = "";
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errMessage = "";
    });

    final filteredProducts = _products.where((p) => p['name'] != '' && p['quantity'] > 0).toList();
    final parsedMinter = double.tryParse(_minterController.text) ?? 0.00;

    final dataToSave = {
      "restocked_items": filteredProducts,
      "restocked_at_place": _selectedPlace,
      "minter_val": parsedMinter,
      "minter_val_text": _minterController.text,
    };

    final response = await SupabaseService.supabase.from("VendingRestock").insert(dataToSave);

    setState(() {
      _isLoading = false;
    });

    if (response.error != null) {
      setState(() {
        _errMessage = "Chyba ukladania do databázy.";
      });
      //print(response.error);
    } else {
      setState(() {
        _loadText = "Vyložené";
      });
      _handleCancel();
      //print("Saved to DB.");
    }
  }

  void _updateProductData(int id, String field, dynamic value) {
    setState(() {
      _products = _products.map((item) {
        if (item['id'] == id) {
          return { ...item, field: value };
        }
        return item;
      }).toList();
    });
  }

  void _removeProductData(int id) {
    setState(() {
      _products.removeWhere((product) => product['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: DropdownButton2<String>(
                  hint: const Text(
                    'Vyber Automat',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  value: _selectedPlace,
                  items: _places.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlace = value;
                    });
                    _handleCancel();
                  },
                  buttonStyleData: ButtonStyleData(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xFF717171),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _minterController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Mincovník",
                    hintStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedPlace != null)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return ProductRow(
                        key: ValueKey(_products[index]['id']),
                        product: _products[index],
                        productsData: _productsData,
                        updateData: _updateProductData,
                        removeProduct: _removeProductData,
                      );
                    },
                  ),
                ),
                Text(_errMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton(
                    onPressed: _addProductRow,
                    child: const Text("Pridať riadok"),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Zrušiť"),
                    ),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isLoading
                          ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                          : Text(_loadText),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}