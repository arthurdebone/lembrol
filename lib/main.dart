import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: LembrolApp(),
    ),
  );
}

class LembrolApp extends ConsumerStatefulWidget {
  const LembrolApp({super.key});

  @override
  ConsumerState<LembrolApp> createState() => _LembrolAppState();
}

class _LembrolAppState extends ConsumerState<LembrolApp> {
  @override
  void initState() {
    super.initState();
    // Inicialização do orquestrador de agendamentos e notificações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schedulerServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Lembrol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
