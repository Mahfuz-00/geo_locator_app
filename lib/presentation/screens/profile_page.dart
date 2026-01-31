import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/map_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00A441);
    const darkGreen = Color(0xFF003E18);
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: context.read<AuthBloc>()..add(LoadProfile()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Stack(
              children: [
                // 1. Top Background Gradient - Adaptive Height
                Container(
                  height: size.height * 0.35, // 35% of screen height
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF007930), Color(0xFF00FF65)],
                    ),
                  ),
                ),

                // 2. Map Image Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.35,
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/background-image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 3. Custom AppBar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balancing back button
                      ],
                    ),
                  ),
                ),

                // 4. Main Scrollable Content
                Column(
                  children: [
                    SizedBox(height: size.height * 0.15), // Offset for content start
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          ),
                        ),
                        child: _buildProfileContent(context, state, primaryGreen, darkGreen, size),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthState state, Color primaryGreen, Color darkGreen, Size size) {
    if (state is AuthLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A441)));
    } else if (state is AuthProfileLoaded) {
      final profile = state.profile;

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 3),
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.person, size: 60, color: Color(0xFF00A441)),
                  ),
                  const SizedBox(height: 16),

                  // Name - Fixed to Black
                  Text(
                    profile['name'] ?? 'User Name',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Explicitly Black
                    ),
                  ),

                  // Email - Fixed to Grey
                  Text(
                    profile['email'] ?? 'email@example.com',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  // Profile List Items
                  _buildProfileItem(Icons.badge_outlined, "Member Status", profile['status']?.toUpperCase() ?? "Active", primaryGreen),
                  _buildProfileItem(Icons.email_outlined, "Email Address", profile['email'] ?? 'N/A', primaryGreen),
                  _buildProfileItem(Icons.phone_iphone_rounded, "Phone Number", profile['phone'] ?? 'N/A', primaryGreen),
                  _buildProfileItem(Icons.history_toggle_off_rounded, "Account Created", "Jan 29, 2026", primaryGreen),

                  // Adaptive spacer before logout
                  SizedBox(height: size.height * 0.05),

                  // Logout Button
                  GestureDetector(
                    onTap: () {
                      FlutterBackgroundService().invoke("stopService");
                      context.read<MapBloc>().add(StopAutoSendLocation());
                      context.read<AuthBloc>().add(LogoutEvent());
                      context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryGreen, darkGreen]),
                        borderRadius: BorderRadius.circular(38),
                      ),
                      child: const Center(
                        child: Text(
                          "LOGOUT",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return const Center(
      child: Text(
        "Error loading profile",
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF00A441), width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title - Clear Grey
                Text(
                  title,
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
                // Value - Clear Black
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black, // Explicitly Black
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}