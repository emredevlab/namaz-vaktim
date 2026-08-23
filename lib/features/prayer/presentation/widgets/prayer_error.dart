import 'package:flutter/material.dart';

class PrayerError extends StatelessWidget {
  const PrayerError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(message),
          trailing:
              TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ),
      );
}
