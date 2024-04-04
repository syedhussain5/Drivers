import 'package:drivers/screens/car_info_screen.dart';
import 'package:drivers/screens/main_screen.dart';
import 'package:drivers/splashScreen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:users/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart ' as http;

import 'ThemeProvider/theme_provider.dart';
import 'infoHandler/app_info.dart';

Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAjSztWKm3wSzOyV5Y6zowUFNEaP1HNyj8',
      appId: '1:1058377040322:web:f8e4749abfac689991165b',
      messagingSenderId: '1058377040322',
      projectId: 'wedrive008',
      authDomain: 'wedrive008.firebaseapp.com',
      databaseURL: 'https://wedrive008-default-rtdb.firebaseio.com',
      storageBucket: 'wedrive008.appspot.com',
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'We Drive',
        themeMode: ThemeMode.system,
        theme: MyTheme.lightTheme,
        darkTheme: MyTheme.darktheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
