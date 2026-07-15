import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import 'my_bookings_screen.dart';
import 'auth_screen.dart';
import 'add_car_screen.dart';
import 'cars_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context, UserProvider userProvider, LanguageProvider lang) async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Text(lang.translate('Change Profile Photo', 'Badili Picha ya Wasifu'), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.photo_library, color: Colors.blueAccent)),
                title: Text(lang.translate('Gallery', 'Kutoka Kwenye Galari')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    if (kIsWeb) {
                      final bytes = await image.readAsBytes();
                      _uploadImageWeb(context, userProvider, bytes, image.name);
                    } else {
                      _uploadImage(context, userProvider, File(image.path));
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.camera_alt, color: Colors.green)),
                title: Text(lang.translate('Camera', 'Piga Picha Sasa')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (image != null) {
                    if (kIsWeb) {
                      final bytes = await image.readAsBytes();
                      _uploadImageWeb(context, userProvider, bytes, image.name);
                    } else {
                      _uploadImage(context, userProvider, File(image.path));
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage(BuildContext context, UserProvider userProvider, File file) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    try {
      await userProvider.uploadProfileImage(file);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _uploadImageWeb(BuildContext context, UserProvider userProvider, dynamic bytes, String fileName) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    try {
      await userProvider.uploadProfileImageWeb(bytes, fileName);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showEditDialog(BuildContext context, String title, String currentValue, Function(String) onSave, LanguageProvider lang, {bool isPassword = false}) {
    final controller = TextEditingController(text: isPassword ? '' : currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: lang.translate('Enter new value', 'Weka taarifa mpya'),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          ElevatedButton(
            onPressed: () async {
              try {
                await onSave(controller.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('Success!', 'Imefanikiwa!'))));
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(lang.translate('Save', 'Hifadhi'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, 
            backgroundColor: const Color(0xFF001F54),
            leading: Navigator.canPop(context) 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF001F54), Color(0xFF003399)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickImage(context, userProvider, lang),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: userProvider.imagePath != null && userProvider.imagePath!.isNotEmpty
                                    ? NetworkImage(userProvider.imagePath!)
                                    : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png') as ImageProvider,
                              ),
                            ),
                            Positioned(
                              bottom: 0, 
                              right: 0, 
                              child: Container(
                                padding: const EdgeInsets.all(6), 
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent, 
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ), 
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(userProvider.name, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(userProvider.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),

                  if (userProvider.role == 'driver') ...[
                    _buildSectionHeader(context, lang.translate('Vehicle Information', 'Taarifa za Gari')),
                    _buildProfileCard(context, [
                      _buildProfileItem(
                        context, 
                        Icons.directions_car_outlined, 
                        lang.translate('Assigned Vehicle', 'Gari Ulilopangiwa'), 
                        userProvider.assignedCar.isNotEmpty ? userProvider.assignedCar : lang.translate('No car assigned', 'Bado hujapangiwa gari'),
                        onTap: null
                      ),
                    ]),
                  ],

                  _buildSectionHeader(context, lang.translate('Account Information', 'Taarifa za Akaunti')),
                  _buildProfileCard(context, [
                    _buildProfileItem(
                      context, 
                      Icons.person_outline, 
                      lang.translate('Full Name', 'Jina Kamili'), 
                      userProvider.name,
                      onTap: () => _showEditDialog(context, lang.translate('Edit Name', 'Badili Jina'), userProvider.name, userProvider.updateName, lang)
                    ),
                    _buildProfileItem(
                      context, 
                      Icons.mail_outline, 
                      lang.translate('Email', 'Barua Pepe'), 
                      userProvider.email,
                      onTap: () => _showEditDialog(context, lang.translate('Edit Email', 'Badili Barua Pepe'), userProvider.email, userProvider.updateEmail, lang)
                    ),
                    _buildProfileItem(
                      context, 
                      Icons.phone_outlined, 
                      lang.translate('Phone Number', 'Namba ya Simu'), 
                      userProvider.phone,
                      onTap: () => _showEditDialog(context, lang.translate('Edit Phone', 'Badili Namba'), userProvider.phone, userProvider.updatePhone, lang)
                    ),
                  ]),

                  _buildSectionHeader(context, lang.translate('Security', 'Usalama')),
                  _buildProfileCard(context, [
                    _buildProfileItem(
                      context, 
                      Icons.lock_outline, 
                      lang.translate('Change Password', 'Badili Nenosiri'), 
                      lang.translate('Keep your account secure', 'Linda akaunti yako'),
                      onTap: () => _showEditDialog(context, lang.translate('New Password', 'Nenosiri Jipya'), '', userProvider.updatePassword, lang, isPassword: true)
                    ),
                  ]),

                  const SizedBox(height: 30),
                  
                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context, lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.redAccent.withOpacity(0.2) : const Color(0xFFFFEBEE), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded),
                          const SizedBox(width: 10),
                          Text(lang.translate('Logout', 'Toka kwenye Akaunti'), 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 15, left: 5),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1D275F))),
    );
  }

  Widget _buildProfileCard(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: theme.brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1D275F), size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey) : null),
    );
  }

  void _showLogoutDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(lang.translate('Logout', 'Toka kwenye Akaunti'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(lang.translate('Are you sure you want to logout?', 'Je, una uhakika unataka kutoka kwenye akaunti hii?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (ctx) => const AuthScreen()), (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: Text(lang.translate('Logout', 'Toka'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
