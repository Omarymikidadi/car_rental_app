import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _offerController = TextEditingController();
  final _urlController = TextEditingController();
  
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _useUrl = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _useUrl = false;
        _urlController.clear();
      });
    }
  }

  Future<void> _addBanner() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_useUrl && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tafadhali chagua picha au weka link")));
      return;
    }

    if (_useUrl && _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tafadhali weka link ya picha")));
      return;
    }

    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      String imageUrl = '';

      if (_useUrl) {
        imageUrl = _urlController.text.trim();
      } else if (_selectedImage != null) {
        // 1. Upload to Storage
        final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('banners').child(fileName);
        
        if (kIsWeb) {
          await storageRef.putData(await _selectedImage!.readAsBytes());
        } else {
          await storageRef.putFile(File(_selectedImage!.path));
        }
        
        imageUrl = await storageRef.getDownloadURL();
      }

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('banners').add({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'image': imageUrl,
        'offer': _offerController.text.trim(),
        'createdAt': Timestamp.now(),
      });
      
      _titleController.clear();
      _subtitleController.clear();
      _offerController.clear();
      _urlController.clear();
      setState(() {
        _selectedImage = null;
        _useUrl = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('Banner added successfully!', 'Poster imewekwa kikamilifu!')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBanner(String id, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('banners').doc(id).delete();
      
      // Only delete from storage if it was an uploaded file (path contains /banners/)
      if (imageUrl != null && imageUrl.contains('/banners/')) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Storage delete error: $e");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Manage Offers', 'Usimamizi wa Ofa'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('Add New Offer Poster', 'Ongeza Ofa Mpya'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          label: lang.translate('Upload Image', 'Pakia Picha'),
                          isSelected: !_useUrl,
                          onSelected: (val) => setState(() => _useUrl = false),
                          icon: Icons.image_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChoiceChip(
                          label: lang.translate('Paste URL', 'Weka Link'),
                          isSelected: _useUrl,
                          onSelected: (val) => setState(() => _useUrl = true),
                          icon: Icons.link_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (!_useUrl)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180, width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: _selectedImage != null 
                          ? ClipRRect(borderRadius: BorderRadius.circular(15), child: kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: const Color(0xFF1D275F).withOpacity(0.5)), const SizedBox(height: 10), Text(lang.translate('Choose Image File', 'Chagua Picha ya Poster'), style: TextStyle(color: Colors.grey[600], fontSize: 13))]),
                      ),
                    )
                  else
                    _buildTextField(_urlController, lang.translate('Image URL (https://...)', 'Link ya Picha'), Icons.link),

                  const SizedBox(height: 20),
                  _buildTextField(_titleController, lang.translate('Offer Title', 'Kichwa cha Ofa'), Icons.title),
                  const SizedBox(height: 15),
                  _buildTextField(_subtitleController, lang.translate('Subtitle/Description', 'Maelezo Mafupi'), Icons.notes),
                  const SizedBox(height: 15),
                  _buildTextField(_offerController, lang.translate('Offer Text (e.g. 20% OFF)', 'Maandishi ya Ofa'), Icons.local_offer_outlined),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addBanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D275F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(lang.translate('Save Poster', 'Hifadhi Poster'),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(lang.translate('Current Active Posters', 'Posters Zinazofanya Kazi'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('banners').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return Center(child: Text(lang.translate('No posters yet', 'Hakuna posters bado')));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String imageUrl = data['image'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl.startsWith('http') 
                              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                              : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                          ),
                        ),
                        title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(data['offer'] ?? '', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                          onPressed: () => _deleteBanner(doc.id, imageUrl),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required Function(bool) onSelected, required IconData icon}) {
    return ChoiceChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blueGrey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF1D275F),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2))),
      showCheckmark: false,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1D275F), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      validator: (v) => v!.isEmpty ? 'Lazima ujaze hapa' : null,
    );
  }
}
