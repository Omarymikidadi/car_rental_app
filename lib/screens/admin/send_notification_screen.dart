import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class SendNotificationScreen extends StatefulWidget {
  final String? targetDriverId;
  final String? targetDriverName;

  const SendNotificationScreen({super.key, this.targetDriverId, this.targetDriverName});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final notificationData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'Admin',
        'readBy': [], // For group messages
        'isRead': false, // For individual messages
        'target': widget.targetDriverId ?? 'all_drivers',
      };

      await FirebaseFirestore.instance.collection('notifications').add(notificationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('Message sent successfully!', 'Ujumbe umetumwa kikamilifu!')), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isGlobal = widget.targetDriverId == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(lang.translate('Send Message', 'Tuma Ujumbe'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D275F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFF3F6FF), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    Icon(isGlobal ? Icons.campaign_rounded : Icons.person_pin_rounded, color: const Color(0xFF1D275F)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.translate('Recipient:', 'Mpokeaji:'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            isGlobal 
                              ? lang.translate('All Drivers', 'Madereva Wote') 
                              : widget.targetDriverName ?? 'Driver',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D275F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: lang.translate('Subject / Title', 'Kichwa cha Habari'),
                  filled: true, fillColor: const Color(0xFFF8F9FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: lang.translate('Your Message', 'Ujumbe Wako'),
                  hintText: lang.translate('Type important information here...', 'Andika taarifa muhimu hapa...'),
                  filled: true, fillColor: const Color(0xFFF8F9FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D275F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(lang.translate('Send Now', 'Tuma Sasa'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
