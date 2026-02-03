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
  final ImagePicker _picker = ImagePicker(); // Single instance

  void _validate() {
    setState(() {
      _isFormValid = _nameCtrl.text.isNotEmpty &&
          _emailCtrl.text.isNotEmpty &&
          _desigCtrl.text.isNotEmpty &&
          _passCtrl.text.length >= 6 &&
          _passCtrl.text == _confirmPassCtrl.text;
    });
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF007930)),
              title: const Text('নতুন ছবি তুলুন'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF007930)),
              title: const Text('গ্যালারি থেকে বেছে নিন'),
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
    print("Picking started from: $source"); // DEBUG PRINT
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        print("Image picked: ${pickedFile.path}"); // DEBUG PRINT
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _validate();
      } else {
        print("User cancelled picking"); // DEBUG PRINT
      }
    } catch (e) {
      print("CRITICAL ERROR: $e"); // DEBUG PRINT
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF007930);

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("রেজিস্ট্রেশন সফল হয়েছে!")));
            context.go('/login');
          }
          if (state is AuthError) {
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
                      const Text("রেজিস্ট্রেশন", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Noto Serif Bengali')),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50))),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      children: [
                        const Text("আপনার তথ্য প্রদান করুন", style: TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Noto Serif Bengali')),
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
                        _buildField("পাসওয়ার্ড", _passCtrl, isPass: true),
                        _buildField("পাসওয়ার্ড নিশ্চিত করুন", _confirmPassCtrl, isPass: true),

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

  Widget _buildField(String label, TextEditingController ctrl, {bool isPass = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF007930), fontWeight: FontWeight.bold, fontSize: 13)),
          TextField(
            controller: ctrl,
            obscureText: isPass,
            keyboardType: type,
            onChanged: (_) => _validate(),
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: "$label প্রদান করুন",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF007930), width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}