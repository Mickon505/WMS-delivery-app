import 'package:flutter/material.dart';
import 'truck_load_screen.dart';
import 'vending_machines_screen.dart';
import 'vm_states.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Text('Hlavné menu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tlačidlo na nakládku
            _buildActionCard(
              context,
              'Nakládka do dodávky',
              Icons.local_shipping,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TruckLoadScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            // Tlačidlo na vykládku
            _buildActionCard(
              context,
              'Vykládka do automatu',
              Icons.outbox,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VendingMachinesScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            // Tlačidlo na Stav automatu
            _buildActionCard(
              context,
              'Stav',
              Icons.aod,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VendingMachineStatesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(113, 113, 113, 0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 50),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}