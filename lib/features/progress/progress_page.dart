import 'package:flutter/material.dart';

import '../../widgets/page_layout.dart';
import '../../widgets/empty_state.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});
  @override
  Widget build(BuildContext context) => const PageLayout(
    title: 'Progres Hafalan',
    children: [
      EmptyState(
        icon: Icons.insights_rounded,
        title: 'Belum ada progres tersimpan',
        message: 'Pencatatan hafalan dan penyimpanan lokal belum diaktifkan. Progres akan muncul di sini setelah fitur tersebut tersedia.',
      ),
      Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Satu langkah setiap hari',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'Nantinya Anda dapat menandai ayat yang sudah dihafal dan melanjutkan sesi terakhir.',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
