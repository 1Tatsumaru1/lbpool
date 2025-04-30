import 'package:lbpool/widgets/responsive_scaffold.dart';
import 'package:lbpool/widgets/text_section.dart';
import 'package:flutter/material.dart';

class LegalView extends StatelessWidget {
  const LegalView({super.key});

  static const Map<String, List<Map<String, String>>> contentMap = {
    "license": [
      {
        "title": "MIT License",
        "content": "Copyright (c) 2025 Anthony Le Douguet"
      },
      {
        "title": "General",
        "content": "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:"
      },
      {
        "title": "Inclusion",
        "content": "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
      },
      {
        "title": "Disclaimer",
        "content": "THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentMap['license']!.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: TextSection(
                title: section['title']!,
                content: section['content']!,
              ),
            );
          }).toList(),
        ),
      ),
    );

    return ResponsiveScaffold(
      title: 'License',
      body: mainContent,
    );

    // return Scaffold(
    //   backgroundColor: Colors.white, // Couleur de fond
    //   drawer: CustomDrawer(context: context),
    //   appBar: AppBar(
    //     title: Text('License'),
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //     foregroundColor: Theme.of(context).colorScheme.onPrimary,
    //     scrolledUnderElevation: 0,
    //   ),
    //   body: 
    // );
  }
}