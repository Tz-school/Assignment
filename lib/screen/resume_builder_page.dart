import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/resume_model.dart';
import '../service/database_service.dart';
import '../service/supabase_service.dart';
import 'location_picker_screen.dart';


class ResumeHomeTab extends StatefulWidget {
  const ResumeHomeTab({super.key});

  @override
  State<ResumeHomeTab> createState() => _ResumeHomeTabState();
}

class _ResumeHomeTabState extends State<ResumeHomeTab> {
  List<ResumeData> _resumeList = [];
  bool _isLoading = true;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    try {
      final list = await DatabaseService().getAllResumes();
      if (mounted) {
        setState(() {
          _resumeList = list;
        });
      }
    } catch (e) {
      debugPrint('Error reading resumes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _createNewResume() async {
    final ResumeData? newData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResumeBuilderForm(),
      ),
    );

    if (newData != null) {
      try {

        int insertedId = await DatabaseService().insertResume(newData);


        await _supabaseService.insertResume(newData);

        await _loadResumes();

        if (!mounted) return;

        final savedResume = ResumeData(
          id: insertedId,
          profileImage: newData.profileImage,
          certificateImage: newData.certificateImage,
          fullName: newData.fullName,
          age: newData.age,
          gender: newData.gender,
          email: newData.email,
          phone: newData.phone,
          address: newData.address,
          summary: newData.summary,
          experience: newData.experience,
          education: newData.education,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumeResultPage(
              data: savedResume,
              onSave: (updatedData) async {
                await DatabaseService().updateResume(updatedData);
                await _supabaseService.updateResume(updatedData);
                _loadResumes();
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('Save error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save resume: $e')),
          );
        }
      }
    }
  }

  void _viewHistory() {
    if (_resumeList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved resumes found! Create one first.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeHistoryPage(
          resumeList: _resumeList,
          onUpdateList: _loadResumes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              'Total Saved Resumes: ${_resumeList.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewResume,
              icon: const Icon(Icons.add),
              label: const Text('Create New Resume'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _viewHistory,
              icon: const Icon(Icons.history),
              label: const Text('View Resume History'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}


class ResumeHistoryPage extends StatefulWidget {
  final List<ResumeData> resumeList;
  final VoidCallback onUpdateList;

  const ResumeHistoryPage({
    super.key,
    required this.resumeList,
    required this.onUpdateList,
  });

  @override
  State<ResumeHistoryPage> createState() => _ResumeHistoryPageState();
}

class _ResumeHistoryPageState extends State<ResumeHistoryPage> {
  final _supabaseService = SupabaseService();

  Future<void> _showDeleteDialog(BuildContext context, ResumeData resume) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Resume'),
          content: Text(
            'Are you sure you want to delete the resume for "${resume.fullName}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (resume.id != null) {
                  await DatabaseService().deleteResume(resume.id!);
                  await _supabaseService.deleteResume(resume.id!);
                }
                widget.onUpdateList();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Resume for ${resume.fullName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Resumes'),
      ),
      body: widget.resumeList.isEmpty
          ? const Center(child: Text('No resumes found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.resumeList.length,
        itemBuilder: (context, index) {
          final resume = widget.resumeList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: FileImage(resume.profileImage),
              ),
              title: Text(
                resume.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${resume.gender} • Age ${resume.age} • ${resume.email}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, resume),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResumeResultPage(
                      data: resume,
                      onSave: (updatedData) async {
                        await DatabaseService().updateResume(updatedData);
                        await _supabaseService.updateResume(updatedData);
                        widget.onUpdateList();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}





class ResumeBuilderForm extends StatefulWidget {
  final ResumeData? initialData;

  const ResumeBuilderForm({super.key, this.initialData});

  @override
  State<ResumeBuilderForm> createState() => _ResumeBuilderFormState();
}

class _ResumeBuilderFormState extends State<ResumeBuilderForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final _supabaseService = SupabaseService();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _summaryController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;

  String? _selectedGender;
  File? _profileImage;
  File? _certificateImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.fullName ?? '');
    _ageController = TextEditingController(text: widget.initialData?.age ?? '');
    _emailController = TextEditingController(text: widget.initialData?.email ?? '');
    _selectedGender = widget.initialData?.gender;

    String initialPhone = widget.initialData?.phone ?? '';
    if (initialPhone.startsWith('+60')) {
      initialPhone = initialPhone.replaceFirst('+60', '').trim();
    }
    _phoneController = TextEditingController(text: initialPhone);

    _addressController = TextEditingController(text: widget.initialData?.address ?? '');
    _summaryController = TextEditingController(text: widget.initialData?.summary ?? '');
    _experienceController = TextEditingController(text: widget.initialData?.experience ?? '');
    _educationController = TextEditingController(text: widget.initialData?.education ?? '');
    _profileImage = widget.initialData?.profileImage;
    _certificateImage = widget.initialData?.certificateImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCertificate) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (isCertificate) {
        if (!pickedFile.path.toLowerCase().endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload the certificate in PNG format only.')),
          );
          return;
        }
        setState(() => _certificateImage = File(pickedFile.path));
      } else {
        setState(() => _profileImage = File(pickedFile.path));
      }
    }
  }

  Future<void> _openMapPicker() async {
    final SelectedLocation? result =
    await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const LocationPickerScreen(),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _addressController.text = result.address;
    });


    try {
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ??
              'guest_user';

      await _supabaseService.saveAddress(
        userId: currentUserId,
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );

      debugPrint(
        'Address saved: ${result.address}',
      );

      debugPrint(
        'Latitude: ${result.latitude}',
      );

      debugPrint(
        'Longitude: ${result.longitude}',
      );
    } catch (e) {
      debugPrint(
        'Failed to save address to Supabase: $e',
      );
    }
  }

  Future<void> _selectAge() async {
    int tens = 1;
    int units = 8;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Select Age',
                textAlign: TextAlign.center,
              ),

              content: SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [

                    Expanded(
                      child:
                      ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        physics:
                        const FixedExtentScrollPhysics(),

                        onSelectedItemChanged:
                            (index) {
                          setDialogState(() {
                            tens = index + 1;
                          });
                        },

                        childDelegate:
                        ListWheelChildBuilderDelegate(
                          childCount: 9,
                          builder:
                              (context, index) {
                            return Center(
                              child: Text(
                                (index + 1).toString(),
                                style:
                                const TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    Expanded(
                      child:
                      ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        physics:
                        const FixedExtentScrollPhysics(),

                        onSelectedItemChanged:
                            (index) {
                          setDialogState(() {
                            units = index;
                          });
                        },

                        childDelegate:
                        ListWheelChildBuilderDelegate(
                          childCount: 10,
                          builder:
                              (context, index) {
                            return Center(
                              child: Text(
                                index.toString(),
                                style:
                                const TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final age =
                        (tens * 10) + units;


                    if (age < 18) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Age must be 18 or above.',
                          ),
                        ),
                      );
                      return;
                    }

                    _ageController.text =
                        age.toString();

                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Confirm',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitForm() {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a personal photo.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      ResumeData newData = ResumeData(
        id: widget.initialData?.id,
        profileImage: _profileImage!,
        certificateImage: _certificateImage,
        fullName: _nameController.text,
        age: _ageController.text,
        gender: _selectedGender!,
        email: _emailController.text,
        phone: '+60 ${_phoneController.text.trim()}',
        address: _addressController.text,
        summary: _summaryController.text,
        experience: _experienceController.text,
        education: _educationController.text,
      );

      Navigator.pop(context, newData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Create Resume' : 'Edit Resume'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(false),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 30, color: Colors.grey),
                        Text('Photo', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _selectAge,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '123456789',
                        prefixText: '+60 ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        final myPhoneRegex = RegExp(r'^[1-9]\d{7,9}$');
                        if (!myPhoneRegex.hasMatch(value.trim())) {
                          return 'Enter valid MY number (e.g. 123456789)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map),
                    tooltip: 'Pick address from Map',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Professional Summary', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Work Experience', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(labelText: 'Education', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.file_upload),
                label: Text(_certificateImage == null
                    ? 'Upload Relevant Certificate (PNG only)'
                    : 'Certificate Uploaded! Tap to replace'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: _certificateImage == null ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(widget.initialData == null ? 'Save Resume' : 'Update Resume', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// --- RESUME RESULT PAGE ---
class ResumeResultPage extends StatefulWidget {
  final ResumeData data;
  final Function(ResumeData)? onSave;

  const ResumeResultPage({
    super.key,
    required this.data,
    this.onSave,
  });

  @override
  State<ResumeResultPage> createState() => _ResumeResultPageState();
}

class _ResumeResultPageState extends State<ResumeResultPage> {
  late ResumeData _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Viewer'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ResumeData? editedData = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumeBuilderForm(initialData: _currentData),
            ),
          );
          if (editedData != null) {
            setState(() {
              _currentData = editedData;
            });
            if (widget.onSave != null) {
              widget.onSave!(editedData);
            }
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Resume'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: FileImage(_currentData.profileImage),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentData.fullName.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('${_currentData.gender}  •  ${_currentData.age} years old', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                          Text('${_currentData.email}  •  ${_currentData.phone}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 2),
                if (_currentData.address.isNotEmpty) ...[
                  const Text('ADDRESS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(_currentData.address, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                ],
                if (_currentData.summary.isNotEmpty) ...[
                  const Text('SUMMARY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(_currentData.summary, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                ],
                if (_currentData.experience.isNotEmpty) ...[
                  const Text('EXPERIENCE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(_currentData.experience, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                ],
                if (_currentData.education.isNotEmpty) ...[
                  const Text('EDUCATION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text(_currentData.education, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                ],
                if (_currentData.certificateImage != null) ...[
                  const Divider(height: 32, thickness: 2),
                  const Text('ATTACHED CERTIFICATE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 16),
                  Center(
                    child: Image.file(
                      _currentData.certificateImage!,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}