import 'package:flutter/material.dart';

import '../../changelog.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yangilanishlar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appChangelog.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final e = appChangelog[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('v${e.version}', style: Theme.of(context).textTheme.titleMedium)),
                      Text(e.date, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...e.items.map(
                    (x) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(x)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

