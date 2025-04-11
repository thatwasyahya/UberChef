// lib/screens/add_offer_page.dart
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/offers_database.dart';

class AddOfferPage extends StatefulWidget {
  final int userId; // The id of the currently logged in user.
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
      appBar: AppBar(
        title: Text('Publish an Offer', style: GoogleFonts.lato()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickOfferImage,
                child: _offerImage != null
                    ? Image.file(
                  _offerImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Tap to select kitchen image')),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'e.g., 18:30',
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter the time' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter the address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _personsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Persons',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter number of persons' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mealController,
                decoration: const InputDecoration(
                  labelText: 'Meal',
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter the meal' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter the price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitOffer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Publish', style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
