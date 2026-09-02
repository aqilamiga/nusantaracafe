  import 'package:flutter/material.dart';
  
  Widget inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5E8B7E),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget customTextField(String hint, {bool isPassword = false}) {
    return Container(
      key: ValueKey(hint),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          suffixIcon: isPassword
              ? const Icon(Icons.visibility_off_outlined, color: Colors.black38)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget mainButton(String text, Color bg, Color textCol, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 2,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textCol,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }