import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'theme/typography.dart';
import 'widgets/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final state = AppState();
  await state.load(); // restore theme / cart / orders / shift
  runApp(TinyPosApp(state: state));
}

class TinyPosApp extends StatelessWidget {
  final AppState? state;
  const TinyPosApp({super.key, this.state});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Tiny POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE9E0D2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC75B39)),
        textTheme: AppType.textTheme(),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const PhoneFrame(),
    );
    // Tests construct TinyPosApp() with no state -> use create() so they never
    // touch SharedPreferences. Runtime passes a pre-loaded state -> use .value.
    return state != null
        ? ChangeNotifierProvider<AppState>.value(value: state!, child: app)
        : ChangeNotifierProvider<AppState>(create: (_) => AppState(), child: app);
  }
}
