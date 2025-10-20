import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:romivending/supabase_service.dart';

class ShowTodaysUnloads extends StatefulWidget {
  const ShowTodaysUnloads({super.key});
  @override
  State<ShowTodaysUnloads> createState() => _ShowTodaysUnloadsState();
}

class _ShowTodaysUnloadsState extends State<ShowTodaysUnloads> {

  String selectedMachine = "*";
  final List<DropdownMenuItem<String>> items = [
    DropdownMenuItem(value: "*", child: Text("Vyber automat")),
  ];
  final Map<String, dynamic> todaysUnloads = {};

  void _loadUnloadsData() async {
    try {
      final data = await SupabaseService.supabase
          .from('VendingRestock')
          .select("restocked_at_place,restocked_items,restocked_at");

      int index = 0;
      for (var unload in data.reversed) {
        if (index >= 5) break;

        final DateTime restockDate = DateTime.parse(unload['restocked_at']);
        final DateTime now = DateTime.now();
        if (restockDate.day != now.day) continue;

        final products = (unload['restocked_items'] as List<dynamic>)
          .map((item) {
            final productItem = item as Map<String, dynamic>;
            productItem['color'] = Colors.black; // or any default color
            return productItem;
          })
          .toList();
        final String place = unload['restocked_at_place'];

        if(!todaysUnloads.containsKey(place)) {
          items.add(DropdownMenuItem(value: place, child: Text(place)));
        
          todaysUnloads[place] = {
            'machineName': place,
            'products': products,
          };
        }
        else {
          todaysUnloads[place]['products'].addAll(products);
        }


        index++;
      }
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba pri načítaní dát: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnloadsData();
  }

  @override
  void dispose() {
    todaysUnloads.clear();
    items.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try{
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dnešné vykládky'),
          backgroundColor: const Color(0xFF141414),
        ),
        backgroundColor: const Color(0xFF141414),
        body: Column( 
          children: [
            const SizedBox(height: 16.0),

            DropdownButton2(items: items, onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedMachine = value;
                });
              }
            },
            value: selectedMachine,
            underline: SizedBox(),
            buttonStyleData: ButtonStyleData(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF141414),
                border: Border.all(
                  color: Colors.white,
                ),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black87,
              ),
            ),
            hint: Text("Vyber automat", style: TextStyle(color: Colors.white70)),
            style: TextStyle(color: Colors.white),),
            
            SizedBox(height: 16.0),
            
            (selectedMachine != "*") ?
              Expanded(
                child: ListView.builder(
                    itemCount: todaysUnloads[selectedMachine]["products"]?.length ?? 0,
                    itemBuilder: (context, index) {
                      return Card(
                        color: todaysUnloads[selectedMachine]["products"][index]['color'],
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                        child: ListTile(
                          leading: Icon(Icons.unarchive_outlined, color: Colors.white),
                          title: Text('${todaysUnloads[selectedMachine]["products"][index]['name']} (${todaysUnloads[selectedMachine]["products"][index]['quantity']}ks)',
                          style: 
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                          textColor: Colors.white,
                          onTap: () {
                            setState(() {
                              todaysUnloads[selectedMachine]["products"][index]['color'] = Colors.green[300];
                            });
                          },
                        ),
                      );
                    },
                  ),
              )
            : Expanded(
                child: Center(
                  child: Text(
                    "Vyber automat.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
          ],
        )
      );

    }
    catch(e){
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dnešné vykládky'),
          backgroundColor: const Color(0xFF141414),
        ),
        backgroundColor: const Color(0xFF141414),
        body: Center(
          child: Text(
            "Chyba pri načítaní dát: $e",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}