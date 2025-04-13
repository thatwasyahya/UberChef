// lib/screens/historique_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<OfferHistoryItem> _mockHistoryData = _generateMockData();
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Aimés', 'Ignorés', 'Consultés'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Favoris'),
            Tab(text: 'Ignorés'),
          ],
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(_mockHistoryData),
          _buildHistoryList(_mockHistoryData.where((item) => item.action == 'Aimé').toList()),
          _buildHistoryList(_mockHistoryData.where((item) => item.action == 'Ignoré').toList()),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<OfferHistoryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'Aucun historique disponible',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Explorez des offres pour commencer à remplir votre historique',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildLeadingIcon(item),
              title: Text(
                item.offerName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    item.restaurantName,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(item.date),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                '${item.discount}%',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              onTap: () {
                // Afficher les détails de l'offre
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Détails de ${item.offerName}')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingIcon(OfferHistoryItem item) {
    IconData iconData;
    Color backgroundColor;

    switch (item.action) {
      case 'Aimé':
        iconData = Icons.favorite;
        backgroundColor = Colors.green.shade100;
        break;
      case 'Ignoré':
        iconData = Icons.close;
        backgroundColor = Colors.red.shade100;
        break;
      default:
        iconData = Icons.visibility;
        backgroundColor = Colors.blue.shade100;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: backgroundColor.withOpacity(1).withRed(backgroundColor.red ~/ 2).withGreen(backgroundColor.green ~/ 2).withBlue(backgroundColor.blue ~/ 2),
      ),
    );
  }
}

class OfferHistoryItem {
  final String id;
  final String offerName;
  final String restaurantName;
  final DateTime date;
  final String action; // 'Aimé', 'Ignoré', 'Consulté'
  final int discount;

  OfferHistoryItem({
    required this.id,
    required this.offerName,
    required this.restaurantName,
    required this.date,
    required this.action,
    required this.discount,
  });
}

List<OfferHistoryItem> _generateMockData() {
  return [
    OfferHistoryItem(
      id: '1',
      offerName: 'Menu Gourmet',
      restaurantName: 'La Belle Assiette',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      action: 'Aimé',
      discount: 30,
    ),
    OfferHistoryItem(
      id: '2',
      offerName: 'Pizza Margherita',
      restaurantName: 'Pizzeria Napoli',
      date: DateTime.now().subtract(const Duration(days: 1)),
      action: 'Ignoré',
      discount: 25,
    ),
    OfferHistoryItem(
      id: '3',
      offerName: 'Burger Deluxe',
      restaurantName: 'Burger House',
      date: DateTime.now().subtract(const Duration(days: 2)),
      action: 'Consulté',
      discount: 40,
    ),
    OfferHistoryItem(
      id: '4',
      offerName: 'Salade César',
      restaurantName: 'Green Garden',
      date: DateTime.now().subtract(const Duration(days: 3)),
      action: 'Aimé',
      discount: 20,
    ),
    OfferHistoryItem(
      id: '5',
      offerName: 'Plat du jour',
      restaurantName: 'Bistro Parisien',
      date: DateTime.now().subtract(const Duration(days: 4)),
      action: 'Ignoré',
      discount: 35,
    ),
    OfferHistoryItem(
      id: '6',
      offerName: 'Menu Dégustation',
      restaurantName: 'Le Gourmet',
      date: DateTime.now().subtract(const Duration(days: 5)),
      action: 'Aimé',
      discount: 45,
    ),
    OfferHistoryItem(
      id: '7',
      offerName: 'Sushi Box',
      restaurantName: 'Tokyo Sushi',
      date: DateTime.now().subtract(const Duration(days: 6)),
      action: 'Consulté',
      discount: 15,
    ),
  ];
}