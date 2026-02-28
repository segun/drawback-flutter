import 'package:flutter/material.dart';

class DrawbackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DrawbackAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 245, 184, 202), // rose-200
      elevation: 0,
      foregroundColor: const Color(0xFF9F1239), // rose-800
      centerTitle: true,
      title: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFBE7EB)), // rose-300
          borderRadius: BorderRadius.circular(6),
        ),
        child: Image.asset(
          'assets/images/logo_main.jpg',
          height: 48,
          width: 144,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
