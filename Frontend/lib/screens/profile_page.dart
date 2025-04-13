import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // À ajouter dans pubspec.yaml
import '../services/auth_database.dart';
import 'edit_profile_page.dart'; // À créer

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool _expanded = false;
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Sarah L.',
      'date': '15 avril 2023',
      'rating': 5,
      'comment': 'Personne très sympathique et ponctuelle, je recommande !',
      'avatar': 'assets/avatars/user1.png',
    },
    {
      'name': 'Thomas M.',
      'date': '3 mars 2023',
      'rating': 4,
      'comment': 'Bonne expérience, repas super.',
      'avatar': 'assets/avatars/user2.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthDatabase.instance.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          user = userData;
          isLoading = false;

          // Ajoutons des données fictives pour la démonstration si elles n'existent pas
          user ??= {
            'name': 'Claire Martin',
            'stars': 4.8,
            'email': 'claire.martin@example.com',
            'phone': '+33 6 12 34 56 78',
            'address': 'Lyon, France',
            'bio':
                'Passionnée de cuisine et de voyages, je suis toujours à la recherche de nouvelles saveurs à partager !',
            'verified': true,
            'memberSince': 'Mai 2022',
            'ridesCompleted': 36,
            'profilePicture': 'assets/profile_placeholder.png',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  ImageProvider _getProfileImage() {
    if (user == null || user!['profilePicture'] == null) {
      return const AssetImage('assets/profile_placeholder.png');
    }

    final String path = user!['profilePicture'];

    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      // Éviction du cache pour forcer le rechargement de l'image
      return FileImage(File(path))..evict();
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Changer la photo de profil',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.deepOrange,
                  ),
                  title: Text('Galerie', style: GoogleFonts.montserrat()),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxWidth: 800,
                      );
                      if (image != null && mounted) {
                        setState(() {
                          if (user != null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chargement de l\'image en cours...'),
                                  duration: Duration(milliseconds: 500),
                                ),
                              );
                            }
                            user!['profilePicture'] = image.path;
                            // Force le widget à se reconstruire pour afficher la nouvelle image
                            setState(() {});
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo mise à jour avec succès'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la sélection: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.deepOrange,
                  ),
                  title: Text('Caméra', style: GoogleFonts.montserrat()),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? photo = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                        maxWidth: 800,
                        preferredCameraDevice: CameraDevice.front,
                      );
                      if (photo != null && mounted) {
                        setState(() {
                          // Ajout d'un indicateur de chargement
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Chargement de l\'image en cours...'),
                                duration: Duration(milliseconds: 500),
                              ),
                            );
                            user!['profilePicture'] = photo.path;
                            // Force le widget à se reconstruire pour afficher la nouvelle image
                            setState(() {});
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo mise à jour avec succès'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la capture: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(255, 212, 186, 1.0),
                      Color.fromRGBO(255, 239, 232, 0.94),
                      Colors.white,
                    ],
                    stops: [0.1, 0.5, 0.9],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              )
              : AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: CustomScrollView(
                  slivers: [
                    //totally transpaent little space app bar
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      expandedHeight: 100,
                      pinned: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeader(),
                        _buildTrustSection(),
                        _buildInfoCards(),
                        _buildBioSection(),
                        _buildPreferencesSection(),
                        _buildReviewsSection(),
                        const SizedBox(height: 100), // Padding en bas
                      ]),
                    ),
                  ],
                ),
              ),
    );
  }


  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Container principal pour le contenu du profil
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 60, bottom: 20),
          width: double.infinity,
          child: Column(
            children: [
              Text(
                user?['name'] ?? "Utilisateur",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    "${user?['stars'] ?? 0.0}",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    " • Membre depuis ${user?['memberSince'] ?? 'récemment'}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Badge de disponibilité
        Positioned(
          top: -80,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Disponible",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Photo de profil (placée en dernier pour un z-index plus élevé)
        Positioned(
          top: -50,
          child: Material(
            elevation: 99,
            shape: const CircleBorder(),
            clipBehavior: Clip.none,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _getProfileImage(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _showImageSourceDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Niveau de confiance",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustItem(
                Icons.verified_user,
                "Identité vérifiée",
                user?['verified'] == true,
              ),
              _buildTrustItem(Icons.phone, "Téléphone vérifié", true),
              _buildTrustItem(Icons.email, "Email vérifié", true),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                "${user?['mealsCompleted'] ?? 0} repas préparés",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text, bool isVerified) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isVerified ? Colors.deepOrange : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: isVerified ? Colors.grey[800] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          _infoCard(Icons.email, "Email", user?['email'] ?? ""),
          _infoCard(Icons.phone, "Téléphone", user?['phone'] ?? ""),
          _infoCard(Icons.location_on, "Adresse", user?['address'] ?? ""),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "À propos de moi",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: Colors.deepOrange,
                onPressed: () {
                  _showBioEditDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              user?['bio'] ?? "Aucune bio fournie.",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBioEditDialog() {
    final TextEditingController controller = TextEditingController(
      text: user?['bio'],
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Modifier votre bio',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Partagez quelque chose sur vous...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.montserrat(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (user != null) {
                      user!['bio'] = controller.text;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Enregistrer',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spécialités culinaires",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _animatedPreferenceItem(Icons.restaurant, "Cuisine française"),
              _animatedPreferenceItem(Icons.rice_bowl, "Végétarien"),
              _animatedPreferenceItem(Icons.local_fire_department, "Fusion"),
              _animatedPreferenceItem(Icons.public, "International"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _animatedPreferenceItem(IconData icon, String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 1.0, end: 1.0),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: _preferenceItem(icon, text),
          );
        },
        child: _preferenceItem(icon, text),
        onEnd: () {},
      ),
    );
  }

  Widget _preferenceItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.deepOrange),
        ),
        const SizedBox(height: 8),
        Text(text, style: GoogleFonts.montserrat(fontSize: 14)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Évaluations culinaires (${_reviews.length})",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Text(
                  _expanded ? "Voir moins" : "Voir tous",
                  style: GoogleFonts.montserrat(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._reviews
              .take(_expanded ? _reviews.length : 2)
              .map((review) => _reviewItem(review))
              .toList(),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userData: user!),
                  ),
                ).then((updatedData) {
                  if (updatedData != null) {
                    setState(() {
                      user = updatedData;
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Modifier mon profil de chef",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'avatar-${review['name']}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(review['avatar']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            review['date'],
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < (review['rating'] as int)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              review['comment'],
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
