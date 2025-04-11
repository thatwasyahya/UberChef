import 'package:flutter/material.dart';
import '../services/offers_database.dart';
import '../services/auth_database.dart';

class Offer {
  final int id;
  final int userId;
  final String image;
  final String time;
  final String address;
  final int persons;
  final String meal;
  final double price;
  final String description;

  Offer({
    required this.id,
    required this.userId,
    required this.image,
    required this.time,
    required this.address,
    required this.persons,
    required this.meal,
    required this.price,
    required this.description,
  });

  factory Offer.fromMap(Map<String, dynamic> json) => Offer(
    id: json['id'],
    userId: json['userId'],
    image: json['image'],
    time: json['time'],
    address: json['address'],
    persons: json['persons'],
    meal: json['meal'],
    price: json['price'],
    description: json['description'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'image': image,
    'time': time,
    'address': address,
    'persons': persons,
    'meal': meal,
    'price': price,
    'description': description,
  };
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with RouteAware {
  List<Offer> offers = [];
  int currentOfferIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final data = await OffersDatabase.instance.getAllOffers();
    if (data.isEmpty) {
      await _insertDummyOffers();
      final newData = await OffersDatabase.instance.getAllOffers();
      offers = newData.map((json) => Offer.fromMap(json)).toList();
    } else {
      offers = data.map((json) => Offer.fromMap(json)).toList();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _insertDummyOffers() async {
    // For demonstration, assume user with id 1 is creating these offers.
    final dummyOffers = [
      {
        'userId': 1,
        'image': 'assets/kitchen1.jpg',
        'time': '18:30',
        'address': '123 Rue de Paris, Paris',
        'persons': 4,
        'meal': 'Pizza',
        'price': 20.0,
        'description': 'Homemade pizza available tonight!',
      },
      {
        'userId': 1,
        'image': 'assets/kitchen2.jpg',
        'time': '12:00',
        'address': '456 Avenue de Lyon, Lyon',
        'persons': 2,
        'meal': 'Pasta',
        'price': 15.0,
        'description': 'Delicious pasta prepared by an expert chef.',
      },
    ];

    for (final offer in dummyOffers) {
      await OffersDatabase.instance.createOffer(offer);
    }
  }

  void _swipeLeft() {
    setState(() {
      currentOfferIndex = (currentOfferIndex + 1) % offers.length;
    });
  }

  void _swipeRight() {
    // In a real app, mark the offer as "proposed" or save a "like".
    setState(() {
      currentOfferIndex = (currentOfferIndex + 1) % offers.length;
    });
  }

  // To update the offers when returning from another screen.
  @override
  void didPopNext() {
    _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (offers.isEmpty) {
      return const Center(child: Text('No offers available'));
    }
    final offer = offers[currentOfferIndex];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Offers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(255, 212, 186, 1.0),
              const Color.fromRGBO(255, 239, 232, 0.94),
              Colors.white,
            ],
            stops: const [0.1, 0.5, 0.9],
          ),
        ),
        child: Center(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: AuthDatabase.instance.getUserById(offer.userId),
            builder: (context, snapshot) {
              Widget userInfo;
              if (snapshot.connectionState == ConnectionState.waiting) {
                userInfo = const CircularProgressIndicator();
              } else if (snapshot.hasData && snapshot.data != null) {
                final user = snapshot.data!;
                userInfo = Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user['profilePicture'] != null
                          ? AssetImage(user['profilePicture'])
                          : const AssetImage('assets/profile_placeholder.png'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${user['stars'] ?? 0.0} ⭐',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              } else {
                userInfo = const SizedBox();
              }

              return GestureDetector(
                onPanEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 0) {
                    _swipeRight();
                  } else {
                    _swipeLeft();
                  }
                },
                child: Card(
                  elevation: 8,
                  color: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.fromLTRB(13, 80, 13, 20),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.73,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              offer.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        userInfo,
                        const SizedBox(height: 8),
                        Text('Meal: ${offer.meal}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Time: ${offer.time}', style: const TextStyle(color: Colors.white)),
                        Text('Address: ${offer.address}', style: const TextStyle(color: Colors.white)),
                        Text('Persons: ${offer.persons}', style: const TextStyle(color: Colors.white)),
                        Text('Price: \$${offer.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(offer.description, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
