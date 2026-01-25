import 'package:flutter/material.dart';
import '../../services/impression_service.dart';
import '../screens/impressions_screen.dart';

/// Impression Icon Widget - Shows impression notifications with unread count badge
class ImpressionIcon extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;

  const ImpressionIcon({
    super.key,
    this.iconColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ImpressionsScreen(),
              ),
            );
          },
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  iconColor ?? const Color(0xFF136DEC),
                  (iconColor ?? const Color(0xFF136DEC)).withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (iconColor ?? const Color(0xFF136DEC)).withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.sentiment_satisfied_alt,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
        // Unread impression badge
        StreamBuilder<int>(
          stream: ImpressionService.getUnreadImpressionsCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            if (count > 0) {
              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}