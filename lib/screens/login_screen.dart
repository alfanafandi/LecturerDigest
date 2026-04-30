import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/screens/main_wrapper.dart';
import 'package:lecturer_digest/screens/register_screen.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:flutter/gestures.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _localError = null);
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _localError = "Email dan kata sandi wajib diisi.");
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.login(_emailController.text.trim(), _passwordController.text.trim());
    
    if (provider.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      }
    } else {
      if (mounted && provider.error != null) {
        setState(() => _localError = provider.error);
      }
    }
  }

  Future<void> _handleTesterLogin() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _emailController.text = 'tester@lecturedigest.app';
    _passwordController.text = 'password123';
    
    _setLoading(true);
    
    try {
      // 1. Try Login first
      await provider.login(_emailController.text, _passwordController.text);
      
      if (!provider.isAuthenticated) {
        // 2. If login fails, try Signup (maybe account doesn't exist yet)
        await provider.signup(_emailController.text, _passwordController.text);
        // 3. Try Login again after signup
        await provider.login(_emailController.text, _passwordController.text);
      }
      
      if (provider.isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainWrapper()),
          );
        }
      } else {
        throw Exception(provider.error ?? "Gagal masuk sebagai tester.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tester Login Error: ${e.toString()}\nPastikan 'Confirm Email' di Supabase sudah OFF."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    // This is just a local helper if needed, but AppProvider handles it usually.
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side: Branding & Illustration
        Expanded(
          flex: 12,
          child: Container(
            color: AppTheme.primary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BrandLogo(size: 160, hasShadow: true),
                        const SizedBox(height: 48),
                        Text(
                          'LectureDigest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Transformasi cara kamu belajar dengan kecerdasan AI.\nSemua materi kuliahmu dalam satu genggaman.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '© 2024 LectureDigest App • Akademik Cerdas',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Right Side: Login Form
        Expanded(
          flex: 10,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48.0),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.05),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: _buildLoginForm(isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          const SizedBox(height: 40),
          const Center(child: BrandLogo(size: 80, hasShadow: true)),
          const SizedBox(height: 32),
        ],
        
        Text(
          'Selamat Datang Kembali',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 28 : 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.onSurface,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Silakan masuk untuk melanjutkan aktivitas belajarmu.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 48),
        
        _buildLabel('Alamat Email'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          hint: 'contoh@mahasiswa.ac.id',
          icon: Icons.email_outlined,
        ),
        
        const SizedBox(height: 24),
        
        _buildLabel('Kata Sandi'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hint: 'Masukkan kata sandi',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        
        if (_localError != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _localError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Lupa Kata Sandi?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Login Button
        Consumer<AppProvider>(
          builder: (context, provider, child) {
            return SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: provider.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('atau', style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5), fontSize: 12)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        
        const SizedBox(height: 32),
        
        OutlinedButton(
          onPressed: _handleTesterLogin,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_outlined, size: 20),
              SizedBox(width: 12),
              Text('Mode Demo (Tester Login)', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: 'Belum punya akun? ',
                style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Daftar Disini',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
