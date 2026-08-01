import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/scallop_header.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text("RishtaBook", style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'serif')),
          const SizedBox(height: 6),
          const Text("संस्करण / Version 2.0.0", style: TextStyle(color: AppColors.muted)),
          const OrnateDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: const Text(
              "RishtaBook भारत का एक विश्वसनीय विवाह मंच है। हमारा उद्देश्य है दो परिवारों को सुरक्षित और आधुनिक तरीके से जोड़ना — अब सीधे मिलान और चैट के साथ।",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.6, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 40),
          const Text("❤️ भारत में बनाया गया / Made with love in India",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
