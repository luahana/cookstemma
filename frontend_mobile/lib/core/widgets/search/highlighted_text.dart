import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// A widget that displays text with highlighted portions matching the query.
/// Uses RichText with TextSpan to highlight matched text.
class HighlightedText extends StatelessWidget {
  final String text;
  final String? query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    this.query,
    this.style,
    this.highlightStyle,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? const TextStyle(color: AppColors.textPrimary);

    // If no query or empty query, just return plain text
    if (query == null || query!.trim().isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final effectiveHighlightStyle = highlightStyle ??
        defaultStyle.copyWith(
          backgroundColor: AppColors.highlightBackground,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        );

    final lowerText = text.toLowerCase();
    final lowerQuery = query!.toLowerCase().trim();
    final spans = <TextSpan>[];

    int start = 0;
    int index;

    // Find all occurrences and create spans
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      // Text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: defaultStyle,
        ));
      }

      // Matched text (preserve original case)
      spans.add(TextSpan(
        text: text.substring(index, index + query!.length),
        style: effectiveHighlightStyle,
      ));

      start = index + query!.length;
    }

    // Remaining text after last match
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }

    // If no matches found, return plain text
    if (spans.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
