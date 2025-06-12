import 'package:flutter/material.dart';
import 'package:kitchen_assistant/screens/recipe_detail_screen.dart';
import 'package:kitchen_assistant/screens/login_screen.dart';
import 'package:kitchen_assistant/screens/signup_screen.dart';
import 'package:kitchen_assistant/screens/home_screen.dart';
import 'package:kitchen_assistant/screens/add_recipe_screen.dart';
import 'package:kitchen_assistant/screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:kitchen_assistant/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/recipeDetail': (context) => const RecipeDetailScreen(),
        '/addRecipe': (context) => const AddRecipeScreen(),
      },
    );
  }
}
