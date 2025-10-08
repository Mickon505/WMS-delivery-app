// lib/product_row.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ProductRow extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<dynamic> productsData;
  final Function(int, String, dynamic) updateData;
  final Function(int) removeProduct;

  const ProductRow({
    super.key,
    required this.product,
    required this.productsData,
    required this.updateData,
    required this.removeProduct,
  });

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.product['quantity'].toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFF717171),
              ),
              child: DropdownButton2<String>(
                isExpanded: true,
                hint: const Text(
                  "Vyber Produkt",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: widget.product['name'] == '' ? null : widget.product['name'] as String?,
                items: widget.productsData.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'] as String,
                    child: Text(item['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  widget.updateData(widget.product['id'], 'name', value);
                },
                buttonStyleData: ButtonStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF717171),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF717171),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 40,
                ),
                dropdownSearchData: DropdownSearchData(
                  searchController: TextEditingController(),
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      expands: true,
                      maxLines: null,
                      controller: TextEditingController(),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: 'Vyhľadať produkt...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (text) {
                widget.updateData(widget.product['id'], 'quantity', int.tryParse(text) ?? 0);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "ks",
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
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => widget.removeProduct(widget.product['id']),
            icon: const FaIcon(
              FontAwesomeIcons.trash,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}