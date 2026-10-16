// A single sheet showing what the app's ThemeData actually paints: the app bar, the bottom navigation,
// the card, the buttons, the inputs and the type scale, all drawn by the real theme rather than described
// in prose. This is the before/after surface for any change to lib/shared/styles/themes.dart.
import 'package:chat/shared/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

class DesignSystemSheet extends StatelessWidget {
  const DesignSystemSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.labelLarge),
              const SizedBox(height: 8),
              body,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Lynomia Chat')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          section(
            'TYPE SCALE',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display', style: text.displayLarge),
                Text('Title large', style: text.titleLarge),
                Text('Title medium', style: text.titleMedium),
                Text('Body large — the quick brown fox', style: text.bodyLarge),
                Text('Body medium — the quick brown fox', style: text.bodyMedium),
              ],
            ),
          ),
          section(
            'SURFACE',
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conversation', style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text('Last message preview sits here', style: text.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          section(
            'ACTIONS',
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Primary')),
                OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
                TextButton(onPressed: () {}, child: const Text('Tertiary')),
                const ElevatedButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
          ),
          section(
            'INPUT',
            const TextField(
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Type a message…',
              ),
            ),
          ),
          section(
            'ACCENTS',
            Row(
              children: [
                for (final c in <Color>[
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.error,
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ])
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('design system, light', (tester) async {
    await shoot(tester, name: 'design-system-light', theme: lightTheme, child: const DesignSystemSheet());
  });

  testWidgets('design system, dark', (tester) async {
    await shoot(tester, name: 'design-system-dark', theme: darkTheme, child: const DesignSystemSheet());
  });
}
