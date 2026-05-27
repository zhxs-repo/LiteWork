import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillImageEmbedBuilder extends EmbedBuilder {
  const QuillImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data;
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          final progress = total != null
              ? loadingProgress.cumulativeBytesLoaded / total
              : null;
          return Center(
            child: CircularProgressIndicator(value: progress),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, size: 48));
        },
      );
    } else {
      imageWidget = Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image, size: 48));
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
            maxHeight: 400,
          ),
          child: GestureDetector(
            onTap: () => _showImagePreview(context, imageUrl),
            child: imageWidget,
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: imageUrl.startsWith('http://') ||
                      imageUrl.startsWith('https://')
                  ? Image.network(imageUrl, fit: BoxFit.contain)
                  : Image.file(File(imageUrl), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
