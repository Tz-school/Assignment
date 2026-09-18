import 'package:flutter/material.dart';
import '../model/hiring_poster_model.dart';
import '../model/industry_partner_model.dart';
import '../service/database_service.dart';
import 'location_picker_screen.dart';

class PosterFormSheet extends StatefulWidget {
  final int? userId;
  final IndustryPartner? partner;
  final HiringPoster? posterToEdit;
  final VoidCallback onSuccess;

  const PosterFormSheet({
    super.key,
    required this.userId,
    required this.partner,
    this.posterToEdit,
    required this.onSuccess,
  });

  @override
  State<PosterFormSheet> createState() => _PosterFormSheetState();
}

class _PosterFormSheetState extends State<PosterFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _contactController;
  late TextEditingController _titleController;
  late TextEditingController _descController;

  bool _isSaving = false;

  bool get _isEditing => widget.posterToEdit != null;

  @override
  void initState() {
    super.initState();

    final p = widget.posterToEdit;

    _companyController = TextEditingController(
      text: p?.companyName ?? widget.partner?.companyName ?? '',
    );

    _emailController = TextEditingController(
      text: p?.email ?? widget.partner?.email ?? '',
    );

    _addressController = TextEditingController(
      text: p?.address ?? widget.partner?.location ?? '',
    );

    _stateController = TextEditingController(
      text: p?.state ?? widget.partner?.state ?? '',
    );

    _contactController = TextEditingController(
      text: p?.contactNumber ?? widget.partner?.contactNumber ?? '',
    );

    _titleController = TextEditingController(
      text: p?.title ?? '',
    );

    _descController = TextEditingController(
      text: p?.description ?? '',
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _contactController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Open the same map used by Resume Builder
  Future<void> _pickLocation() async {
    final SelectedLocation? result =
    await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result == null) return;

    setState(() {
      _addressController.text = result.address;
      _stateController.text = result.state;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location from the map first.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final posterData = HiringPoster(
        id: widget.posterToEdit?.id,
        userId: widget.userId ?? widget.posterToEdit?.userId,
        companyName: _companyController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        state: _stateController.text.trim(),
        contactNumber: _contactController.text.trim(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imagePath: '',
        datePosted: widget.posterToEdit?.datePosted ??
            DateTime.now().toIso8601String().split('T').first,
      );

      if (_isEditing) {
        await DatabaseService().updateHiringPoster(posterData);
      } else {
        await DatabaseService().insertHiringPoster(posterData);
      }

      widget.onSuccess();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Poster updated successfully!'
                : 'Hiring poster published successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving poster: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? 'Edit Hiring Poster'
                    : 'Create Hiring Poster',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Company Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 8),

              // Company name
              TextFormField(
                controller: _companyController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Company Email / Gmail',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              // Address
              TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Company Address / Location',
                  hintText: 'Select location from map',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.map,
                      color: Colors.indigo,
                    ),
                    onPressed: _pickLocation,
                  ),
                  filled: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select company location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // State
              TextFormField(
                controller: _stateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'State',
                  hintText: 'Automatically detected from location',
                  prefixIcon: Icon(Icons.map),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'State is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Contact
              TextFormField(
                controller: _contactController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Job Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 8),

              // Job title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title / Position',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter job title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description & Requirements',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter description & requirements';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Save / Publish
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        _isEditing
                            ? Icons.save
                            : Icons.publish,
                      ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (_isEditing
                            ? 'Save Changes'
                            : 'Publish Poster'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}