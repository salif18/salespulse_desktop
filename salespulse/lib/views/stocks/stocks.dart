// ignore_for_file: depend_on_referenced_packages

import 'dart:async'; // Pour StreamController
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/utils/format_prix.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
import 'package:salespulse/views/stocks/stock_mouvements_screen.dart';
import 'package:salespulse/views/update_stock/update_stock.dart';

class StocksView extends StatefulWidget {
  const StocksView({super.key});

  @override
  State<StocksView> createState() => _StocksViewState();
}

class _StocksViewState extends State<StocksView> {
  FormatPrice formatPrice = FormatPrice();
  ServicesStocks api = ServicesStocks();
  ServicesCategories apiCatego = ServicesCategories();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();

  final StreamController<List<ProductModel>> _streamController =
      StreamController();
  List<CategoriesModel> _listCategories = [];
  List<ProductModel> inventaireList = [];
  String? _categorieValue;

// configuration des champs de formulaires pour le controller
  final _nameController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _stockController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _getCategories();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _stockController.dispose();
    _streamController.close();
    super.dispose();
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loadProducts();
      _getCategories();
    });
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await api.getAllProducts(token);
      final body = res.data;

      if (res.statusCode == 200) {
        final products = (body["produits"] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();

        setState(() {
          inventaireList = products;
        });

        if (!_streamController.isClosed) {
          _streamController.add(products); // Ajouter les produits au stream
        } else {
          debugPrint("StreamController is closed, cannot add products.");
        }
      } else {
        if (!_streamController.isClosed) {
          _streamController.addError("Failed to load products");
        }
      }
    } on DioException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Problème de connexion : Vérifiez votre Internet.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
      if (!_streamController.isClosed) {
        _streamController.addError("Error loading products");
      }
    }
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await apiCatego.getCategories(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          _listCategories = (body["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          // 👉 Afficher message spécifique abonnement expiré
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Abonnement expiré"),
              content: const Text(
                  "Votre abonnement a expiré. Veuillez le renouveler."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AbonnementScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return;
        }
      }

      // 🚫 Autres DioException (ex: réseau)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
  }

  Future<void> _removeArticles(article) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteProduct(article.id, token);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _loadProducts();
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        backgroundColor: Colors.transparent,
        color: Colors.grey[100],
        onRefresh: _refresh,
        displacement: 50,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white, //const Color(0xff001c30),
              expandedHeight: 40,
              pinned: true,
              floating: true,
              flexibleSpace: FlexibleSpaceBar(
                title: AutoSizeText("Les stocks",
                    minFontSize: 16,
                    style:
                        GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  // color: const Color.fromARGB(255, 0, 40, 68),
                  color: Colors.white,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                          maxHeight:
                              40, // un peu plus haut pour éviter que le texte soit coupé
                        ),
                        child: DropdownButtonFormField<String>(
                          isDense: true,
                          value: _categorieValue,
                          dropdownColor: const Color(0xff001c30),
                          borderRadius: BorderRadius.circular(10),
                          style: GoogleFonts.roboto(
                              fontSize: 14, color: Colors.white),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            filled: true,
                            fillColor: Colors.blueGrey,
                            hintText: "Choisir une catégorie",
                            hintStyle: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                "Toutes les catégories",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ..._listCategories.map((categorie) {
                              return DropdownMenuItem<String>(
                                value: categorie.name,
                                child: Text(
                                  categorie.name,
                                  style: GoogleFonts.roboto(
                                      fontSize: 13, color: Colors.white),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _categorieValue = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "La catégorie est requise";
                            }
                            return null;
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Rechercher un produit...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<List<ProductModel>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.orange, size: 50)),
                  );
                } else if (snapshot.hasError) {
                  return SliverFillRemaining(
                      child: Center(
                          child: Container(
                    padding: const EdgeInsets.all(8),
                    height: MediaQuery.of(context).size.width * 0.4,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/images/erreur.png",
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover),
                                    const SizedBox(height: 20),
                                    Text(
                                      "Erreur de chargement des données. Verifier votre réseau de connexion et réessayer !!",
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ],
                                ))),
                        const SizedBox(width: 40),
                        IconButton(
                            onPressed: () {
                              _refresh();
                            },
                            icon: const Icon(Icons.refresh_outlined, size: 24))
                      ],
                    ),
                  )));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/images/not_data.png",
                            width: 200, height: 200, fit: BoxFit.cover),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Aucune catégorie disponible.",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    )),
                  );
                } else {
                  final articles = snapshot.data!;
                  final filteredByCategory = _categorieValue == null
                      ? articles
                      : articles
                          .where((article) =>
                              article.categories == _categorieValue)
                          .toList();

                  final filteredArticles = _searchQuery.isEmpty
                      ? filteredByCategory
                      : filteredByCategory
                          .where((article) => article.nom
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (filteredArticles.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Aucun article trouvé.",
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowHeight: 35,
                                  headingRowColor:
                                      WidgetStateProperty.all(Colors.blueGrey),
                                  headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        "Photo".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Name".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Categories".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Prix d'achat".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Prix de vente".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Quantités".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Statut".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Date".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Actions".toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: filteredArticles.map((article) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          (article.image ?? "").isEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Image.asset(
                                                    "assets/images/defaultImg.png",
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Image.network(
                                                    article.image!,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                ),
                                        ),
                                        DataCell(
                                          Text(
                                            article.nom,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            article.categories,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            formatPrice.formatNombre(
                                                article.prixAchat.toString()),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (article.isPromo) ...[
                                                Text(
                                                  formatPrice.formatNombre(
                                                      article.prixPromo
                                                          .toString()),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  formatPrice.formatNombre(
                                                      article.prixVente
                                                          .toString()),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ] else
                                                Text(
                                                  formatPrice.formatNombre(
                                                      article.prixVente
                                                          .toString()),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            article.stocks.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            article.statut.toString(),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: article.statut ==
                                                        "disponible"
                                                    ? Colors.green
                                                    : Colors.red),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            DateFormat("dd MMM yyyy")
                                                .format(article.dateAchat),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              if (article.stocks > 0 &&
                                                  role == "admin")
                                                Expanded(
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue),
                                                    onPressed: () {
                                                      // Action pour editer
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditProduitPage(
                                                                  product:
                                                                      article),
                                                        ),
                                                      ).then((modified) {
                                                        if (modified == true) {
                                                          // Rafraîchir les données si nécessaire
                                                          _loadProducts();
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                              if (article.stocks == 0 &&
                                                  role == "admin")
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .disabled_by_default_rounded,
                                                      color: Color.fromARGB(
                                                          255, 255, 67, 67)),
                                                  onPressed: () {
                                                    // Action pour supprimer le produit
                                                    _showAlertDelete(
                                                        context, article);
                                                  },
                                                ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  final token =
                                                      Provider.of<AuthProvider>(
                                                              context,
                                                              listen: false)
                                                          .token;
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          MouvementsListFiltered(
                                                        productId: article.id,
                                                        token: token,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                label: Text(
                                                  "historique",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                                icon: const Icon(
                                                    Icons.history_outlined),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

// alerte de confirmation de suppression
  Future<bool?> _showAlertDelete(BuildContext context, article) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Supprimer",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text("Êtes-vous sûr de vouloir supprimer cet article ?",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400)),
          actions: <Widget>[
            TextButton(
              onPressed: () => _removeArticles(article),
              child: Text("Supprimer",
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w400)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Annuler",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
