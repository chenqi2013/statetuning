import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'home_controller.dart';
import 'home_page.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_translations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final appLocale = resolveAppLocale(deviceLocale);
  runApp(MyApp(locale: appLocale));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'app_title'.tr,
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: kAppSupportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
      home: const HomePage(),
    );
  }
}
