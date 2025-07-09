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


  getStatsGenerales(selectedMonth,token)async{
    var uri = "$domaineName/stats?mois=$selectedMonth";
    return await dio.get(uri,
      options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  Future<Response> getVentesDuJour(String token) async {
  final uri = "$domaineName/stats/jour";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesHebdomadaires(String token) async {
  final uri = "$domaineName/stats/semaine";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesAnnee(String token) async {
  final uri = "$domaineName/stats/annee";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getClientRetard(String token) async {
  final uri = "$domaineName/stats/clients-en-retard";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}
}
