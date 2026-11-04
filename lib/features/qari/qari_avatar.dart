import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class QariAvatar extends StatelessWidget {
  const QariAvatar({super.key, required this.name, this.size = 52});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : '${parts.first[0]}${parts.length > 1 ? parts.last[0] : ''}'
              .toUpperCase();
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(
        initials,
        style: TextStyle(fontSize: size * .26, fontWeight: FontWeight.w700),
      ),
    );
    if (name == 'Yasser Al-Dosari') {
      return Semantics(
        label: context.t(
          'Foto Yasser Al-Dosari',
          'Portrait of Yasser Al-Dosari',
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/qari/yasser-al-dosari.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -.25),
            cacheWidth: (size * 3).round(),
            frameBuilder: (_, child, frame, synchronouslyLoaded) =>
                frame == null ? fallback : child,
            errorBuilder: (_, error, stack) => fallback,
          ),
        ),
      );
    }
    return Semantics(
      label: context.t(
        'Avatar inisial, bukan foto qari',
        'Initials avatar, not a reciter photograph',
      ),
      child: fallback,
    );
  }
}
