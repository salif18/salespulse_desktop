import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  // Déclaration des variables
  late String _token;
  late String _userId;
  late String _userName;
  late String _societeName;
  late String _societeNumber;

  // Accesseurs pour récupérer les valeurs
  String get token => _token;
  String get userId => _userId;
  String get userName => _userName;
  String get societeName => _societeName;
  String get societeNumber => _societeNumber;

  // Initialisation des variables
  AuthProvider() {
    _token = "";
    _userId = "";
    _userName = "";
    _societeName = "";
    _societeNumber ="";

    // Chargement des données au démarrage
    _loadUserData();
  }

  // Charger les données depuis le stockage local
  Future<void> _loadUserData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    _token = localStorage.getString("token") ?? "";
    _userId = localStorage.getString("userId") ?? "";
    _userName = localStorage.getString("userName") ?? "";
    _societeName = localStorage.getString("societeName") ?? "";
    _societeNumber = localStorage.getString("societeNumber") ?? "";
    // Notifier les listeners après avoir chargé les données
    notifyListeners();
  }

  // Sauvegarder les données dans le stockage local
  Future<void> saveToLocalStorage(String key, String value) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    await localStorage.setString(key, value);
  }

  // Supprimer les données du stockage local
  Future<void> removeFromLocalStorage(String key) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    await localStorage.remove(key);
  }

  // Fonction de login : sauvegarde les données utilisateur
  void loginButton(String userToken, String userUserId, String userName , String entreprise, String number) {
    _token = userToken;
    _userId = userUserId;
    _userName =userName;
    _societeName = entreprise;
    _societeNumber = number;
    saveToLocalStorage("token", _token);
    saveToLocalStorage("userId", _userId);
    saveToLocalStorage("userName", _userName);
    saveToLocalStorage("societeName", _societeName);
    saveToLocalStorage("societeNumber", _societeNumber);
    notifyListeners();
  }
  // Fonction de déconnexion : efface les données utilisateur
  void logoutButton() {
    _token = "";
    _userId = "";
    _userName = "";
    _societeName = "";
    _societeNumber = "";
    removeFromLocalStorage("token");
    removeFromLocalStorage("userId");
    removeFromLocalStorage("userName");
    removeFromLocalStorage("societeName");
    removeFromLocalStorage("societeNumber");
    notifyListeners();
  }
}
