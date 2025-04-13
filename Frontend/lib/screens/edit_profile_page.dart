import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';


class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les champs de formulaire
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  // Image de profil
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  // Préférences
  final Map<String, bool> _preferences = {
    'Bavard': false,
    'Non-fumeur': false,
    'Musique': false,
    'Animaux acceptés': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(text: widget.userData['address']);
    _bioController = TextEditingController(text: widget.userData['bio']);
    _profileImagePath = widget.userData['profilePicture'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  ImageProvider _getProfileImage() {
    if (_profileImagePath == null) {
      return const AssetImage('assets/profile_placeholder.png');
    }

    if (_profileImagePath!.startsWith('assets/')) {
      return AssetImage(_profileImagePath!);
    } else {
      return FileImage(File(_profileImagePath!));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Changer la photo de profil',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepOrange),
              title: Text('Galerie', style: GoogleFonts.montserrat()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepOrange),
              title: Text('Caméra', style: GoogleFonts.montserrat()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Ici, vous implementeriez la connexion à votre base de données
        // pour sauvegarder les modifications

        // Simulons une opération asynchrone
        await Future.delayed(const Duration(seconds: 1));

        // Créez un nouveau Map avec les informations mises à jour
        final updatedData = Map<String, dynamic>.from(widget.userData);
        updatedData['name'] = _nameController.text;
        updatedData['email'] = _emailController.text;
        updatedData['phone'] = _phoneController.text;
        updatedData['address'] = _addressController.text;
        updatedData['bio'] = _bioController.text;
        updatedData['profilePicture'] = _profileImagePath;

        // Dans une vraie application, vous appelleriez votre service pour mettre à jour les données
        // Exemple: await AuthDatabase.instance.updateUser(updatedData);

        // Retourner les données mises à jour à la page précédente
        Navigator.pop(context, updatedData);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Enregistrer',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImageSection(),
              const SizedBox(height: 24),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildBioSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _getProfileImage(),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Changer la photo',
            style: GoogleFonts.montserrat(
              color: Colors.deepOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre numéro de téléphone';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre adresse';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos de moi',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Partagez quelque chose sur vous...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.montserrat(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes préférences',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPreferenceChip('Bavard', Icons.chat_bubble_outline),
            _buildPreferenceChip('Non-fumeur', Icons.smoke_free),
            _buildPreferenceChip('Musique', Icons.music_note),
            _buildPreferenceChip('Animaux acceptés', Icons.pets),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceChip(String label, IconData icon) {
    final bool isSelected = _preferences[label] ?? false;

    return FilterChip(
      selected: isSelected,
      selectedColor: Colors.deepOrange.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
      checkmarkColor: Colors.deepOrange,
      avatar: Icon(
        icon,
        color: isSelected ? Colors.deepOrange : Colors.grey[600],
        size: 18,
      ),
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          color: isSelected ? Colors.deepOrange : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      onSelected: (bool selected) {
        setState(() {
          _preferences[label] = selected;
        });
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepOrange),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.montserrat(fontSize: 16),
    );
  }
}