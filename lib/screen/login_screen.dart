import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../model/industry_partner_model.dart';
import '../service/database_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Industry Specific Controllers
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isRegistering = false;
  String _selectedRole = 'student'; // 'student' or 'industry'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFetchingLocation = false;
  File? _companyPhoto;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Validates digits typed after +60 (8 to 10 digits starting with 1-9)
  bool _validateMalaysiaPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegExp = RegExp(r'^[1-9][0-9]{7,9}$');
    return phoneRegExp.hasMatch(cleanPhone);
  }

  Future<void> _pickCompanyPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _companyPhoto = File(image.path);
      });
    }
  }

  Future<void> _generateLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
      );
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? '${position.latitude}, ${position.longitude}';
        setState(() {
          _locationController.text = address;
        });
      } else {
        setState(() {
          _locationController.text = '${position.latitude}, ${position.longitude}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  void _submitForm() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_isRegistering) {
      final confirmPassword = _confirmPasswordController.text.trim();

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      if (_selectedRole == 'industry') {
        final rawContact = _contactController.text.trim();

        if (_companyNameController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            rawContact.isEmpty ||
            _locationController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all industry partner fields')),
          );
          return;
        }

        // Validate contact number typed after +60
        if (!_validateMalaysiaPhone(rawContact)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter a valid phone number (e.g. 123456789)'),
            ),
          );
          return;
        }

        if (_companyPhoto == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a company photo')),
          );
          return;
        }

        try {
          // Store fully formatted phone number (+60XXXXXXXXX)
          final fullContactNumber = '+60$rawContact';

          final partner = IndustryPartner(
            companyName: _companyNameController.text.trim(),
            email: _emailController.text.trim(),
            contactNumber: fullContactNumber,
            location: _locationController.text.trim(),
            photoPath: _companyPhoto!.path,
          );

          await DatabaseService().registerIndustryUser(
            username: username,
            password: password,
            partner: partner,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Industry Partner registration successful!')),
          );
          _navigateToMain(username: username, role: 'industry');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already exists!')),
          );
        }
      } else {
        try {
          await DatabaseService().registerUser(username, password, 'student');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Logging in...')),
          );
          _navigateToMain(username: username, role: 'student');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already exists!')),
          );
        }
      }
    } else {
      if (username == 'admin' && password == 'admin123') {
        _navigateToMain(username: 'System Admin', role: 'admin');
        return;
      }

      final user = await DatabaseService().loginUser(username, password);
      if (user != null) {
        _navigateToMain(username: user['username'], role: user['role']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    }
  }

  void _navigateToMain({required String username, required String role}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(userRole: role, username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    _isRegistering
                        ? (_selectedRole == 'industry'
                        ? 'Create Industry Account'
                        : 'Create Student Account')
                        : 'Career & Industry Portal',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isRegistering) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'student',
                          label: Text('Student'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 'industry',
                          label: Text('Industry Partner'),
                          icon: Icon(Icons.business),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_isRegistering && _selectedRole == 'industry') ...[
                    Center(
                      child: GestureDetector(
                        onTap: _pickCompanyPhoto,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.indigo.shade50,
                          backgroundImage:
                          _companyPhoto != null ? FileImage(_companyPhoto!) : null,
                          child: _companyPhoto == null
                              ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.indigo),
                              Text('Photo', style: TextStyle(fontSize: 12)),
                            ],
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company / Industry Name',
                        prefixIcon: Icon(Icons.domain),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Company Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        prefixText: '+60 ',
                        prefixStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: '123456789',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: _isFetchingLocation
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.my_location, color: Colors.indigo),
                          onPressed: _generateLocation,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isRegistering) ...[
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isRegistering ? 'Register' : 'Login',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                      });
                    },
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login here'
                          : "Don't have an account? Register here",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}