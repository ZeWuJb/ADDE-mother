import 'package:flutter/material.dart';

class InputFiled extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscure;
  final bool email;
  const InputFiled({
    super.key,
    required this.controller,
    required this.hintText,
    this.email = false,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: TextField(
          obscureText: obscure,
          cursorColor: Theme.of(context).colorScheme.onSecondary,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none, // Remove the default border
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
            ), // Inside padding
            hintStyle: TextStyle(color: Colors.grey), // Hint text color
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.onSurface, // Transparent when not focused
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.onPrimary, // White border when focused
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ), // Text color
        ),
      ),
    );
  }
}
