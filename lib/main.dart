import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/operator_service.dart';
import 'theme/app_theme.dart';
import 'screens/get_started_screen.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OperatorService()),
      ],
      child: const UrjaaApp(),
    ),
  );
}

/// Main URJAA EV Application
class UrjaaApp extends StatelessWidget {
  const UrjaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URJAA - Unified EV Infrastructure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const AppShell() : const GetStartedScreen();
        },
      ),
    );
  }
}
