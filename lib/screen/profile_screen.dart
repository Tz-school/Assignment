import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as handler;
import '../service/database_service.dart';

const List<String> kMalaysianStates = [
  'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 'Pahang',
  'Perak', 'Perlis', 'Pulau Pinang', 'Sabah', 'Sarawak', 'Selangor',
  'Terengganu', 'Kuala Lumpur', 'Labuan', 'Putrajaya',
];

/// Sentinel dropdown entry. Picking it doesn't set a state directly -- it
/// triggers GPS detection instead.
const String kSelectByLocationOption = '📍 Select by location';

/// Approximate centroid of each Malaysian state/territory, used to work out
/// which one is nearest to the user's current GPS position. These are
/// rough midpoints for "nearest state" purposes only, not precise borders --
/// readings near a state boundary may occasionally pick the neighbour.
class _StateCoordinate {
  final String name;
  final double latitude;
  final double longitude;
  const _StateCoordinate(this.name, this.latitude, this.longitude);
}

const List<_StateCoordinate> kMalaysianStateCoordinates = [
  _StateCoordinate('Johor', 1.9200, 102.9238),
  _StateCoordinate('Kedah', 6.1184, 100.3685),
  _StateCoordinate('Kelantan', 5.1802, 102.1450),
  _StateCoordinate('Melaka', 2.1896, 102.2501),
  _StateCoordinate('Negeri Sembilan', 2.7259, 101.9424),
  _StateCoordinate('Pahang', 3.8126, 102.4381),
  _StateCoordinate('Perak', 4.5921, 101.0901),
  _StateCoordinate('Perlis', 6.4449, 100.2048),
  _StateCoordinate('Pulau Pinang', 5.4141, 100.3288),
  _StateCoordinate('Sabah', 5.9788, 116.0753),
  _StateCoordinate('Sarawak', 1.5533, 110.3592),
  _StateCoordinate('Selangor', 3.0738, 101.5183),
  _StateCoordinate('Terengganu', 5.3117, 103.1324),
  _StateCoordinate('Kuala Lumpur', 3.1390, 101.6869),
  _StateCoordinate('Labuan', 5.2831, 115.2308),
  _StateCoordinate('Putrajaya', 2.9264, 101.6964),
];

/// Haversine distance between two lat/lng points, in metres.
double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

class EditProfileScreen extends StatefulWidget {
  final String username;
  const EditProfileScreen({super.key, required this.username});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController =
  TextEditingController(text: widget.username);
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedState;
  bool _isDetectingState = false;
  String? _stateDetectionMessage; // inline feedback shown under the dropdown
  String? _photoPath; // local file path of the profile photo, if any
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService().getUserProfile(widget.username);
    if (mounted) {
      setState(() {
        _fullNameController.text = profile?['name'] ?? '';
        _emailController.text = profile?['email'] ?? '';
        _phoneController.text = profile?['phone'] ?? '';
        _selectedState = profile?['state'] as String?;
        _photoPath = profile?['photoPath'] as String?;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    // Let the user choose between camera and gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    // Copy the picked image into permanent app storage so it survives
    // beyond the OS's temporary picker cache.
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${widget.username}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() => _photoPath = savedImage.path);
  }

  // Uses the `location` + `permission_handler` packages (see Practical 13)
  // to read the device's current GPS position, then picks whichever
  // Malaysian state centroid is closest by straight-line distance.
  Future<void> _selectStateByLocation() async {
    setState(() {
      _isDetectingState = true;
      _stateDetectionMessage = null;
    });
    try {
      final locationService = loc.Location();

      bool gpsEnabled = await locationService.serviceEnabled();
      if (!gpsEnabled) {
        gpsEnabled = await locationService.requestService();
        if (!gpsEnabled) {
          setState(() => _stateDetectionMessage = 'Please enable GPS/location services.');
          return;
        }
      }

      handler.PermissionStatus permissionStatus =
      await handler.Permission.locationWhenInUse.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await handler.Permission.locationWhenInUse.request();
        if (!permissionStatus.isGranted) {
          setState(() =>
          _stateDetectionMessage = 'Location permission is required to detect your state.');
          return;
        }
      }

      final currentLocation = await locationService.getLocation();
      final userLat = currentLocation.latitude;
      final userLng = currentLocation.longitude;
      if (userLat == null || userLng == null) return;

      String? nearestState;
      double? nearestDistance;
      for (final state in kMalaysianStateCoordinates) {
        final distance = _distanceInMeters(userLat, userLng, state.latitude, state.longitude);
        if (nearestDistance == null || distance < nearestDistance) {
          nearestDistance = distance;
          nearestState = state.name;
        }
      }

      if (nearestState != null) {
        setState(() {
          _selectedState = nearestState;
          _stateDetectionMessage = 'Detected "$nearestState" based on your current location.';
        });
      }
    } catch (e) {
      setState(() => _stateDetectionMessage = 'Could not detect location: $e');
    } finally {
      setState(() => _isDetectingState = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    await DatabaseService().updateUserProfile(
      widget.username,
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      state: _selectedState,
      photoPath: _photoPath,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
      // Stay on the Edit Profile page - no Navigator.pop here.
    }
  }

  void _showResetPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true, obscureNew = true, obscureConfirm = true;
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    // Inline error - always visible, never hidden behind the dialog
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    final current = currentPasswordController.text;
                    final newPass = newPasswordController.text;
                    final confirm = confirmPasswordController.text;

                    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                      setDialogState(() => errorText = 'Please fill in all fields.');
                      return;
                    }
                    if (newPass.length < 4) {
                      setDialogState(() => errorText = 'New password must be at least 4 characters.');
                      return;
                    }
                    if (newPass != confirm) {
                      setDialogState(() => errorText = 'New passwords do not match.');
                      return;
                    }

                    setDialogState(() {
                      isSubmitting = true;
                      errorText = null;
                    });

                    final success = await DatabaseService()
                        .changePassword(widget.username, current, newPass);

                    if (!success) {
                      setDialogState(() {
                        isSubmitting = false;
                        errorText = 'Current password is incorrect.';
                      });
                      return; // Halt - do not close the dialog
                    }

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.indigo,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null
                        ? const Icon(Icons.person, size: 48, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Change Photo'),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              enabled: false, // Username is the login identifier - keep it read-only here
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                labelText: 'State',
                prefixIcon: const Icon(Icons.map),
                border: const OutlineInputBorder(),
                suffixIcon: _isDetectingState
                    ? const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : null,
              ),
              items: [
                const DropdownMenuItem(
                  value: kSelectByLocationOption,
                  child: Text(
                    kSelectByLocationOption,
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                ),
                ...kMalaysianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: _isDetectingState
                  ? null
                  : (val) {
                if (val == kSelectByLocationOption) {
                  // Don't select the sentinel itself - detect instead.
                  _selectStateByLocation();
                } else {
                  setState(() {
                    _selectedState = val;
                    _stateDetectionMessage = null;
                  });
                }
              },
            ),
            if (_stateDetectionMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _stateDetectionMessage!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showResetPasswordDialog,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Reset Password'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.indigo),
                foregroundColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}