// lib/screens/profile_creation_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_database.dart';
import 'main_page.dart';

class ProfileCreationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileCreationScreen({super.key, required this.user});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  List<String> _addressSuggestions = [];
  DateTime? _selectedDate;
  Timer? _debounce;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user['name'] ?? '';
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
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
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
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving location: $e')),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedUser = {
        'id': widget.user['id'],
        'email': widget.user['email'],
        'name': _fullNameController.text,
        'password': widget.user['password'],
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'dateOfBirth': _dobController.text,
        'profilePicture': _profileImage?.path,
      };

      final result = await AuthDatabase.instance.updateUser(updatedUser);
      if (result > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Go To Main Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Complete Your Profile',
                          style: GoogleFonts.lato(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white10,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickProfilePicture,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black,
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(_fullNameController, 'Full Name'),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _addressController,
                        'Address',
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
                      ),
                      if (_addressSuggestions.isNotEmpty)
                        ..._addressSuggestions.map((suggestion) => ListTile(
                          title: Text(suggestion, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            _addressController.text = suggestion;
                            setState(() => _addressSuggestions = []);
                          },
                        )),
                      const SizedBox(height: 16),
                      _buildTextField(_bioController, 'Bio'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Profile',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        void Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: label == 'Address'
            ? IconButton(
          icon: const Icon(Icons.my_location, color: Colors.white),
          onPressed: _getAddressFromCurrentLocation,
        )
            : null,
      ),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Please enter your $label'
          : null,
    );
  }
}
