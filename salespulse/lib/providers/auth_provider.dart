import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  late String _token;
  late String _userId;
  late String _userName;
  late String _societeName;
  late String _societeNumber;
  late String _adminId;
  late String _role;

  String get token => _token;
  String get userId => _userId;
  String get adminId => _adminId;
  String get userName => _userName;
  String get societeName => _societeName;
  String get societeNumber => _societeNumber;
  String get role => _role;
 

  AuthProvider() {
    _token = "";
    _userId = "";
    _userName = "";
    _societeName = "";
    _societeNumber = "";
    _loadUserData();
  }

  // Charger les données depuis SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token") ?? "";
    _userId = prefs.getString("userId") ?? "";
    _userName = prefs.getString("userName") ?? "";
    _societeName = prefs.getString("societeName") ?? "";
    _societeNumber = prefs.getString("societeNumber") ?? "";
    _role = prefs.getString("role") ?? "";
    _adminId = prefs.getString("adminId") ?? "";


    // final userJson = prefs.getString("userData");
    // if (userJson != null) {
    //   _user = UserModel.fromJon(jsonDecode(userJson));
    // }

    notifyListeners();
  }

  // Sauvegarde rapide
  Future<void> saveToLocalStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Sauvegarder les données complètes de l’utilisateur
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // _user = UserModel.fromJon(userData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData)); // 👈 convertit en JSON
    notifyListeners();
  }

  // Fonction de connexion
  void loginButton(
    String userToken, 
    String userUserId,
    String adminId, 
    String role,
    String userName,  
    String number,   
    String entreprise,
  ) { 
    _token = userToken;
    _userId = userUserId;
    _adminId = adminId;
    _role = role;
    _userName = userName;   
    _societeNumber = number;
    _societeName = entreprise;
    

    saveToLocalStorage("token", _token);
    saveToLocalStorage("userId", _userId);
    saveToLocalStorage("userName", _userName);
    saveToLocalStorage("societeName", _societeName);
    saveToLocalStorage("societeNumber", _societeNumber);
    saveToLocalStorage("adminId", _adminId);
    saveToLocalStorage("role", _role);
    notifyListeners();
  }

  // Déconnexion
  Future<void> logoutButton() async {
    _token = "";
    _userId = ""; 
    _adminId ="";
    _role = "";
    _userName = "";    
    _societeNumber = "";
    _societeName = "";
    
    // _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Efface toutes les données stockées localement

    notifyListeners();
  }
}
