import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/common_widgets/modern_button.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blueAccent, Colors.indigo])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 80, color: Colors.white),
                const SizedBox(height: 40),
                TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username', filled: true)),
                const SizedBox(height: 16),
                TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', filled: true)),
                const SizedBox(height: 32),
                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthAuthenticated) {
                      context.go('/dashboard');
                    }
                  },
                  builder: (context, state) {
                    if (state is AuthLoading) return const CircularProgressIndicator();
                    return ModernButton(
                      text: 'Login',
                      onPressed: () {
                        print('Username: ${_usernameCtrl.text}');
                        print('Password: ${_passwordCtrl.text}');
                        context.read<AuthBloc>().add(LoginEvent(_usernameCtrl.text, _passwordCtrl.text));
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}