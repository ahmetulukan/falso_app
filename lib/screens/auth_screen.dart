import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email ve şifre gereklidir.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Kullanıcı adı gereklidir.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
      } else {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: pass);
        // Save user profile to Firestore
        if (cred.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'email': email,
            'nickname': name,
            'createdAt': FieldValue.serverTimestamp(),
            'totalScore': 0,
            'streak': 0,
            'bestStreak': 0,
          });
          await cred.user!.updateDisplayName(name);
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Bu emaile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          msg = 'Yanlış şifre girdiniz.';
          break;
        case 'email-already-in-use':
          msg = 'Bu email zaten kayıtlı.';
          break;
        case 'weak-password':
          msg = 'Şifre çok zayıf, en az 6 karakter olmalı.';
          break;
        case 'invalid-email':
          msg = 'Geçersiz email adresi.';
          break;
        case 'invalid-credential':
          msg = 'Email veya şifre hatalı.';
          break;
        default:
          msg = 'Giriş hatası: ${e.message}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.sports_soccer, color: AppColors.primaryBlue, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text('FALSO', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6)),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? 'Hesabınıza giriş yapın' : 'Yeni hesap oluşturun',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Toggle tabs
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _tabBtn('Giriş Yap', _isLogin, () => setState(() => _isLogin = true))),
                                Expanded(child: _tabBtn('Kayıt Ol', !_isLogin, () => setState(() => _isLogin = false))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name field (only for register)
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameCtrl,
                              hint: 'Kullanıcı Adı',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Email
                          _buildTextField(
                            controller: _emailCtrl,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _buildTextField(
                            controller: _passCtrl,
                            hint: 'Şifre',
                            icon: Icons.lock_outline,
                            obscure: _obscurePass,
                            suffix: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Error
                          if (_error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.wrong.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.wrong, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error, style: const TextStyle(color: AppColors.wrong, fontSize: 12))),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Submit button
                          GestureDetector(
                            onTap: _isLoading ? null : _submit,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Skip button
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      child: Text(
                        'Giriş yapmadan devam et →',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
