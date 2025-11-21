import 'package:flutter/material.dart';

class AdminAulasScreen extends StatelessWidget {
  const AdminAulasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.door_front_door, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Gestión de Aulas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Funcionalidad en desarrollo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
  }
}

