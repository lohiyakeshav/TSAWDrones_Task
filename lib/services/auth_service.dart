import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsawdrones_task/HomePage.dart';
import 'package:tsawdrones_task/UserValidation.dart';
import '../Provider/UserData.dart';
import '../models/user.dart';
import '../util/constant.dart';
import '../util/utils.dart';

class AuthService {
  Future<void> signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final navigator = Navigator.of(context);
      User user = User(
        id: '',
        name: name,
        password: password,
        email: email,
        token: '',
      );


      final response = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      navigator.push(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );


      if (response.statusCode == 200) {
        print('Signup successful');
      } else {
        throw 'Failed to sign up: ${response.body}';
      }
    } catch (e) {
      print("catch of signup");
      print("$e");

      showSnackBar(context, e.toString());
    }
  }

  Future<void> getUserData(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token') ?? '';

      final tokenRes = await http.post(
        Uri.parse('${Constants.uri}/tokenIsValid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (tokenRes.statusCode == 200) {
        final response = jsonDecode(tokenRes.body);
        if (response == true) {
          final userRes = await http.get(
            Uri.parse('${Constants.uri}/'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'x-auth-token': token,
            },
          );

          if (userRes.statusCode == 200) {
            userProvider.setUser(userRes.body);
            final navigator = Navigator.of(context);

            navigator.push(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );

          } else {
            throw 'Failed to get user data: ${userRes.body}';
          }
        } else {
          throw 'Token is not valid';
        }
      } else {
        throw 'Failed to validate token: ${tokenRes.body}';
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final navigator = Navigator.of(context);
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('x-auth-token');

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const UserValidation(),
        ),
            (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
