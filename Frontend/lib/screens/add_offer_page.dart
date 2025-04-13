import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/offers_database.dart';

class AddOfferPage extends StatefulWidget {
  final int userId; // The id of the currently logged-in user.
  const AddOfferPage({super.key, required this.userId});

  @override
  State<AddOfferPage> createState() => _AddOfferPageState();
}

class _AddOfferPageState extends State<AddOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _personsController = TextEditingController();
  final TextEditingController _mealController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _offerImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickOfferImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _offerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOffer() async {
    if (_formKey.currentState!.validate() && _offerImage != null) {
      final newOffer = {
        'userId': widget.userId,
        'image': _offerImage!.path,
        'time': _timeController.text,
        'address': _addressController.text,
        'persons': int.tryParse(_personsController.text) ?? 1,
        'meal': _mealController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'description': _descriptionController.text,
      };

      final result = await OffersDatabase.instance.createOffer(newOffer);
      if (result > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer published successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish offer.')),
        );
      }
    } else if (_offerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a kitchen image.')),
      );
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _addressController.dispose();
    _personsController.dispose();
    _mealController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Publier une offre',
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: Colors.black87
          ),
        ),
      ),
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du repas',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image selection with improved UI
                  GestureDetector(
                    onTap: _pickOfferImage,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _offerImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _offerImage!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.deepOrange.withOpacity(0.7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ajouter une photo de votre cuisine',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Une bonne photo aide à attirer les clients',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main dish info row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _mealController,
                          label: 'Plat proposé',
                          hint: 'ex: Couscous, Pizza...',
                          icon: Icons.restaurant_menu,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Veuillez indiquer le plat'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Prix (€)',
                          hint: 'ex: 15.00',
                          icon: Icons.euro,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Indiquez le prix'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time and persons row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _timeController,
                          label: 'Heure',
                          hint: 'ex: 18:30',
                          icon: Icons.access_time,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Indiquez l\'heure'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _personsController,
                          label: 'Personnes',
                          hint: 'ex: 4',
                          icon: Icons.people,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Nb. personnes'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Address field
                  _buildTextField(
                    controller: _addressController,
                    label: 'Adresse',
                    hint: 'ex: 123 Rue de Paris, Paris',
                    icon: Icons.location_on,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Veuillez indiquer l\'adresse'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Description field
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Décrivez votre plat et votre offre...',
                    icon: Icons.description,
                    maxLines: 4,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ajoutez une description'
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitOffer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.publish, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Publier l\'offre',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.lato(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.deepOrange.withOpacity(0.7)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
