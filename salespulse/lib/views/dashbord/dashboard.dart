import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/bar_chart.dart';
import 'package:salespulse/components/line_chart.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/models/stats_categorie_model.dart';
import 'package:salespulse/models/stats_week_model.dart';
import 'package:salespulse/models/stats_year_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/depense_api.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/utils/format_prix.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  FormatPrice formatPrice = FormatPrice();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  ServicesDepense depenseApi = ServicesDepense();
  ServicesStocks stockApi = ServicesStocks();
  ServicesVentes venteApi = ServicesVentes();
  ServicesStats statsApi = ServicesStats();

  List<ProduitBestVendu> populaireVente = [];
  List<ProductModel> stocks = [];
  List<StatsWeekModel> statsHebdo = [];
  List<StatsYearModel> statsYear = [];
  int totalAchatOfAchat = 0;
  int totalAchatOfVente = 0;
  int beneficeTotal = 0;
  int venteTotal = 0;
  int depenseTotal = 0;

  int totalHebdo = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
    _loadVentes();
    _loadDepenses();
    _loadMostCategorie();
    _loadStatsHebdo();
    _loadStatsYear();
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await stockApi.getAllProducts(token, userId);
      final body = res.data;
      if (res.statusCode == 200) {
        // Ajouter les produits au stream
        setState(() {
          stocks = (body["produits"] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
          totalAchatOfAchat = body["totalAchatOfAchat"];
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  Future<void> _loadDepenses() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await depenseApi.getAllDepenses(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          depenseTotal = body["depensesTotal"];
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadVentes() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await venteApi.getAllVentes(token, userId);
      final body = res.data;

      if (res.statusCode == 200) {
        setState(() {
          totalAchatOfVente = body["totalAchatOfVente"];
          venteTotal = body["total_vente"];
          beneficeTotal = body["benefice_total"];
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadMostCategorie() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsByCategories(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          populaireVente = (body["results"] as List)
              .map((json) => ProduitBestVendu.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadStatsHebdo() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsHebdo(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          totalHebdo = body["totalHebdo"];
          statsHebdo = (body["stats"] as List)
              .map((json) => StatsWeekModel.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadStatsYear() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsByMonth(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          statsYear = (body["results"] as List)
              .map((json) => StatsYearModel.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loadProducts();
      _loadDepenses();
      _loadMostCategorie();
      _loadStatsHebdo();
      _loadStatsYear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        
        // ignore: deprecated_member_use
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          backgroundColor: Colors.transparent,
          color: Colors.grey[100],
          onRefresh: _refresh,
          displacement: 40,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xff001c30),
                toolbarHeight: 50,
                pinned: true,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("Tableau de bord",
                      style: GoogleFonts.roboto(
                          fontSize: 14, color: Colors.white)),
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                _statsWeek(context),
                _statsCaisse2(context),
                _statsAnnuel(context)
              ]))
            ],
          ),
        ));
  }

  Widget _statsWeek(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                child: Text("Hebdomadaire",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color.fromARGB(255, 41, 40, 40)))),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16, bottom: 4),
              child: Text(formatPrice.formatNombre(totalHebdo.toString()),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.green)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: const Color.fromARGB(255, 36, 34, 34)
                              // ignore: deprecated_member_use
                              .withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: BarChartWidget(
                      data: statsHebdo,
                    ),
                  ),
                ),
                Expanded(flex: 1, child: _statsStock(context)),
                Expanded(flex: 1, child: _statsCaisse1(context))
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsStock(BuildContext context) {
    List<ProductModel> filterStocks =
        stocks.where((product) => product.stocks == 0).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
     // height: 350,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatContainer(
            title: "Les plus achetés",
            icon: Icons.star_rate_rounded,
            iconColor: Colors.yellow,
            backgroundColor: Colors.deepOrange,
            textColor: Colors.white,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: populaireVente.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final stock = populaireVente[index];
                  return Row(
                    children: [
                      Container(
                        width: 100,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stock.id.nom,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            stock.id.categories,
                            style: GoogleFonts.roboto(
                                fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          stock.totalVendu.toString(),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 255, 238, 0),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildStatContainer(
            title: "Manque de stock",
            icon: Icons.hourglass_empty_rounded,
            iconColor: const Color.fromARGB(255, 236, 40, 40),
            backgroundColor: const Color(0xfff0f1f5),
            textColor: const Color.fromARGB(255, 39, 39, 39),
            child: filterStocks.isEmpty
                ? Center(
                    child: Text("Aucun stock manquant",
                        style: GoogleFonts.roboto(fontSize: 14)))
                : SizedBox(
                  //height: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics:const NeverScrollableScrollPhysics(),
                    itemCount: filterStocks.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final stock = filterStocks[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(stock.nom,
                                style: GoogleFonts.roboto(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text(stock.categories,
                                style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.orange.shade700)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color.fromARGB(255, 36, 34, 34).withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconLarge, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _statsCaisse(BuildContext context) {
    int revenu = beneficeTotal - depenseTotal;
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal:10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xfff0f1f5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 36, 34, 34)
                  // ignore: deprecated_member_use
                  .withOpacity(0.2), // Couleur de l'ombre
              spreadRadius: 2, // Taille de la diffusion de l'ombre
              blurRadius: 8, // Flou de l'ombre
              offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
            ),
          ],
        ),
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.line_axis_rounded,
                        size: 24, color: Colors.green)),
                Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      "Etat de caisse",
                      style: GoogleFonts.roboto(fontSize: 16),
                    ))
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    formatPrice.formatNombre(revenu.toString()),
                    style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: revenu < 0 ? Colors.red : Colors.black),
                  ),
                  const SizedBox(width: 25),
                  revenu > 0
                      ? const Icon(
                          Icons.arrow_upward_rounded,
                          size: 24,
                          color: Colors.blue,
                        )
                      : const Icon(
                          Icons.arrow_downward_outlined,
                          size: 16,
                          color: Colors.red,
                        )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statsCaisse1(BuildContext context) {
    int prixGlobalAchat = totalAchatOfAchat + totalAchatOfVente;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:8.0),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 36, 34, 34)
                      // ignore: deprecated_member_use
                      .withOpacity(0.2), // Couleur de l'ombre
                  spreadRadius: 2, // Taille de la diffusion de l'ombre
                  blurRadius: 8, // Flou de l'ombre
                  offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                ),
              ],
            ),
            height: 135,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.monetization_on,
                            size: 24, color: Color.fromARGB(255, 255, 230, 1))),
                    Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          "Chiffre d'affaire (prix d'achat)",
                          style: GoogleFonts.roboto(
                              fontSize: 16, color: Colors.white),
                        ))
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    formatPrice.formatNombre(prixGlobalAchat.toString()),
                    style:
                        GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 36, 34, 34)
                      // ignore: deprecated_member_use
                      .withOpacity(0.2), // Couleur de l'ombre
                  spreadRadius: 2, // Taille de la diffusion de l'ombre
                  blurRadius: 8, // Flou de l'ombre
                  offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                ),
              ],
            ),
            height: 135,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.attach_money_outlined,
                          size: 24,
                          color: Colors.white,
                        )),
                    Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          "Prix de vente",
                          style: GoogleFonts.roboto(
                              fontSize: 16, color: Colors.white),
                        ))
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    formatPrice.formatNombre(venteTotal.toString()),
                    style:
                        GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCaisse2(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:8.0),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statsCaisse(context),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 36, 34, 34)
                        // ignore: deprecated_member_use
                        .withOpacity(0.2), // Couleur de l'ombre
                    spreadRadius: 2, // Taille de la diffusion de l'ombre
                    blurRadius: 8, // Flou de l'ombre
                    offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                  ),
                ],
              ),
              height: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.monetization_on,
                            size: 24,
                            color: Color.fromARGB(255, 255, 255, 255),
                          )),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            "Benefices",
                            style: GoogleFonts.roboto(
                                fontSize: 16, color: Colors.white),
                          ))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      formatPrice.formatNombre(beneficeTotal.toString()),
                      style:
                          GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF292D4E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 36, 34, 34)
                        // ignore: deprecated_member_use
                        .withOpacity(0.2), // Couleur de l'ombre
                    spreadRadius: 2, // Taille de la diffusion de l'ombre
                    blurRadius: 8, // Flou de l'ombre
                    offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                  ),
                ],
              ),
              height: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.monetization_on,
                              size: 24,
                              color: Color.fromARGB(255, 255, 17, 0))),
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            "Depenses",
                            style: GoogleFonts.roboto(
                                fontSize: 16, color: Colors.white),
                          ))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      formatPrice.formatNombre(depenseTotal.toString()),
                      style:
                          GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsAnnuel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text("Annuel",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
            ),
            const SizedBox(height: 4),
            LineChartWidget(data: statsYear),
          ],
        ),
      ),
    );
  }
}
