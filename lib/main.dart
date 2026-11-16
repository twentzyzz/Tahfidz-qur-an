import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'id.tahfidz.tahfidz_quran.murottal',
    androidNotificationChannelName: 'Pemutar Murottal',
    androidNotificationIcon: 'drawable/notification_icon',
    androidNotificationOngoing: true,
  );
  runApp(const TahfidzApp());
}
