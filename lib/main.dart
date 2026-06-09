import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'services/local_games_store.dart';
import 'providers/demo_store_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env file first — must happen before anything reads AppConstants
  await dotenv.load(fileName: 'assets/.env');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await Supabase.initialize(
    url:     AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Local store for unverified (free-play) games + the demo sandbox.
  await Hive.initFlutter();
  await LocalGamesStore.init();
  await DemoStore.init();

  runApp(
    const ProviderScope(
      child: CourtsideApp(),
    ),
  );
}