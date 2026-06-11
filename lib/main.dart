import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'state/session.dart';
import 'state/menu_controller.dart';
import 'state/bills_controller.dart';
import 'state/kds_controller.dart';
import 'state/tables_controller.dart';
import 'api/bill_repository.dart';
import 'api/kds_repository.dart';
import 'api/table_repository.dart';
import 'theme/typography.dart';
import 'widgets/phone_frame.dart';
import 'widgets/app_scaffold.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final app = AppState();
  await app.load(); // theme / cached UI prefs
  runApp(TinyPosApp(app: app));
}

class TinyPosApp extends StatelessWidget {
  final AppState? app;
  final SessionState? session; // injected (already signed-in) by widget tests
  final PosMenuController? menu; // injected (preloaded) by widget tests
  final BillRepository? billRepo; // injected (fake) by widget tests
  final BillsController? bills; // injected (preloaded) by widget tests
  final KdsController? kds; // injected (preloaded) by widget tests
  final TablesController? tables; // injected (preloaded) by widget tests
  const TinyPosApp({super.key, this.app, this.session, this.menu, this.billRepo, this.bills, this.kds, this.tables});

  @override
  Widget build(BuildContext context) {
    final material = MaterialApp(
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
      home: const RootGate(),
    );
    return MultiProvider(
      providers: [
        if (session != null)
          ChangeNotifierProvider<SessionState>.value(value: session!)
        else
          ChangeNotifierProvider<SessionState>(create: (_) => SessionState()..restore()),
        if (app != null)
          ChangeNotifierProvider<AppState>.value(value: app!)
        else
          ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        if (menu != null)
          ChangeNotifierProvider<PosMenuController>.value(value: menu!)
        else
          ChangeNotifierProvider<PosMenuController>(
            create: (ctx) => PosMenuController(ctx.read<SessionState>().api),
          ),
        if (billRepo != null)
          Provider<BillRepository>.value(value: billRepo!)
        else
          Provider<BillRepository>(create: (ctx) => BillRepository(ctx.read<SessionState>().api)),
        if (bills != null)
          ChangeNotifierProvider<BillsController>.value(value: bills!)
        else
          ChangeNotifierProvider<BillsController>(
            create: (ctx) => BillsController(ctx.read<BillRepository>()),
          ),
        if (kds != null)
          ChangeNotifierProvider<KdsController>.value(value: kds!)
        else
          ChangeNotifierProvider<KdsController>(
            create: (ctx) => KdsController(KdsRepository(ctx.read<SessionState>().api)),
          ),
        if (tables != null)
          ChangeNotifierProvider<TablesController>.value(value: tables!)
        else
          ChangeNotifierProvider<TablesController>(
            create: (ctx) => TablesController(TableRepository(ctx.read<SessionState>().api)),
          ),
      ],
      child: material,
    );
  }
}

/// Decides what to show based on the auth session: splash → login → app shell.
class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    switch (session.status) {
      case SessionStatus.loading:
        return const _Splash();
      case SessionStatus.signedOut:
        return const AppFrame(child: AuthLoginScreen());
      case SessionStatus.signedIn:
        // Map the authenticated staffRole onto the existing role-based shell.
        final app = context.read<AppState>();
        WidgetsBinding.instance.addPostFrameCallback((_) => app.applyAuthRole(session.user!.staffRole));
        return const PhoneFrame();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const AppFrame(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0, -1),
            end: Alignment(0.4, 1),
            colors: [Color(0xFF2A160C), Color(0xFF160B05)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('☕', style: TextStyle(fontSize: 52)),
              SizedBox(height: 18),
              SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFD98A4E))),
            ],
          ),
        ),
      ),
    );
  }
}
