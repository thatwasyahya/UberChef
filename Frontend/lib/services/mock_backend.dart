// lib/services/mock_backend.dart
import 'dart:async';

class MockBackend {
  // Simule une requête pour récupérer des annonces
  Future<List<Map<String, dynamic>>> fetchAnnonces() async {
    // Simule un délai réseau
    await Future.delayed(Duration(seconds: 2));

    // Retourne une liste d'exemples d'annonces
    return [
      {
        'title': 'Pizza maison',
        'price': 15.0,
        'description': 'Chef amateur propose une pizza napolitaine.',
        'address': '12 rue de la Cuisine, Paris',
        'time': '19:00',
      },
      {
        'title': 'Tacos gourmet',
        'price': 12.0,
        'description': 'Tacos préparé par un chef professionnel.',
        'address': '35 avenue de la Gastronomie, Lyon',
        'time': '12:30',
      },
    ];
  }
}
