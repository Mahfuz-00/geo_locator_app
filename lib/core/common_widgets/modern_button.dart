import 'package:flutter/material.dart';

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingText;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF00A441), Color(0xFF003E18)],
        ),
        borderRadius: BorderRadius.circular(38),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          // Keeps the shape consistent
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(38)),
        ),
        child: isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centering is key
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
            if (loadingText != null) ...[
              const SizedBox(width: 12),
              Text(
                loadingText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ), // Space between text and spinner
            ],
          ],
        )
            : Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}