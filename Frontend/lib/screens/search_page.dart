import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/offers_database.dart';
import '../services/auth_database.dart';
import '../widgets/shimmer_effect.dart';

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
  final List<String>? tags;

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
    this.tags,
  });

  factory Offer.fromMap(Map<String, dynamic> json) => Offer(
    id: json['id'],
    userId: json['userId'],
    image: json['image'],
    time: json['time'],
    address: json['address'],
    persons: json['persons'],
    meal: json['meal'],
    price: json['price'].toDouble(),
    description: json['description'],
    tags:
        json['tags'] != null
            ? json['tags'] is String
                ? List<String>.from(jsonDecode(json['tags']))
                : List<String>.from(json['tags'])
            : ['Fait maison', 'Local'],
  );
}

class SwipeableCard extends StatefulWidget {
  final Offer offer;
  final VoidCallback onSwiped;
  final VoidCallback onLiked;
  final VoidCallback onDetail;

  const SwipeableCard({
    super.key,
    required this.offer,
    required this.onSwiped,
    required this.onLiked,
    required this.onDetail,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  double _angle = 0.0;
  late AnimationController _animationController;
  late Animation<Offset> _animationOffset;
  late Animation<double> _animationAngle;
  bool _isDetailExpanded = false;
  double _swipeProgress = 0.0;
  String _swipeDirection = '';
  double _scale = 1.0;
  bool _isDragging = false;

  // Seuil adapté pour un meilleur swipe
  late double _swipeThreshold;

  static const double rotationFactor = 0.10;
  static const double maxRotation = 0.25;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.addListener(() {
      setState(() {
        _offset = _animationOffset.value;
        _angle = _animationAngle.value;
      });
    });

    // Écouter la fin de l'animation pour déclencher les actions nécessaires
    _animationController.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculer le seuil en fonction de la largeur de l'écran
    _swipeThreshold = MediaQuery.of(context).size.width * 0.2;
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_handleAnimationStatus);
    _animationController.dispose();
    super.dispose();
  }

  // Gestionnaire unifié pour tous les statuts d'animation
  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_offset.dx.abs() >= _swipeThreshold) {
        if (_offset.dx > 0) {
          widget.onLiked();
        } else {
          widget.onSwiped();
        }
      }
    }
  }

  Widget _buildOfferImage() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
      child:
          widget.offer.image.startsWith('')
              ? Image.asset(
                widget.offer.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder:
                    (context, error, stackTrace) => _buildErrorImage(),
              )
              : Image.network(
                widget.offer.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.deepOrange,
                      ),
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => _buildErrorImage(),
              ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Image non disponible',
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSwipeState(Offset offset) {
    setState(() {
      _swipeProgress = (offset.dx.abs() / _swipeThreshold).clamp(0.0, 1.0);
      _swipeDirection = offset.dx > 0 ? 'right' : 'left';

      // Rotation plus naturelle avec effet de ressort progressif
      final rotationAmount =
          (offset.dx / MediaQuery.of(context).size.width) * rotationFactor;
      _angle = rotationAmount.clamp(-maxRotation, maxRotation);

      // Échelle dynamique pendant le glissement
      _scale = 1.0 - (_swipeProgress * 0.05);
    });
  }

  void _animateReset() {
    _animationOffset = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationAngle = Tween<double>(begin: _angle, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.reset();
    _animationController.forward();
  }

  void _animateSwipe(String direction) {
    final endX =
        direction == 'right'
            ? MediaQuery.of(context).size.width * 1.5
            : -MediaQuery.of(context).size.width * 1.5;

    _animationOffset = Tween<Offset>(
      begin: _offset,
      end: Offset(endX, _offset.dy),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _animationAngle = Tween<double>(
      begin: _angle,
      end: direction == 'right' ? maxRotation : -maxRotation,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    HapticFeedback.mediumImpact();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.65;

    return GestureDetector(
      onPanStart: (details) {
        if (_isDetailExpanded) return;
        setState(() {
          _isDragging = true;
        });
        HapticFeedback.lightImpact();
      },
      onPanUpdate: (details) {
        if (!_isDetailExpanded) {
          setState(() {
            _offset += details.delta;
            _updateSwipeState(_offset);
          });
        }
      },
      onPanEnd: (details) {
        if (_isDetailExpanded) return;

        setState(() {
          _isDragging = false;
        });

        // Calcul de la vélocité et décision de swipe plus précis
        final velocity = details.velocity.pixelsPerSecond.dx;
        final isQuickSwipe =
            velocity.abs() > 800; // Augmenter pour les gestes rapides

        // Déterminer si on doit faire un swipe complet
        final shouldCompleteSwipe =
            _offset.dx.abs() > _swipeThreshold || isQuickSwipe;

        if (shouldCompleteSwipe) {
          final direction =
              (_offset.dx > 0 || (isQuickSwipe && velocity > 0))
                  ? 'right'
                  : 'left';
          _animateSwipe(direction);
        } else {
          _animateReset();
        }
      },
      onTap: () {
        if (_offset.dx.abs() < 20) {
          setState(() {
            _isDetailExpanded = !_isDetailExpanded;
          });
          widget.onDetail();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isDetailExpanded ? cardHeight + 80 : cardHeight,
        child: Stack(
          children: [
            // La suite du contenu de la carte est identique...
            AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _scale,
              child: Transform.translate(
                offset: _offset,
                child: Transform.rotate(
                  angle: _angle,
                  child: Card(
                    // Le reste du widget reste inchangé...
                    elevation: 8 + (_swipeProgress * 4),
                    // Élévation dynamique
                    shadowColor:
                        _swipeDirection == 'right'
                            ? Colors.green.withOpacity(0.5 * _swipeProgress)
                            : Colors.red.withOpacity(0.5 * _swipeProgress),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border:
                            _swipeProgress > 0.2
                                ? Border.all(
                                  color:
                                      _swipeDirection == 'right'
                                          ? Colors.green.withOpacity(
                                            _swipeProgress,
                                          )
                                          : Colors.red.withOpacity(
                                            _swipeProgress,
                                          ),
                                  width: 3 * _swipeProgress,
                                )
                                : null,
                      ),
                      width: double.infinity,
                      height: _isDetailExpanded ? cardHeight + 80 : cardHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image section
                          Expanded(
                            flex: 7,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Image principale
                                Hero(
                                  tag: 'offer_image_${widget.offer.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                    child: _buildOfferImage(),
                                  ),
                                ),

                                // Overlay gradient pour le texte
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Bouton favori
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          widget.onLiked();
                                        },
                                        customBorder: const CircleBorder(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.favorite_border,
                                            color: Colors.deepOrange,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Prix dans un badge
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange,
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "${widget.offer.price.toStringAsFixed(2)} €",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                // Nom du repas
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.offer.meal,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 3.0,
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        children:
                                            widget.offer.tags
                                                ?.map(
                                                  (tag) => Chip(
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    label: Text(
                                                      tag,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    backgroundColor: Colors
                                                        .deepOrange
                                                        .withOpacity(0.7),
                                                    padding: EdgeInsets.zero,
                                                    labelPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 0,
                                                        ),
                                                  ),
                                                )
                                                .toList() ??
                                            [],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content section
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User info
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: AuthDatabase.instance.getUserById(
                                      widget.offer.userId,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return ShimmerEffect(
                                          child: Row(
                                            children: [
                                              const CircleAvatar(radius: 20),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 100,
                                                    height: 14,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    width: 60,
                                                    height: 10,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final user = snapshot.data!;
                                        return Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  Colors.deepOrange.shade100,
                                              child: Text(
                                                (user['name'] as String)
                                                        .isNotEmpty
                                                    ? user['name']
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepOrange,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user['name'],
                                                  style: GoogleFonts.montserrat(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star_rounded,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${user['stars'] ?? 4.5}',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade800,
                                                          ),
                                                    ),
                                                    Text(
                                                      ' (${(user['reviewCount'] ?? 42)})',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 12,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.deepOrange
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.message_rounded,
                                                    color: Colors.deepOrange,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Contacter',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Colors.deepOrange,
                                                          fontSize: 13,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return const SizedBox();
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Info details
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.access_time_rounded,
                                                  widget.offer.time,
                                                  Colors.blue.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.people_alt_rounded,
                                                  "${widget.offer.persons} pers",
                                                  Colors.green.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.kitchen_rounded,
                                                  "Dispo",
                                                  Colors.amber.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _infoItem(
                                            Icons.location_on_rounded,
                                            widget.offer.address,
                                            Colors.red.shade700,
                                            fullWidth: true,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Indicateur de swipe (droite/gauche) - correction du duplicata
            if (_offset.dx.abs() > 20 && !_isDetailExpanded)
              Positioned(
                top: 50,
                right: _swipeDirection == 'left' ? null : 20,
                left: _swipeDirection == 'right' ? null : 20,
                child: AnimatedOpacity(
                  opacity: _swipeProgress > 0.1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _swipeDirection == 'right'
                              ? Colors.green.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color:
                            _swipeDirection == 'right'
                                ? Colors.green
                                : Colors.red,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_swipeDirection == 'right'
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _swipeDirection == 'right'
                              ? Icons.favorite_rounded
                              : Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _swipeDirection == 'right' ? 'J\'AIME' : 'PASSER',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String text,
    Color iconColor, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: fullWidth ? TextAlign.left : TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with RouteAware, TickerProviderStateMixin {
  List<Offer> offers = [];
  List<Offer> filteredOffers = [];
  bool isLoading = true;
  late AnimationController _filterAnimationController;
  bool _showFilters = false;

  // Filtres
  String? selectedMealType;
  double? maxPrice;
  int? maxPersons;
  String? searchQuery;

  // Animation du filtre
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('Chargement des offres...');
      }

      final data = await OffersDatabase.instance.getAllOffers();
      if (kDebugMode) {
        print('Offres récupérées: ${data.length}');
      }

      if (data.isEmpty) {
        // Générer des offres de démonstration
        if (kDebugMode) {
          print('Aucune offre trouvée, création d\'offres de démonstration');
        }

        await _insertDummyOffers();
        final newData = await OffersDatabase.instance.getAllOffers();

        if (kDebugMode) {
          print('Nouvelles offres récupérées: ${newData.length}');
        }

        if (newData.isEmpty) {
          if (kDebugMode) {
            print('ERREUR: Échec de création des offres de démonstration');
          }
        } else {
          offers = newData.map((json) => Offer.fromMap(json)).toList();
        }
      } else {
        offers = data.map((json) => Offer.fromMap(json)).toList();
      }

      // Délai artificiel réduit
      await Future.delayed(const Duration(milliseconds: 300));

      if (kDebugMode) {
        print('Nombre d\'offres chargées: ${offers.length}');
      }

      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print('ERREUR lors du chargement des offres: $e');
      }

      // Gestion d'erreur améliorée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: _loadOffers,
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (kDebugMode) {
      print('Application des filtres...');
      print(
        'Filtres actuels: type=$selectedMealType, prix=$maxPrice, personnes=$maxPersons, recherche="$searchQuery"',
      );
    }

    setState(() {
      filteredOffers =
          offers.where((offer) {
            bool matchesMealType =
                selectedMealType == null ||
                offer.meal.toLowerCase().contains(
                  selectedMealType!.toLowerCase(),
                );
            bool matchesPrice = maxPrice == null || offer.price <= maxPrice!;
            bool matchesPersons =
                maxPersons == null || offer.persons <= maxPersons!;
            bool matchesQuery =
                searchQuery == null ||
                searchQuery!.isEmpty ||
                offer.meal.toLowerCase().contains(searchQuery!.toLowerCase()) ||
                offer.description.toLowerCase().contains(
                  searchQuery!.toLowerCase(),
                );

            bool matchesAll =
                matchesMealType &&
                matchesPrice &&
                matchesPersons &&
                matchesQuery;

            return matchesAll;
          }).toList();
    });

    if (kDebugMode) {
      print('Offres filtrées: ${filteredOffers.length}');
    }

    // Animer le rafraîchissement
    _refreshAnimationController.forward(from: 0);
  }

  void _resetFilters() {
    setState(() {
      selectedMealType = null;
      maxPrice = null;
      maxPersons = null;
      searchQuery = null;
      filteredOffers = offers;
    });

    _refreshAnimationController.forward(from: 0);
  }

  Future<void> _insertDummyOffers() async {
    if (kDebugMode) {
      print('Insertion d\'offres de démonstration...');
    }

    final List<Map<String, dynamic>> dummyOffers = [
      {
        'userId': 1,
        'image': 'assets/kitchen.jpg',
        'time': '18:30',
        'address': '123 Rue de Paris, Paris',
        'persons': 4,
        'meal': 'Pizza Napolitaine',
        'price': 20.0,
        'description':
            'Délicieuse pizza napolitaine avec mozzarella di bufala, sauce tomate maison et basilic frais. Cuite au four à bois traditionnel pour une pâte croustillante et moelleuse.',
        'tags': jsonEncode(['Italien', 'Fait maison']),
      },
      {
        'userId': 1,
        'image': 'assets/kitchen1.jpg',
        'time': '12:00',
        'address': '456 Avenue de Lyon, Lyon',
        'persons': 2,
        'meal': 'Pasta al Tartufo',
        'price': 15.0,
        'description':
            'Pâtes fraîches préparées par un chef expert avec truffe noire et parmesan affiné 24 mois. Une explosion de saveurs pour les amateurs de cuisine italienne authentique.',
        'tags': jsonEncode(['Italien', 'Gourmet']),
      },
      {
        'userId': 1,
        'image': 'assets/default_meal.jpg',
        'time': '19:00',
        'address': '789 Boulevard de Marseille, Marseille',
        'persons': 6,
        'meal': 'Couscous Royal',
        'price': 25.0,
        'description':
            'Un couscous traditionnel préparé selon une recette familiale avec agneau, poulet, merguez et légumes de saison. Portion généreuse idéale pour un repas convivial.',
        'tags': jsonEncode(['Maghrébin', 'Fait maison']),
      },
      {
        'userId': 1,
        'image': 'assets/profile_placeholder.png',
        'time': '20:30',
        'address': '101 Rue du Faubourg, Paris',
        'persons': 2,
        'meal': 'Sushi Assortiment',
        'price': 30.0,
        'description':
            'Plateau de 18 pièces de sushi fraîchement préparés avec du poisson de qualité sashimi. Accompagné de wasabi, gingembre mariné et sauce soja.',
        'tags': jsonEncode(['Japonais', 'Poisson']),
      },
      {
        'userId': 1,
        'image': 'assets/kitchen.jpg',
        'time': '12:30',
        'address': '202 Avenue des Champs, Paris',
        'persons': 3,
        'meal': 'Paëlla Valenciana',
        'price': 18.0,
        'description':
            'Authentique paëlla espagnole avec riz safrané, fruits de mer, poulet et légumes. Un plat familial coloré et savoureux pour voyager en Espagne depuis chez vous.',
        'tags': jsonEncode(['Espagnol', 'Fruits de mer']),
      },
    ];

    int insertedCount = 0;

    try {
      for (final offerData in dummyOffers) {
        final id = await OffersDatabase.instance.createOffer(offerData);
        if (id != null) insertedCount++;

        if (kDebugMode) {
          print('Insertion offre: ${offerData['meal']} => ID: $id');
        }
      }

      if (kDebugMode) {
        print('$insertedCount offres factices insérées avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERREUR lors de l\'insertion des offres : $e');
      }
      rethrow; // Propager l'erreur pour permettre la gestion en amont
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _filterAnimationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload after returning to this screen
    _loadOffers();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _showOfferDetails(Offer offer) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          offer.meal,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    offer.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    double size = 32,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  void _handleSwipe(Offer offer) {
    // Retour haptique avant de modifier l'état
    HapticFeedback.mediumImpact();

    setState(() {
      // Retirer l'offre de la liste filtrée
      filteredOffers.remove(offer);
    });

    // Forcer un rebuild du widget pour actualiser la pile de cartes
    Future.microtask(() {
      if (mounted) setState(() {});
    });

    // Afficher un message discret
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vous avez passé "${offer.meal}"'),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Appliquer la même modification à _handleLike
  void _handleLike(Offer offer) {
    HapticFeedback.mediumImpact();

    setState(() {
      filteredOffers.remove(offer);
    });

    // Forcer un rebuild immédiat
    Future.microtask(() {
      if (mounted) setState(() {});
    });

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text('Vous proposez vos services pour "${offer.meal}"'),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Contacter',
          textColor: Colors.white,
          onPressed: () {
            // Naviguer vers la page de messages
          },
        ),
      ),
    );

    // Si la liste est vide après le like, rafraîchir l'interface
    if (filteredOffers.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {}); // Force UI update
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildLoadingState()
          : filteredOffers.isEmpty
          ? _buildEmptyState()
          : _buildOffersList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicateur de chargement animé sans utiliser Lottie
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recherche des meilleures offres...',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Aucune offre disponible',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Revenez plus tard ou modifiez vos critères de recherche',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _resetFilters();
                _loadOffers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersList() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background pour les swipes
        if (filteredOffers.isEmpty)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Plus d\'offres disponibles',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Modifiez vos filtres ou actualisez pour voir de nouvelles offres',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _resetFilters();
                  _loadOffers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

        // Pile de cartes
        if (filteredOffers.isNotEmpty)
          Positioned.fill(
            child: Stack(
              alignment: Alignment.center,
              children:
                  filteredOffers
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final offer = entry.value;

                        // N'afficher que les cartes visibles (maximum 3)
                        if (index > 2) return const SizedBox.shrink();

                        return Positioned(
                          top: index * 6.0,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: 1.0,
                            child: Transform.scale(
                              scale: 1.0 - (index * 0.03),
                              alignment: Alignment.topCenter,
                              child: IgnorePointer(
                                // Important: seule la première carte est interactive
                                ignoring: index != 0,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: index == 0 ? 15.0 : 10.0,
                                  ),
                                  child: SwipeableCard(
                                    key: ValueKey("card_${offer.id}"),
                                    // Ajouter une clé unique
                                    offer: offer,
                                    onSwiped: () => _handleSwipe(offer),
                                    onLiked: () => _handleLike(offer),
                                    onDetail: () => _showOfferDetails(offer),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList()
                      .reversed
                      .toList(), // Renverser l'ordre pour que index 0 soit au-dessus
            ),
          ),
        // Actions boutons
        if (filteredOffers.isNotEmpty)
          Positioned(
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouton dislike
                _buildActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  onTap: () {
                    if (filteredOffers.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      _handleSwipe(filteredOffers[0]);
                    }
                  },
                ),

                const SizedBox(width: 24),

                // Bouton info
                _buildActionButton(
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  size: 24,
                  onTap: () {
                    if (filteredOffers.isNotEmpty) {
                      HapticFeedback.selectionClick();
                      _showOfferDetails(filteredOffers[0]);
                    }
                  },
                ),

                const SizedBox(width: 24),

                // Bouton like
                _buildActionButton(
                  icon: Icons.favorite,
                  color: Colors.green,
                  onTap: () {
                    if (filteredOffers.isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      _handleLike(filteredOffers[0]);
                    }
                  },
                ),
              ],
            ),
          ),

        // Indicateur de rafraîchissement
        // Indicateur de rafraîchissement
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _refreshAnimationController.isAnimating ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recherche mise à jour',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
