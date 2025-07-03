import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesCredits {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );

  //ajouter de categorie pour formulaire
  postCredits(data, token) async {
    var uri = "$domaineName/credits";
    return await dio.post(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //obtenir categorie pour formulaire
  getCredits(userId, token) async {
    var uri = "$domaineName/credits/$userId";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //supprimer categorie
  deleteFournisseurs(id, token) async {
    var uri = "$domaineName/credits/single/$id";
    return await dio.delete(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }
}