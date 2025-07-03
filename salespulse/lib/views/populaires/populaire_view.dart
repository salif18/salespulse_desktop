// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/vente_api.dart';

class ProduitTendance {
  final String productId;
  final String nom;
  final String image;
  final int quantiteTotale;

  ProduitTendance({
    required this.productId,
    required this.nom,
    required this.image,
    required this.quantiteTotale,
  });
}

class VenteProduit {
  final String productId;
  final String nom;
  final String image;
  final int quantite;

  VenteProduit({
    required this.productId,
    required this.nom,
    required this.image,
    required this.quantite,
  });

  factory VenteProduit.fromJson(Map<String, dynamic> json) {
    return VenteProduit(
      productId: json['productId'],
      nom: json['nom'],
      image: json['image'] ?? '',
      quantite: json['quantite'],
    );
  }
}

class VenteModel {
  final String id;
  final List<VenteProduit> produits;
  final DateTime date;

  VenteModel({
    required this.id,
    required this.produits,
    required this.date,
  });

  factory VenteModel.fromJson(Map<String, dynamic> json) {
    var produitsJson = json['produits'] as List<dynamic>;
    List<VenteProduit> produits =
        produitsJson.map((p) => VenteProduit.fromJson(p)).toList();

    return VenteModel(
      id: json['_id'],
      produits: produits,
      date: DateTime.parse(json['date']),
    );
  }
}

class StatistiquesProduitsPage extends StatefulWidget {
  const StatistiquesProduitsPage({super.key});

  @override
  State<StatistiquesProduitsPage> createState() =>
      _StatistiquesProduitsPageState();
}

class _StatistiquesProduitsPageState extends State<StatistiquesProduitsPage> {
  List<ProduitTendance> produitsTendance = [];
  bool isLoading = true;
  String errorMessage = '';

  ServicesVentes api = ServicesVentes();

  @override
  void initState() {
    super.initState();
    fetchVentes();
  }

  Future<void> fetchVentes() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;

      final response = await api.getAllVentes(token, userId);

      if (response.statusCode == 200) {
        List ventesJson = response.data["ventes"];
        List<VenteModel> ventes =
            ventesJson.map((json) => VenteModel.fromJson(json)).toList();

        Map<String, ProduitTendance> mapProduits = {};
        for (var vente in ventes) {
          for (var produit in vente.produits) {
            if (mapProduits.containsKey(produit.productId)) {
              final ancien = mapProduits[produit.productId]!;
              mapProduits[produit.productId] = ProduitTendance(
                productId: produit.productId,
                nom: produit.nom,
                image: produit.image,
                quantiteTotale: ancien.quantiteTotale + produit.quantite,
              );
            } else {
              mapProduits[produit.productId] = ProduitTendance(
                productId: produit.productId,
                nom: produit.nom,
                image: produit.image,
                quantiteTotale: produit.quantite,
              );
            }
          }
        }

        List<ProduitTendance> produitsTrie = mapProduits.values.toList();
        produitsTrie
            .sort((a, b) => b.quantiteTotale.compareTo(a.quantiteTotale));

        setState(() {
          produitsTendance = produitsTrie;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur lors du chargement des ventes";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur réseau: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Statistiques produits en tendance",
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: const Color(0xff001c30),
      ),
      body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(errorMessage,
                          style: const TextStyle(color: Colors.red)))
                  : produitsTendance.isEmpty
                      ? Center(
                          child: Text(
                          "Aucune donnée disponible",
                          style: GoogleFonts.roboto(
                              fontSize: 14, fontWeight: FontWeight.w400),
                        ))
                      : LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: Container(
                                color: Colors.white,
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowColor:
                                      WidgetStateProperty.all(Colors.orange),
                                  headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  columns: [
                                    DataColumn(
                                        label: Text(
                                      "Image".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Nom".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Quantité vendue".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    )),
                                  ],
                                  rows: produitsTendance.map((produit) {
                                    return DataRow(cells: [
                                      DataCell(
                                        produit.image.isNotEmpty
                                            ? Image.network(produit.image,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover)
                                            : const Icon(
                                                Icons.image_not_supported),
                                      ),
                                      DataCell(Text(produit.nom,
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black))),
                                      DataCell(Text(
                                          produit.quantiteTotale.toString(),
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black))),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        })),
    );
  }
}
