import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/domain/entities/hashtag/hashtag.dart';

class HashtagChips extends StatelessWidget {
  final List<Hashtag> hashtags;

  const HashtagChips({super.key, required this.hashtags});

  @override
  Widget build(BuildContext context) {
    if (hashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hashtags.map((hashtag) => _buildChip(hashtag)).toList(),
    );
  }

  Widget _buildChip(Hashtag hashtag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[100]!),
      ),
      child: Text(
        '#${hashtag.name}',
        style: TextStyle(
          fontSize: 13,
          color: Colors.indigo[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
