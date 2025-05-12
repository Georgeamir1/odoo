import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/login/login_ui.dart';
import 'package:pretty_bloc_observer/pretty_bloc_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization.dart';
import 'locale_cubit.dart';

void main() {
  Bloc.observer = PrettyBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => LocaleCubit(),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Flutter Demo',
              locale: locale,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: [
                const Locale('en', ''),
                const Locale('ar', ''),
              ],
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: LoginPage(
                title: 'Beta',
              ),
              builder: (context, child) {
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerHover: (_) {}, // Ignore hover events
                  onPointerDown: (_) {}, // Ignore down events
                  onPointerUp: (_) {}, // Ignore up events
                  child: child!,
                );
              },
            );
          },
        ));
  }
}
