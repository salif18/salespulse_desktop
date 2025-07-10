import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';

class PaymentAbonnementScreen extends StatelessWidget {
  const PaymentAbonnementScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("Abonnement Pro",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titreSection("💼 Abonnement Pro - 3 mois"),
              const SizedBox(height: 8),
              Text(
                "Boostez votre activité avec les fonctionnalités Pro :",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _avantage("📊 Statistiques avancées"),
              _avantage("📦 Gestion de stock illimitée"),
              _avantage("🧾 Génération automatique de reçus PDF"),
              _avantage("👥 Utilisateurs multiples (Manager, Caissier...)"),
              _avantage("📁 Sauvegarde sécurisée en ligne"),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Durée : 3 mois",
                        style: GoogleFonts.poppins(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text("Prix : 9 900 FCFA",
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment ,color:Colors.white),
                  label: Text("Acheter maintenant",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold , color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _confirmerPaiement(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _titreSection(String titre) {
    return Text(
      titre,
      style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }

  Widget _avantage(String texte) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texte,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade800)),
          )
        ],
      ),
    );
  }

  void _confirmerPaiement(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmation",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text("Voulez-vous confirmer l’achat de l’abonnement Pro ?",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _acheterAbonnement(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Confirmer", style: GoogleFonts.poppins()),
          )
        ],
      ),
    );
  }

  void _acheterAbonnement(BuildContext context) async {
     final api = AbonnementApi();
    // 🔄 Simuler un appel API d’abonnement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Text(
          "Achat de l’abonnement en cours...",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // 🔁 Simulation
     // Récupère ton token depuis SharedPreferences ou Provider
 final token = Provider.of<AuthProvider>(context, listen: false).token;
 await api.acheterAbonnement(
    context: context,
    type: "essai", // ou "essai"
    token: token,
  );
 
    // ✅ Après paiement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "Abonnement Pro activé avec succès !",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );

    // ⤵️ Redirection ou mise à jour du statut abonnement...
  }
}
