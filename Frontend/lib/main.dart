// lib/main.dart
import 'package:flutter/material.dart';
import 'services/mock_backend.dart';

void main() {
  runApp(UberChefApp());
}

class UberChefApp extends StatelessWidget {
  const UberChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UberChef',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MockBackend _backend = MockBackend();
  late Future<List<Map<String, dynamic>>> _annoncesFuture;

  @override
  void initState() {
    super.initState();
    _annoncesFuture = _backend.fetchAnnonces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UberChef - Annonces'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _annoncesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final annonces = snapshot.data!;
          return ListView.builder(
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final annonce = annonces[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(annonce['title']),
                  subtitle: Text(
                      '${annonce['description']}\nPrix: ${annonce['price']}€ - Heure: ${annonce['time']}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
