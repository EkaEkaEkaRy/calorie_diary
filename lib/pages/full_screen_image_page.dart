import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class FullscreenImageScreen extends StatelessWidget {
  final String imagePath;

  const FullscreenImageScreen({super.key, required this.imagePath});

  Future<void> _saveImage(BuildContext context) async {
    try {
      // Запрос разрешений (Android)
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Разрешение на доступ к хранилищу отклонено')),
        );
        return;
      }

      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      final result = await ImageGallerySaverPlus.saveImage(bytes,
          quality: 100, name: 'image_${DateTime.now().millisecondsSinceEpoch}');
      if (result['isSuccess'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Изображение сохранено в галерею')),
        );
      } else {
        throw Exception('Ошибка сохранения');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _saveImage(context),
            tooltip: 'Скачать',
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag:
              imagePath, // Можно использовать event['id'], но здесь imagePath тоже уникален
          child: InteractiveViewer(
            maxScale: 5.0,
            minScale: 1.0,
            child: Image.file(File(imagePath)),
          ),
        ),
      ),
    );
  }
}
