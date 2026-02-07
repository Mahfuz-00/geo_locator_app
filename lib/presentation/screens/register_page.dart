import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/register_request_entity.dart';
import '../bloc/auth_bloc.dart';
import '../../core/common_widgets/modern_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  File? _selectedImage;
  bool _isFormValid = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  final ImagePicker _picker = ImagePicker();

  void _validate() {
    setState(() {
      _isFormValid = _nameCtrl.text.isNotEmpty &&
          _emailCtrl.text.isNotEmpty &&
          _desigCtrl.text.isNotEmpty &&
          _passCtrl.text.length >= 7 &&
          _passCtrl.text == _confirmPassCtrl.text;
    });
  }

  Map<String, dynamic> _getPasswordStrength() {
    String p = _passCtrl.text;
    if (p.isEmpty) return {"text": "", "color": Colors.transparent, "percent": 0.0};
    if (p.length < 7) return {"text": "খুবই দুর্বল", "color": Colors.red, "percent": 0.2};
    if (p.length < 9) return {"text": "দুর্বল", "color": Colors.orange, "percent": 0.4};

    bool hasLetters = p.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumbers = p.contains(RegExp(r'[0-9]'));
    bool hasSpecial = p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasLetters && hasNumbers) {
      if (hasSpecial) return {"text": "অত্যন্ত শক্তিশালী", "color": const Color(0xFF004D1F), "percent": 1.0};
      return {"text": "শক্তিশালী", "color": Colors.green, "percent": 0.8};
    }
    return {"text": "মাঝারি (অক্ষর ও সংখ্যা উভয়ই ব্যবহার করুন)", "color": Colors.blue, "percent": 0.6};
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF007930)),
              title: const Text('নতুন ছবি তুলুন', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF007930)),
              title: const Text('গ্যালারি থেকে বেছে নিন', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
        _validate();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Helper to show success dialog on the login screen context
  void _showSuccessDialog(BuildContext loginContext) {
    const primaryGreen = Color(0xFF007930);
    showDialog(
      context: loginContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: primaryGreen, size: 60),
            SizedBox(height: 10),
            Text("রেজিস্ট্রেশন সফল!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "আপনার তথ্য সফলভাবে জমা দেওয়া হয়েছে। সংশ্লিষ্ট কর্তৃপক্ষ আপনার অ্যাকাউন্টটি অনুমোদিত করলে আপনি লগ-ইন করতে পারবেন।",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ঠিক আছে", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF007930);
    final strength = _getPasswordStrength();

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          // Unfocus immediately
          if (state is RegisterSuccess || state is AuthError) {
            FocusScope.of(context).unfocus();
          }

          if (state is RegisterSuccess) {
            // 1. Navigate to Login first
            context.go('/login');

            // 2. Show dialog on the next frame so it appears over the Login screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Note: Using the current context might fail if the widget is disposed,
              // but go_router's 'go' usually keeps the overlay stack accessible
              // or you can use a global navigator key.
              _showSuccessDialog(context);
            });
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryGreen, Color(0xFF00A441)],
                  ),
                ),
              ),
              Positioned(
                top: 0, left: 0, right: 0, height: 250,
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset('assets/images/background-image.png', fit: BoxFit.cover),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => context.pop()),
                      const Spacer(),
                      const Text("রেজিস্ট্রেশন", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight * 1.5),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50))),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      children: [
                        const Text("আপনার তথ্য প্রদান করুন", style: TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 25),
                        GestureDetector(
                          onTap: _showPickerOptions,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                                child: _selectedImage == null ? const Icon(Icons.camera_alt, size: 40, color: primaryGreen) : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildField("নাম", _nameCtrl),
                        _buildField("ইমেইল", _emailCtrl, type: TextInputType.emailAddress),
                        _buildField("ফোন নম্বর", _phoneCtrl, type: TextInputType.phone),
                        _buildField("পদবী", _desigCtrl),
                        _buildField("পাসওয়ার্ড", _passCtrl, isPass: true, obscure: _obscurePass, onToggle: () => setState(() => _obscurePass = !_obscurePass)),

                        if (_passCtrl.text.isNotEmpty)
                          Column(
                            children: [
                              LinearProgressIndicator(value: strength['percent'], backgroundColor: Colors.grey.shade200, color: strength['color'], minHeight: 4),
                              const SizedBox(height: 4),
                              Align(alignment: Alignment.centerRight, child: Text(strength['text'], style: TextStyle(color: strength['color'], fontSize: 11, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 10),
                            ],
                          ),

                        _buildField("পাসওয়ার্ড নিশ্চিত করুন", _confirmPassCtrl, isPass: true, obscure: _obscureConfirmPass, onToggle: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass)),

                        if (_confirmPassCtrl.text.isNotEmpty && _passCtrl.text != _confirmPassCtrl.text)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                SizedBox(width: 5),
                                Text("পাসওয়ার্ড দুটি মিলিনি", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),
                        ModernButton(
                          text: "সাবমিট করুন",
                          isLoading: state is AuthLoading,
                          onPressed: _isFormValid ? () {
                            final request = RegisterRequestEntity(
                              name: _nameCtrl.text,
                              email: _emailCtrl.text,
                              phone: _phoneCtrl.text,
                              designation: _desigCtrl.text,
                              password: _passCtrl.text,
                              confirmPassword: _confirmPassCtrl.text,
                              status: 'active',
                              imagePath: _selectedImage?.path,
                            );
                            context.read<AuthBloc>().add(RegisterUser(request));
                          } : null,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isPass = false, bool obscure = false, VoidCallback? onToggle, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF007930), fontWeight: FontWeight.bold, fontSize: 13)),
          TextField(
            controller: ctrl,
            obscureText: isPass ? obscure : false,
            keyboardType: type,
            onChanged: (_) => _validate(),
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: "$label প্রদান করুন",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF007930), width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: isPass ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onToggle) : null,
            ),
          ),
        ],
      ),
    );
  }
}