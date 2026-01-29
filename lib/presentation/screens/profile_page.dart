import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AuthBloc>()..add(LoadProfile()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AuthProfileLoaded) {
              final profile = state.profile;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
                    const SizedBox(height: 24),
                    Text(profile['name'] ?? 'User', style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(profile['email'] ?? '', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutEvent());
                        context.go('/login'); // navigate to login screen
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            } else if (state is AuthError) {
              return Center(child: Text('Error: ${state.message}'));
            } else {
              return const Center(child: Text('No profile loaded'));
            }
          },
        ),
      ),
    );
  }
}
