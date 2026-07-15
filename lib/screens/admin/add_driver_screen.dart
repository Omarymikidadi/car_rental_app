import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AddDriverScreen extends StatefulWidget {
  final String initialRole;
  const AddDriverScreen({super.key, this.initialRole = 'driver'});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _ageController = TextEditingController();
  
  late String _selectedRole;
  XFile? _pickedFile;
  bool _isLoading = false;
  String _loadingText = "Inasajili...";

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image != null) setState(() => _pickedFile = image);
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _loadingText = "Inatayarisha mfumo...";
    });
    
    FirebaseApp? secondaryApp;

    try {
      try {
        secondaryApp = Firebase.app('UserCreator');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'UserCreator', 
          options: Firebase.app().options
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

      setState(() => _loadingText = "Inatengeneza akaunti...");
      UserCredential userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      String? imageUrl;
      if (_pickedFile != null) {
        setState(() => _loadingText = "Inajaribu kupakia picha...");
        try {
          final secondaryStorage = FirebaseStorage.instanceFor(app: secondaryApp);
          final storageRef = secondaryStorage.ref().child('profile_images').child('$uid.jpg');
          if (kIsWeb) {
            await storageRef.putData(await _pickedFile!.readAsBytes());
          } else {
            await storageRef.putFile(File(_pickedFile!.path));
          }
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint("Storage error: $e");
        }
      }

      setState(() => _loadingText = "Inahifadhi taarifa...");
      Map<String, dynamic> userData = {
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'profileImage': imageUrl ?? '',
        'role': _selectedRole,
        'status': 'active',
        'createdAt': Timestamp.now(), 
      };

      if (_selectedRole == 'driver') {
        userData['licenseNumber'] = _licenseController.text.trim().toUpperCase();
        userData['age'] = int.tryParse(_ageController.text.trim()) ?? 0;
      }

      await secondaryFirestore.collection('users').doc(uid).set(userData);
      await secondaryAuth.signOut();

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${_selectedRole == 'driver' ? 'Dereva' : 'Mmiliki'} amesajiliwa!"), 
          backgroundColor: Colors.green
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog("Kosa: $e");
    }
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kosa"), content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Sawa"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_selectedRole == 'driver' ? lang.translate('Register Driver', 'Sajili Dereva') : lang.translate('Register Owner', 'Sajili Mmiliki'), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Color(0xFF1D275F)), const SizedBox(height: 20), Text(_loadingText)]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50, backgroundColor: const Color(0xFFF5F6F9),
                      backgroundImage: _pickedFile != null ? (kIsWeb ? NetworkImage(_pickedFile!.path) : FileImage(File(_pickedFile!.path)) as ImageProvider) : null,
                      child: _pickedFile == null ? const Icon(Icons.camera_alt, color: Color(0xFF1D275F)) : null,
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  _buildDropdownRole(lang),
                  const SizedBox(height: 15),
                  
                  _buildTextField(_nameController, lang.translate('Full Name', 'Jina Kamili'), Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_emailController, lang.translate('Email', 'Email'), Icons.email),
                  const SizedBox(height: 15),
                  _buildTextField(_phoneController, lang.translate('Phone', 'Simu'), Icons.phone, isNum: true),
                  
                  if (_selectedRole == 'driver') ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_licenseController, lang.translate('License', 'Leseni'), Icons.badge)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField(_ageController, lang.translate('Age', 'Umri'), Icons.cake, isNum: true)),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, lang.translate('Password', 'Nenosiri'), Icons.lock, isPass: true),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D275F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(lang.translate('Register Now', 'Sajili Sasa'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDropdownRole(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFFF5F6F9), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole, isExpanded: true,
          items: [
            DropdownMenuItem(value: 'driver', child: Text(lang.translate('Driver', 'Dereva'))),
            DropdownMenuItem(value: 'owner', child: Text(lang.translate('Car Owner', 'Mmiliki wa Gari'))),
          ],
          onChanged: (val) { if (val != null) setState(() => _selectedRole = val); },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false, bool isNum = false}) {
    return TextFormField(
      controller: ctrl, obscureText: isPass, keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF1D275F)),
        filled: true, fillColor: const Color(0xFFF5F6F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Lazima' : null,
    );
  }
}
