import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../features/auth/auth_gate.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import '../services/seed_service.dart';
import '../theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Future<void> _bootstrapFuture = _bootstrap();
  late final AuthService _authService = AuthService(FirebaseAuth.instance);

  Future<void> _bootstrap() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await SeedService(
        FirebaseFirestore.instance,
      ).seedIfNeeded();
    } catch (error, stackTrace) {
      debugPrint('Seed skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppShoppe',
      theme: buildAppTheme(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isWide = mediaQuery.size.width > 520;

        if (!isWide || child == null) {
          return child ?? const SizedBox.shrink();
        }

        return ColoredBox(
          color: const Color(0xFFE7E3DB),
          child: Center(
            child: Container(
              width: 440,
              margin: const EdgeInsets.symmetric(vertical: 18),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 36,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: const Size(440, 956),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootstrapScreen();
          }
          if (snapshot.hasError) {
            return _BootstrapError(error: snapshot.error.toString());
          }
          return AuthGate(authService: _authService);
        },
      ),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
