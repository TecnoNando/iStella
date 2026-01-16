import 'package:flutter/material.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Agenda y Horarios', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Próximamente disponible',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
