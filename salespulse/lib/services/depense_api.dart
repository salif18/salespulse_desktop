
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:salespulse/https/domaine.dart';

   const String domaineName = Domaine.domaineURI;

class ServicesDepense{

   Dio dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(milliseconds: 15000),  // 15 secondes
    receiveTimeout: const Duration(milliseconds: 15000),  // 15 secondes
  ),
);

  //ajouter depense
  postNewDepenses(data, token) async {
    var uri = "$domaineName/depenses";
    return await dio.post(
      uri,
      data: data,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },)
    );
  }

  //obtenir depenses
  getAllDepenses(token,userId) async {
    var uri = "$domaineName/depenses/$userId";
    return await http.get(
      Uri.parse(uri),
     headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).timeout(const Duration(seconds: 15));
  }

  //messade d'affichage de reponse de la requette recus
  void showSnackBarSuccessPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: 16,fontWeight: FontWeight.w400)),
      backgroundColor:const Color.fromARGB(255, 34, 27, 51),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
          label: "",
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }),
    ));
  }

//messade d'affichage des reponse de la requette en cas dechec
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: 16,fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 255, 35, 19),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: "",
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }
}
