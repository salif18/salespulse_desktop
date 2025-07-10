// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/paiement_abonement.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  bool loading = false;
  final api = AbonnementApi();

  Future<void> souscrire(String type) async {
    setState(() => loading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      await api.acheterAbonnement(
        context: context,
        type: type,
        montant: type == "essai" ? 0 : 10000,
        mode: "",
        token: token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green,
          content: Text(
            "Abonnement ${type == "essai" ? "d'essai" : "Pro"} activé avec succès !",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            "Erreur : ${e.response?.data['error'] ?? 'Échec de la souscription'}",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Nos Offres d'Abonnement",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête
            Text(
              "Choisissez la formule qui correspond à vos besoins",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Carte Essai Gratuit
            _buildPlanCard(
              title: "Essai Gratuit",
              price: "0 FCFA",
              duration: "7 jours",
              color: const Color(0xFF4CAF50),
              features: const [
                "Accès à toutes les fonctionnalités",
                "Jusqu'à 50 produits",
                "1 utilisateur",
                "Support de base",
              ],
              isPopular: false,
              onPressed: () => souscrire("essai"),
            ),

            const SizedBox(height: 25),

            // Carte Pro
            _buildPlanCard(
              title: "Professionnel",
              price: "25 000 FCFA",
              duration: "3 mois",
              color: const Color(0xFFFF9800),
              features: const [
                "Toutes les fonctionnalités Premium",
                "Produits illimités",
                "Jusqu'à 5 utilisateurs",
                "Support prioritaire",
                "Sauvegarde automatique",
                "Statistiques avancées",
              ],
              isPopular: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentAbonnementScreen(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mentions légales
            Text(
              "Résiliation possible à tout moment. Aucun remboursement après paiement.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),

            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required Color color,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                "LE PLUS POPULAIRE",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:BorderRadius.only(
                bottomLeft: const Radius.circular(16),
                bottomRight:const Radius.circular(16),
                topLeft: Radius.circular(isPopular ? 0 : 16),
                topRight: Radius.circular(isPopular ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        duration,
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title == "Essai Gratuit"
                      ? "Sans engagement"
                      : "Soit 10 000 FCFA/mois",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onPressed,
                    child: Text(
                      title == "Essai Gratuit"
                          ? "Commencer l'essai"
                          : "Choisir cette offre",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}