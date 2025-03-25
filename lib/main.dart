import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/geo_fence_provider.dart';
import 'providers/home_provider.dart';
import 'providers/local_data_provider.dart';
import 'providers/location_provider.dart';
import 'providers/location_tracking_provider.dart';
import 'providers/main_screen_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/summary_screen_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'config.env');
  initializeDependencies().then((_) => runApp(MyApp()));
}

Future<void> initializeDependencies() async {
  await Firebase.initializeApp();
  updateLocalTimeZone();
  FlutterError.onError = (errorDetails) =>
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> updateLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _storage = FirebaseFirestore.instance;
  final LocationTrackingProvider _locationTrackingProvider =
      LocationTrackingProvider();
  final SummaryProvider _summaryProvider = SummaryProvider();

  final GeoFenceProvider _geoFenceProvider = GeoFenceProvider();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );

    return MultiProvider(
      providers: [
        Provider<AnalyticsProvider>(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<LocalDataProvider>(
          create: (_) => LocalDataProvider(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),
        ChangeNotifierProvider<auth.AuthProvider>(
          create: (_) => auth.AuthProvider(_auth, _storage),
        ),
        ChangeNotifierProvider<LocationTrackingProvider>(
          create: (_) => LocationTrackingProvider(),
        ),
        ChangeNotifierProvider<GeoFenceProvider>(
          create: (_) => GeoFenceProvider(),
        ),
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
        ChangeNotifierProvider(
          create: (_) => SummaryScreenProvider(
            _locationTrackingProvider,
            _summaryProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MainScreenProvider(
            _locationTrackingProvider,
            _geoFenceProvider,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Example project',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        scrollBehavior:
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        home: const SplashScreen(),
      ),
    );
  }
}
