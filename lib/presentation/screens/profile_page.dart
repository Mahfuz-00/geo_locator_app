import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/map_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Branding Colors
    const primaryGreen = Color(0xFF007930);
    const lightGreen = Color(0xFF00A441);
    const darkGreen = Color(0xFF003E18);

    return BlocProvider.value(
      value: context.read<AuthBloc>()..add(LoadProfile()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Stack(
              children: [
                // 1. Top Background Gradient
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryGreen, lightGreen],
                    ),
                  ),
                ),

                // 2. Background Image Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Opacity(
                    opacity: 0.2,
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
                          "প্রোফাইল",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Noto Serif Bengali',
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                // 4. Main White Container
                Column(
                  children: [
                    const SizedBox(height: kToolbarHeight*1.5),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            )
                          ],
                        ),
                        child: _buildBody(context, state, primaryGreen, darkGreen),
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

  // Helper to switch between Loading, Success, and Error
  Widget _buildBody(BuildContext context, AuthState state, Color primaryGreen, Color darkGreen) {
    if (state is AuthLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryGreen,
          strokeWidth: 3,
        ),
      );
    }

    if (state is AuthProfileLoaded) {
      return _buildProfileContent(context, state, primaryGreen, darkGreen);
    }

    // Improved Error State with Reload Button
    return _buildErrorState(context, primaryGreen, darkGreen);
  }

  Widget _buildProfileContent(BuildContext context, AuthProfileLoaded state, Color primaryGreen, Color darkGreen) {
    final profile = state.profile;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Avatar
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryGreen, width: 4),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.person, size: 70, color: Color(0xFF00A441)),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Noto Serif Bengali',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF00A441).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.status.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF00A441), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 35),

                _buildProfileItem(Icons.email_outlined, "ইমেইল অ্যাড্রেস", profile.email, primaryGreen),
                _buildProfileItem(Icons.phone_iphone_rounded, "ফোন নম্বর", profile.phone, primaryGreen),
                _buildProfileItem(Icons.history_toggle_off_rounded, "অ্যাকাউন্ট তৈরি", profile.createdAt.split('T')[0], primaryGreen),

                const SizedBox(height: 60),

                // Logout Button
                _buildActionButton(
                  context: context,
                  label: "লগ আউট",
                  gradient: [primaryGreen, darkGreen],
                  onTap: () {
                    FlutterBackgroundService().invoke("stopService");
                    context.read<MapBloc>().add(StopAutoSendLocation());
                    context.read<AuthBloc>().add(LogoutEvent());
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Color primaryGreen, Color darkGreen) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            "তথ্য লোড করতে সমস্যা হয়েছে",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Serif Bengali',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "অনুগ্রহ করে আপনার ইন্টারনেট কানেকশন চেক করুন এবং পুনরায় চেষ্টা করুন।",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 30),
          // Reload Button
          _buildActionButton(
            context: context,
            label: "আবার চেষ্টা করুন",
            gradient: [primaryGreen, darkGreen],
            onTap: () => context.read<AuthBloc>().add(LoadProfile()),
          ),
        ],
      ),
    );
  }

  // Reusable Action Button Component
  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Noto Serif Bengali',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontFamily: 'Noto Serif Bengali')),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
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