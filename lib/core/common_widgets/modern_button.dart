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
    // Determine if the button is effectively disabled
    final bool isBtnDisabled = onPressed == null || isLoading;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        // Switch between Gradient and Grey based on state
        gradient: isBtnDisabled
            ? null
            : const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF00A441), Color(0xFF003E18)],
        ),
        color: isBtnDisabled ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(38),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(38)),
          // Ensure disabled style doesn't override our container color
          disabledBackgroundColor: Colors.transparent,
        ),
        child: isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              ),
            ],
          ],
        )
            : Text(
          text,
          style: TextStyle(
            // Slightly dimmer white text when disabled if preferred
            color: isBtnDisabled ? Colors.white70 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}