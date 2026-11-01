import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

Widget failure(BuildContext c, VoidCallback retry) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        c.t(
          'Data gagal dimuat. Periksa koneksi.',
          'Unable to load data. Check your connection.',
        ),
      ),
      FilledButton(onPressed: retry, child: Text(c.t('Coba lagi', 'Retry'))),
    ],
  ),
);
Future<void> perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'Perubahan gagal disimpan atau layanan tidak tersedia. Coba lagi.',
              'Unable to save changes or access the service. Try again.',
            ),
          ),
        ),
      );
    }
  }
}

Widget padded(List<Widget> children) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 850),
    child: ListView(padding: const EdgeInsets.all(20), children: children),
  ),
);
