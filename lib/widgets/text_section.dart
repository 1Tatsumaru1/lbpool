import 'package:flutter/material.dart';

class TextSection extends StatelessWidget {
  const TextSection({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Titre en gras
        Text(
          title,
          softWrap: true,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Ligne séparatrice
        Divider(
          color: Theme.of(context).colorScheme.inversePrimary,
          thickness: 2,
        ),

        // Contenu texte
        Text(
          content,
          softWrap: true,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}