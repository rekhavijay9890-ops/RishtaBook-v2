import 'package:flutter/material.dart';

const Color kBrandColor = Color(0xFF0F766E);

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: kBrandColor, size: 60),
            const SizedBox(height: 16),
            const Text("RishtaBook", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Version 2.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text(
              "RishtaBook is India's most trusted premium matchmaking platform. Humara maksad hai do dilon ko ek surakshit aur modern tarike se milana - ab real matching aur direct chat ke saath.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 30),
            const Text("Made with ❤️ in India", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
