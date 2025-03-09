import 'dart:io';
import 'package:flutter/material.dart';

class DiaryFormPage extends StatefulWidget {
  const DiaryFormPage({super.key});

  @override
  State<DiaryFormPage> createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  File? image;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
