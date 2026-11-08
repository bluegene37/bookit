// Gene - Nov, 03, 2026: Implemented BookIt entrypoint with Riverpod, NeumorphicTheme (Light/Dark), GoRouter, and Supabase initialization
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Gene - Nov, 08, 2026: Added flutter_web_plugins url_strategy import for clean path-based URLs on Vercel Web deployments
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/neumorphic_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'services/supabase_service.dart';

/*
// Gene - Nov, 03, 2026: Original main() without path URL strategy
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: BookItApp()));
}
*/

// Gene - Nov, 08, 2026: Enabled usePathUrlStrategy() so Vercel SPA rewrites serve clean paths (/admin, /my-bookings) without /#/ hash fragments
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: BookItApp()));
}

class BookItApp extends ConsumerWidget {
  const BookItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'BookIt - Universal Booking Platform',
      debugShowCheckedModeBanner: false,
      theme: NeumorphicTheme.lightTheme,
      darkTheme: NeumorphicTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

/*
// Gene - Nov, 03, 2026: Preserved initial counter boilerplate for documentation and history
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/

