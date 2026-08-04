import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../services/profile_service.dart';

/// Grid of up to [ProfileService.maxPhotos] photos: tap an empty slot to
/// add one (gallery -> Storage -> `photoUrls` array), tap an existing photo
/// to set it as primary or delete it. Backed by a live stream so it reacts
/// to uploads from other devices/tabs too.
class ManagePhotosScreen extends StatefulWidget {
  final String uid;
  const ManagePhotosScreen({super.key, required this.uid});

  @override
  State<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  final _profileService = ProfileService();
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _addPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
      if (picked == null) return;
      setState(() => _uploading = true);
      await _profileService.uploadProfilePhoto(widget.uid, File(picked.path));
    } catch (e) {
      if (mounted) {
        final msg = e is StateError
            ? "अधिकतम ${ProfileService.maxPhotos} फ़ोटो जोड़ी जा सकती हैं / Maximum ${ProfileService.maxPhotos} photos allowed"
            : "फ़ोटो अपलोड नहीं हुई / Could not upload photo";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openActions(String url, bool isPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          if (!isPrimary)
            ListTile(
              leading: const Icon(Icons.star_outline, color: AppColors.gold),
              title: const Text("प्रोफ़ाइल फ़ोटो बनाएं / Set as profile photo"),
              onTap: () async {
                Navigator.pop(context);
                await _profileService.setPrimaryPhoto(widget.uid, url);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text("हटाएं / Delete", style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              await _profileService.deleteProfilePhoto(widget.uid, url);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text("फ़ोटो प्रबंधित करें / Manage Photos"),
        backgroundColor: AppColors.headerBg,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
        builder: (context, snapshot) {
          final urls = List<String>.from(snapshot.data?.data()?['photoUrls'] ?? const []);
          final canAddMore = urls.length < ProfileService.maxPhotos;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "${urls.length}/${ProfileService.maxPhotos} फ़ोटो · पहली फ़ोटो आपकी प्रोफ़ाइल फ़ोटो होगी\n${urls.length}/${ProfileService.maxPhotos} photos · the first one is your profile photo",
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
                    ),
                    itemCount: urls.length + (canAddMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == urls.length) {
                        return GestureDetector(
                          onTap: _uploading ? null : _addPhoto,
                          child: DottedAddTile(uploading: _uploading),
                        );
                      }
                      final url = urls[index];
                      final isPrimary = index == 0;
                      return GestureDetector(
                        onTap: () => _openActions(url, isPrimary),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(url, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AppColors.borderColor)),
                            ),
                            if (isPrimary)
                              Positioned(
                                top: 5, left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(100)),
                                  child: const Text("मुख्य", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DottedAddTile extends StatelessWidget {
  final bool uploading;
  const DottedAddTile({super.key, required this.uploading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.safLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.saffron, width: 1.4),
      ),
      child: Center(
        child: uploading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.saffron))
            : const Icon(Icons.add_a_photo_outlined, color: AppColors.saffron, size: 26),
      ),
    );
  }
}
