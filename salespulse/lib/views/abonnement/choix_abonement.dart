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
      await api.acheterAbonnement(context: context, type: type, token: token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Abonnement $type activé avec succès.")),
      );

      // Redirection (par exemple vers la page d’accueil)
      Navigator.pop(context,true);
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.response?.data['error'] ?? 'Échec de l’abonnement'}")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir un abonnement"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCard(
              title: "Essai Gratuit",
              description: "Durée : 7 jours.\nAccès complet à toutes les fonctionnalités.",
              color: Colors.green[400]!,
              onPressed: () => souscrire("essai"),
            ),
            const SizedBox(height: 20),
            _buildCard(
              title: "Pro - 3 Mois",
              description: "Durée : 3 mois.\nSupport prioritaire + accès complet.",
              color: Colors.orange[600]!,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> const PaymentAbonnementScreen())),
            ),
            if (loading) const Padding(
              padding: EdgeInsets.only(top: 30),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 10),
            Text(description,
                style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.monetization_on_outlined),
              label: Text("S'abonner" ,style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
