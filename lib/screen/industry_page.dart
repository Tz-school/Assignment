import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_drawer.dart';
import '../model/resume_model.dart';
import 'package:flutter/services.dart';

class IndustryPage extends StatelessWidget {
  final String userRole;
  final String username;

  const IndustryPage({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Industry'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Resume Builder'),
              Tab(text: 'Job Seeker'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ResumeHomeTab(),
            Center(child: Text('Job Seeker Content')),
          ],
        ),
        drawer: AppDrawer(userRole: userRole, username: username),
      ),
    );
  }
}

// --- RESUME HOME TAB ---
class ResumeHomeTab extends StatefulWidget {
  const ResumeHomeTab({super.key});

  @override
  State<ResumeHomeTab> createState() => _ResumeHomeTabState();
}

class _ResumeHomeTabState extends State<ResumeHomeTab> {
  final List<ResumeData> _resumeList = [];

  void _createNewResume() async {
    final ResumeData? newData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResumeBuilderForm(),
      ),
    );

    if (newData != null) {
      setState(() {
        _resumeList.add(newData);
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumeResultPage(
            data: newData,
            onSave: (updatedData) {
              setState(() {
                _resumeList[_resumeList.length - 1] = updatedData;
              });
            },
          ),
        ),
      );
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
          onUpdateList: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

// --- RESUME HISTORY PAGE ---
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
  Future<void> _showDeleteDialog(BuildContext context, int index) async {
    final String resumeName = widget.resumeList[index].fullName;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Resume'),
          content: Text(
            'Are you sure you want to delete the resume for "$resumeName"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  widget.resumeList.removeAt(index);
                });
                widget.onUpdateList();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Resume for $resumeName deleted.')),
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
              subtitle: Text('${resume.email} • Age ${resume.age}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, index),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResumeResultPage(
                      data: resume,
                      onSave: (updatedData) {
                        setState(() {
                          widget.resumeList[index] = updatedData;
                        });
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

// --- RESUME BUILDER FORM ---
class ResumeBuilderForm extends StatefulWidget {
  final ResumeData? initialData;

  const ResumeBuilderForm({super.key, this.initialData});

  @override
  State<ResumeBuilderForm> createState() => _ResumeBuilderFormState();
}

class _ResumeBuilderFormState extends State<ResumeBuilderForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _summaryController;
  late TextEditingController _experienceController;
  late TextEditingController _educationController;

  File? _profileImage;
  File? _certificateImage;

  @override
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.fullName ?? '');
    _ageController = TextEditingController(text: widget.initialData?.age ?? '');
    _emailController = TextEditingController(text: widget.initialData?.email ?? '');

    // Clean initial phone string for editing
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

  Future<void> _selectAge() async {
    int tens = 0;
    int units = 0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Age', textAlign: TextAlign.center),
          content: SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) => tens = index,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 10,
                      builder: (context, index) => Center(
                        child: Text(index.toString(), style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ),
                const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) => units = index,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 10,
                      builder: (context, index) => Center(
                        child: Text(index.toString(), style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _ageController.text = '$tens$units';
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
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
      // Combine prefix with input digits
      final String fullPhone = '+60 ${_phoneController.text.trim()}';

      ResumeData newData = ResumeData(
        profileImage: _profileImage!,
        certificateImage: _certificateImage,
        fullName: _nameController.text,
        age: _ageController.text,
        email: _emailController.text,
        phone: fullPhone, // Saves as "+60 123456789"
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
                        prefixText: '+60 ', // Displays fixed +60 prefix in UI
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Restricts keyboard input to numbers only
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        // Validates Malaysian phone numbers (8 to 10 digits following +60)
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
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                maxLines: 2,
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
                          Text('${_currentData.age} years old', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                          Text('${_currentData.email}  •  ${_currentData.phone}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 2),
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