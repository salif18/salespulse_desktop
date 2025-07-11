// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class PaymentAbonnementScreen extends StatelessWidget {
  const PaymentAbonnementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Abonnement Professionnel",
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 3),)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec badge Pro
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("PRO",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Text("3 mois",
                      style: GoogleFonts.poppins(
                          color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 15),
              
              // Titre principal
              Text("Optimisez votre business",
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 5),
              Text("Accédez à toutes les fonctionnalités avancées",
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600])),
              
              const SizedBox(height: 25),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 25),
              
              // Liste des avantages
              _avantagePro("📈 Analytics complets", "Suivez toutes vos performances commerciales"),
              _avantagePro("🛒 Stock illimité", "Gérez un nombre illimité de produits"),
              _avantagePro("📁 Backup cloud", "Sauvegarde automatique et sécurisée"),
              _avantagePro("👥 Équipe complète", "Jusqu'à 5 utilisateurs simultanés"),
              _avantagePro("🔐 Sécurité renforcée", "Protection des données premium"),
              
              const SizedBox(height: 30),
              
              // Carte de prix
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[800]!,
                      Colors.blue[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text("INVESTISSEMENT",
                        style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12)),
                    const SizedBox(height: 5),
                    Text("25 000 FCFA",
                        style: GoogleFonts.poppins(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("soit seulement 10 000 FCFA/mois",
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text("PASSER EN VERSION PRO",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white)),
                    ],
                  ),
                  onPressed: () => _confirmerPaiement(context),
                ),
              ),
              
              const SizedBox(height: 15),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> const AbonnementScreen()));
                  },
                  child: Text("Essai gratuit de 7 jours",
                      style: GoogleFonts.poppins(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avantagePro(String emojiTitre, String sousTitre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emojiTitre,
              style: GoogleFonts.poppins(fontSize: 18)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emojiTitre.substring(3),
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(sousTitre,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerPaiement(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_outlined,
                  color: Colors.blue, size: 50),
              const SizedBox(height: 15),
              Text("Confirmer l'abonnement",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              Text(
                  "Vous êtes sur le point de souscrire à l'abonnement Pro pour 25 000 FCFA.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.grey[600])),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("Annuler",
                          style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: ()  {
                        Navigator.pop(context);
                         _acheterAbonnement(context);
                      },
                      child: Text("Confirmer",
                          style: GoogleFonts.poppins(
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 void _acheterAbonnement(BuildContext context) async {
  final api = AbonnementApi();
  final token = Provider.of<AuthProvider>(context, listen: false).token;

  // Afficher l'indicateur de chargement
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.blue[800],
      content: Row(
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(width: 15),
          Text("Traitement de votre abonnement...",
              style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
    ),
  );

  try {
    final response = await api.acheterAbonnement(
      context: context,
      type: "premium",
      montant: 10000,
      mode: "",
      token: token,
    );

    // Cacher le SnackBar de chargement
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.statusCode == 201) {
      // Afficher confirmation succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${response.data['message']}"),
          backgroundColor: Colors.green,
        ),
      );

      // Afficher la boîte de dialogue de succès
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.green, size: 40),
                ),
                const SizedBox(height: 20),
                Text("Abonnement activé!",
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                    "Votre compte est maintenant passé en version Pro. Profitez de toutes les fonctionnalités!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600])),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Explorer les fonctionnalités",
                        style: GoogleFonts.poppins(
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  } on DioException catch (e) {
    // Cacher le SnackBar de chargement en cas d'erreur
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final msg = e.response?.data['error'] ?? "Erreur lors de l'abonnement";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}