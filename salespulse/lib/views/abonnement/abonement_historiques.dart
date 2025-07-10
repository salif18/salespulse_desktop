// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/abonnement_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
import 'package:salespulse/views/abonnement/historique_paiement_abonnement.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AbonnementHistoriquePage extends StatefulWidget {
  const AbonnementHistoriquePage({super.key});

  @override
  State<AbonnementHistoriquePage> createState() => _AbonnementHistoriquePageState();
}

class _AbonnementHistoriquePageState extends State<AbonnementHistoriquePage> {
  List<HistoriqueAbonnement> historiques = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final api = AbonnementApi();
      final res = await api.getHistoriqueAbonnement(token);
      setState(() {
        historiques = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
  }

  String formatDate(DateTime date) {
    return DateFormat.yMMMMd('fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
     final token = Provider.of<AuthProvider>(context, listen: false).token;
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique des abonnements",style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),),
        backgroundColor: Colors.blueGrey,
        actions: [
          ElevatedButton.icon(
            onPressed:()=> Navigator.push(context, MaterialPageRoute(builder: (context)=> HistoriquePaiementPage(token: token))), 
            icon:const Icon(Icons.list),
            label: Text('Mes paiement', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),),
            )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : historiques.isEmpty
              ? const Center(child: Text("Aucun abonnement trouvé."))
              : ListView.builder(
                  itemCount: historiques.length,
                  itemBuilder: (context, index) {
                    final item = historiques[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          item.type == "premium" ? Icons.star : Icons.lock_clock,
                          color: item.type == "premium" ? Colors.amber : Colors.grey,
                        ),
                        title: Text("Abonnement ${item.type.toUpperCase()}"),
                        subtitle: Text(
                          "Du ${formatDate(item.debut)} au ${formatDate(item.fin)}\nStatut : ${item.statut}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
                 floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: () =>
           Navigator.push(context, MaterialPageRoute(builder: (context)=> const AbonnementScreen())),
        tooltip: "Réabonner",
        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
        label: Text("Réabonnement",style: GoogleFonts.roboto(fontSize: 12, color: Colors.white,fontWeight: FontWeight.bold),),
      ),
    );
  
  }
}
