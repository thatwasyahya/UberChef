// lib/screens/profile_creation_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../services/auth_database.dart';
import 'main_page.dart';

class ProfileCreationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileCreationScreen({super.key, required this.user});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _addressSuggestions = [];
  DateTime? _selectedDate;
  Timer? _debounce;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Groupes de champs du formulaire pour l'approche par étapes
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Initialisation du nom si disponible
    _fullNameController.text = widget.user['name'] ?? '';

    // Précharger les suggestions d'adresse si le nom de la ville/pays est disponible
    if (widget.user['address'] != null) {
      _addressController.text = widget.user['address'];
      _getAddressSuggestions(widget.user['address']);
    }
  }

  Future<List<String>> _getAddressSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      final String url =
          'https://api-adresse.data.gouv.fr/search/?q=${Uri.encodeComponent(query)}&limit=5';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connexion Timeout'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] == null) return [];
        final features = data['features'] as List;
        return features.map((f) => f['properties']['label'] as String).toList();
      } else {
        if (kDebugMode) {
          print('API Error: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching address: $e');
      }
      return [];
    }
  }

  Future<void> _getAddressFromCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (!mounted) return;
          _showSnackBar('Accès à la localisation refusé', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressController.text =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
          _isLoading = false;
        });
        HapticFeedback.mediumImpact();
        _showSnackBar('Adresse détectée avec succès');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur lors de la récupération de la position: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfilePicture() async {
    HapticFeedback.lightImpact();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisissez une source',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Appareil photo',
                  source: ImageSource.camera,
                ),
                _imageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  source: ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection de l\'image', isError: true);
    }
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required ImageSource source
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orangeAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < _totalSteps - 1) {
        HapticFeedback.lightImpact();
        setState(() {
          _currentStep++;
        });
      } else {
        _submitProfile();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKeys[_currentStep].currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final updatedUser = {
        'id': widget.user['id'],
        'email': widget.user['email'],
        'name': _fullNameController.text,
        'password': widget.user['password'],
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'dateOfBirth': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '',
        'profilePicture': _profileImage?.path,
      };

      final result = await AuthDatabase.instance.updateUser(updatedUser);

      if (!mounted) return;

      if (result > 0) {
        _showSuccessAnimation();
      } else {
        _showSnackBar('Échec de la mise à jour du profil', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json',
              width: 200,
              height: 200,
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(const Duration(milliseconds: 2500), () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MainPage(),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Profil créé avec succès!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111111), Color(0xFF212121)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                _buildProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: _buildCurrentStep(),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Précédent',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            const Spacer(flex: 1),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
                  : Text(
                _currentStep == _totalSteps - 1 ? 'Terminer' : 'Suivant',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              splashRadius: 24,
            ),
          Expanded(
            child: Text(
              _getStepTitle(),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: _currentStep > 0 ? TextAlign.center : TextAlign.left,
            ),
          ),
          const SizedBox(width: 40), // Pour équilibrer avec le bouton retour
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Informations personnelles';
      case 1:
        return 'Coordonnées';
      case 2:
        return 'Votre biographie';
      case 3:
        return 'Photo de profil';
      default:
        return 'Créer votre profil';
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 8,
            width: MediaQuery.of(context).size.width *
                (_currentStep + 1) / _totalSteps * 0.9, // 0.9 pour compenser les paddings
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildContactInfoStep();
      case 2:
        return _buildBioStep();
      case 3:
        return _buildProfilePictureStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Nous avons besoin de quelques informations pour personnaliser votre expérience',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _fullNameController,
              label: 'Nom complet',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Veuillez entrer votre nom'
                  : null,
            ),
            const SizedBox(height: 20),
            _buildDatePickerField(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Comment pouvons-nous vous contacter?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 30),
            _buildInputField(
              controller: _phoneController,
              label: 'Numéro de téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                  return 'Format de téléphone invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildAddressField(),
            if (_addressSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _addressSuggestions.map((suggestion) =>
                      ListTile(
                        title: Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            )
                        ),
                        onTap: () {
                          setState(() {
                            _addressController.text = suggestion;
                            _addressSuggestions = [];
                          });
                          HapticFeedback.selectionClick();
                        },
                      )
                  ).toList(),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBioStep() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Parlez-nous un peu de vous',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _bioController,
              maxLines: 6,
              maxLength: 250,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Votre biographie',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade800.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                ),
                prefixIcon: const Icon(
                  Icons.edit_note,
                  color: Colors.orangeAccent,
                ),
                counterStyle: GoogleFonts.poppins(color: Colors.grey),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Ajoutez une courte biographie'
                  : null,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureStep() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Ajoutez une photo de profil pour personnaliser votre compte',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickProfilePicture,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orangeAccent,
                        width: 3,
                      ),
                      image: _profileImage != null
                          ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _profileImage == null
                        ? const Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.orangeAccent,
                    )
                        : null,
                  ),
                  if (_profileImage != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _profileImage == null
                  ? 'Touchez pour ajouter une photo'
                  : 'Touchez pour modifier votre photo',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: IgnorePointer(
        child: TextFormField(
          controller: _dobController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey.shade800.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
            ),
            prefixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.orangeAccent,
            ),
            suffixIcon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.orangeAccent,
            ),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Sélectionnez votre date de naissance'
              : null,
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        _buildInputField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.home_outlined,
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () async {
              if (value.isEmpty) {
                setState(() => _addressSuggestions = []);
                return;
              }
              try {
                final suggestions = await _getAddressSuggestions(value);
                if (mounted) {
                  setState(() => _addressSuggestions = suggestions);
                }
              } catch (_) {
                if (mounted) {
                  setState(() => _addressSuggestions = []);
                }
              }
            });
          },
          validator: (value) => (value == null || value.isEmpty)
              ? 'Veuillez entrer votre adresse'
              : null,
          suffixIcon: _isLoading
              ? Container(
            padding: const EdgeInsets.all(10),
            height: 20,
            width: 20,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.my_location, color: Colors.orangeAccent),
            onPressed: _getAddressFromCurrentLocation,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.poppins(color: Colors.white),
    decoration: InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.grey.shade800.withOpacity(0.5),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.orangeAccent,
    width: 2),
    ),
    prefixIcon: Icon(
    icon,
    color: Colors.orangeAccent,
    ),
    suffixIcon: suffixIcon,
    ),
    validator: validator,
    );
  }
}
