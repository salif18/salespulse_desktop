import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesStats {
  //obtenir depenses
   Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );


  getStatsGenerales(userId, selectedMonth,token)async{
    var uri = "$domaineName/stats/$userId?mois=$selectedMonth";
    return await dio.get(uri,
      options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  Future<Response> getVentesDuJour(String userId, String token) async {
  final uri = "$domaineName/stats/jour/$userId";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesHebdomadaires(String userId, String token) async {
  final uri = "$domaineName/stats/semaine/$userId";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesAnnee(String userId, String token) async {
  final uri = "$domaineName/stats/annee/$userId";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getClientRetard(String userId, String token) async {
  final uri = "$domaineName/stats/clients-en-retard/$userId";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}
}
