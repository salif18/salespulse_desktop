import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stocks_api.dart';

class CreateInventaire extends StatefulWidget {
  final List<ProduitInventaire> produits;

  const CreateInventaire({super.key, required this.produits});

  @override
  State<CreateInventaire> createState() => _CreateInventaireState();
}

class _CreateInventaireState extends State<CreateInventaire> {
  ServicesStocks api = ServicesStocks();
  late List<ProduitInventaire> produits;

  @override
  void initState() {
    super.initState();
    produits = widget.produits.map((p) => p.copy()).toList();
  }

  void _validerInventaire(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    for (var p in produits) {
      try {
        // Créez un map avec les données de base
        Map<String, dynamic> data = {
          "userId": userId,
          "nom": p.nom,
          "categories": p.categories,
          "prix_achat": p.prixAchat,
          "prix_vente": p.prixVente,
          "stocks": p.stockReel.toString(),
          "date_achat": p.dateAchat.toIso8601String(),
        };

        // envoie de lineventaire historique
        FormData formData = FormData.fromMap(data);
        final res = await api.updateProduct(formData, token, p.id);
        if (res.statusCode == 200) {
          // Si écart → enregistrer historique
          if (p.ecart != 0) {
            Map<String, dynamic> historiqueData = {
              "userId": userId,
              "nom": p.nom,
              "stock_systeme": p.stockSysteme,
              "stock_reel": p.stockReel,
              "ecart": p.ecart,
              "date": DateTime.now().toIso8601String(),
              "operateur":
                  p.operateur ?? "", // ou récupéré via AuthProvider si besoin
              "motif": p.motif ?? "",
              "productId": p.id,
            };

            final historiqueRes =
                await api.saveHistoriqueInventaire(historiqueData, token);

            if (historiqueRes.statusCode == 201) {
              // ignore: avoid_print
              print("📦 Historique enregistré !");
            } else {
              // ignore: avoid_print
              print("⚠️ Échec enregistrement historique");
            }
          }
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventaire mis à jour avec succès.")),
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print("❌ Erreur serveur ${p.nom} : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Création d'inventaire",
            style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff001c30),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context, true); // <- retourne 'true' à la page précédente
            },
            icon:const Icon(
              Icons.arrow_back_ios_outlined,
              color: Colors.white,
              size: 18,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: produits.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  final ecart = produit.stockReel - produit.stockSysteme;
                  return Container(
                    color: Colors.white,
                   
                    child: ListTile(
                      title: Text(produit.nom,
                          style: GoogleFonts.roboto(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Stock enregistré: ${produit.stockSysteme}",
                              style: GoogleFonts.roboto(
                                  fontSize: 14, fontWeight: FontWeight.w400)),
                          Row(
                            children: [
                              Text("Stock réel: ",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14, fontWeight: FontWeight.w400)),
                              Expanded(
                                child: TextFormField(
                                  initialValue: produit.stockReel.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      produit.stockReel = int.tryParse(value) ??
                                          produit.stockReel;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (ecart != 0)
                            Text(
                              "Écart: ${ecart > 0 ? '+' : ''} $ecart",
                              style: GoogleFonts.roboto(
                                color: ecart > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          if (ecart != 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Motif de l'écart",
                                  labelStyle: GoogleFonts.roboto(
                                      fontSize: 14, fontWeight: FontWeight.w400),
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    produit.motif = value;
                                  });
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: "Opérateur",
                                labelStyle: GoogleFonts.roboto(
                                    fontSize: 14, fontWeight: FontWeight.w400),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  produit.operateur = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => _validerInventaire(context),
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.orange,
                ),
                label: Text(
                  "Valider l'inventaire",
                  style: GoogleFonts.roboto(
                    color: Colors.orange,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff001c30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProduitInventaire {
  final String id;
  String image;
  final String nom;
  String categories;
  int prixAchat;
  int prixVente;
  DateTime dateAchat;
  final int stockSysteme;
  int stockReel;
  String? motif;
  String? operateur;

  ProduitInventaire(
      {required this.id,
      required this.image,
      required this.nom,
      required this.categories,
      required this.prixAchat,
      required this.prixVente,
      required this.dateAchat,
      required this.stockSysteme,
      required this.stockReel,
      this.motif,
      this.operateur});

  double get ecart => stockReel.toDouble() - stockSysteme;

  ProduitInventaire copy() => ProduitInventaire(
      id: id,
      image: image,
      nom: nom,
      categories: categories,
      prixAchat: prixAchat,
      prixVente: prixVente,
      dateAchat: dateAchat,
      stockSysteme: stockSysteme,
      stockReel: stockReel,
      motif: motif,
      operateur: operateur);
}

List<ProduitInventaire> convertirEnInventaire(List<ProductModel> stocks) {
  return stocks.map((article) {
    return ProduitInventaire(
        id: article.id,
        image: article.image!,
        nom: article.nom,
        categories: article.categories,
        prixAchat: article.prixAchat,
        prixVente: article.prixVente,
        dateAchat: article.dateAchat,
        stockSysteme: article.stocks,
        stockReel: article.stocks,
        motif: "",
        operateur: "");
  }).toList();
}
