import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; 
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        UserCredential userCredential;
        try {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
          
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'active';
            if (status == 'inactive' || status == 'suspended') {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                _showErrorDialog(lang.translate(
                  'Your account has been suspended. Please contact admin.', 
                  'Akaunti yako imesimamishwa. Tafadhali wasiliana na utawala.'
                ));
              }
              return;
            }
          }

          if (email == 'admin@carrental.com') {
            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
              'name': 'System Admin',
              'email': email,
              'phone': '0000000000',
              'role': 'admin',
              'updatedAt': Timestamp.now(),
            }, SetOptions(merge: true));
          }
        } on FirebaseAuthException catch (e) {
          if ((e.code == 'user-not-found' || e.code == 'invalid-credential') && 
              email == 'admin@carrental.com' && password == 'admin123456') {
            
            UserCredential res = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
            await FirebaseFirestore.instance.collection('users').doc(res.user!.uid).set({
              'name': 'System Admin',
              'email': email,
              'phone': '0000000000',
              'role': 'admin',
              'status': 'active',
              'createdAt': Timestamp.now(),
            });
          } else {
            rethrow;
          }
        }
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'role': 'customer',
          'status': 'active',
          'createdAt': Timestamp.now(),
        });
      }
      
      await userProvider.fetchFromFirestore();

    } on FirebaseAuthException catch (e) {
      String message = lang.translate('Auth Error: ', 'Tatizo: ') + e.code;
      
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = lang.translate('Invalid email or password.', 'Barua pepe au nenosiri si sahihi.');
      } else if (e.code == 'network-request-failed') {
        message = lang.translate('No internet connection.', 'Hakuna intaneti.');
      } else if (e.code == 'email-already-in-use') {
        message = lang.translate('This email is already registered.', 'Barua pepe hii tayari imeshasajiliwa.');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final emailResetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          lang.translate('Reset Password', 'Badili Nenosiri'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D275F)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate(
                'Enter your email to receive a reset link.', 
                'Weka barua pepe ili kutumiwa link ya kubadili nenosiri.'
              ), 
              style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400)
            ),
            const SizedBox(height: 25),
            _buildTextField(
              controller: emailResetController,
              label: lang.translate('Email Address', 'Barua Pepe'),
              icon: Icons.alternate_email_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.translate('Cancel', 'Ghairi'), style: TextStyle(color: Colors.blueGrey.shade600)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                final email = emailResetController.text.trim();
                if (email.isEmpty) return;
                
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.translate(
                          'Reset link sent! Check your email.', 
                          'Link imetumwa! Angalia barua pepe yako.'
                        )),
                        backgroundColor: Colors.green,
                      )
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003399),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(lang.translate('Send', 'Tuma'), style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF003399).withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 40, letterSpacing: -1.5),
                              children: [
                                TextSpan(
                                  text: 'Carrental',
                                  style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF1D275F)),
                                ),
                                TextSpan(
                                  text: ' Pro',
                                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF003399)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 3,
                            width: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003399),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isLogin ? lang.translate('Welcome Back', 'Karibu Tena') : lang.translate('Get Started', 'Anza Sasa'),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isLogin 
                              ? lang.translate('Sign in to continue to your account', 'Ingia ili kuendelea na akaunti yako') 
                              : lang.translate('Create an account to start your journey', 'Tengeneza akaunti ili kuanza safari yako'),
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      if (!_isLogin) ...[
                        _buildTextField(
                          controller: _nameController, 
                          label: lang.translate('Full Name', 'Jina Kamili'), 
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _phoneController, 
                          label: lang.translate('Phone Number', 'Namba ya Simu'), 
                          icon: Icons.phone_android_outlined, 
                          isPhone: true,
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildTextField(
                        controller: _emailController, 
                        label: lang.translate('Email Address', 'Barua Pepe'), 
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController, 
                        label: lang.translate('Password', 'Nenosiri'), 
                        icon: Icons.lock_open_rounded, 
                        isPassword: true,
                      ),
                      
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              lang.translate('Forgot Password?', 'Umesahau Nenosiri?'),
                              style: const TextStyle(color: Color(0xFF003399), fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D275F),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF1D275F).withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLogin ? lang.translate('LOGIN', 'INGIA') : lang.translate('REGISTER', 'JISAJILI'), 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                              ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? lang.translate("Don't have an account?", "Huna akaunti?") : lang.translate("Already have an account?", "Tayari una akaunti?"),
                            style: TextStyle(color: Colors.blueGrey.shade600),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? lang.translate('Register', 'Jisajili') : lang.translate('Login', 'Ingia'),
                              style: const TextStyle(color: Color(0xFF003399), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    bool isPhone = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6F0), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1D1E)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFF1D275F), size: 22),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.blueGrey.shade300,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: (v) => v!.isEmpty ? 'Field is required' : null,
      ),
    );
  }
}
