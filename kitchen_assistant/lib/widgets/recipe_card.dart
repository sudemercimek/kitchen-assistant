import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class RecipeCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onDetail;
  final VoidCallback? onDelete;
  final bool showDeleteIcon;

  const RecipeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isFavorite,
    this.onFavorite,
    this.onDetail,
    this.onDelete,
    this.showDeleteIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: GestureDetector(
          onTap: onDetail,
          child: Container(
            width: kIsWeb
                ? 420
                : MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E7E1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

          child: imageUrl.isNotEmpty
              ? Image.network(
            imageUrl,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print(" Image failed to load: $error");
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.red),
                ),
              );
            },
          )
              : const SizedBox(
            height: 200,
            child: Center(
              child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            ),
          )
                ) ,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF725C3F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (onFavorite != null)
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.pinkAccent,
                              ),
                              onPressed: onFavorite,
                            ),
                          const Spacer(),
                          if (showDeleteIcon && onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: onDelete,
                            ),
                          if (onDetail != null)
                            TextButton.icon(
                              onPressed: onDetail,
                              icon: const Icon(Icons.arrow_forward_ios, size: 14),
                              label: const Text("Details"),
                              style: TextButton.styleFrom(foregroundColor: Colors.teal),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
