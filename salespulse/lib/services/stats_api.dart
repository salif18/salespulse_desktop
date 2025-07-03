import 'package:http/http.dart' as http;
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesStats {
  //obtenir depenses
  getStatsByCategories(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-categories/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }

  getStatsHebdo(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-hebdo/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }

  getStatsByMonth(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-month/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }
}
