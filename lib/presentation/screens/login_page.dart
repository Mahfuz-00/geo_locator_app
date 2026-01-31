import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/common_widgets/modern_button.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter your credentials'),
          backgroundColor: Color(0xFF00A441)));
      return;
    }
    context.read<AuthBloc>().add(LoginEvent(identifier, password));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF007930),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF007930), Color(0xFF00FF65)],
                  stops: [0.16, 0.55],
                ),
              ),
            ),
          ),

          // 2. Map Image Overlay
          Positioned(
            top: -size.height * 0.05,
            left: -size.width * 0.3,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/background-image.png',
                width: size.width * 1.8,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 3. Content Layer
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Top Header Section - Protected by a nested SafeArea
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.08),
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Government_Seal_of_Bangladesh.svg/1200px-Government_Seal_of_Bangladesh.svg.png',
                        height: size.height * 0.12,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "মাদারীপুর জেলা",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Noto Serif Bengali',
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 7)],
                        ),
                      ),
                      SizedBox(height: size.height * 0.05),
                    ],
                  ),
                ),
              ),

              // White Card Section - Extends to the absolute bottom
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.08),
                            _buildInputField("Email/Username", "Your Email or Username Here", _identifierCtrl),
                            const SizedBox(height: 25),
                            _buildInputField("Password", "Your Password Here", _passwordCtrl, isPassword: true),
                            const SizedBox(height: 40),

                            BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthAuthenticated) context.go('/dashboard');
                                if (state is AuthError) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
                                }
                              },
                              builder: (context, state) {
                                return ModernButton(
                                  text: "LOG IN",
                                  isLoading: state is AuthLoading,
                                  loadingText: "LOGGING IN",
                                  onPressed: _handleLogin,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Footer Image + Bottom Fill
                      Container(
                        color: Colors.white, // Ensures the background is white behind the image
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/footer-image.jpg',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),
                            // This fills the safe area (home bar area) with white instead of green
                            SizedBox(height: bottomPadding),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style: const TextStyle(color: Color(0xFF00A441), fontSize: 18, fontWeight: FontWeight.w600)
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00A441), width: 1)
            ),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00A441), width: 2)
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}