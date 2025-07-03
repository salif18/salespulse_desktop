import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/depenses_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/depense_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/utils/format_prix.dart';

class DepensesView extends StatefulWidget {
  const DepensesView({super.key});

  @override
  State<DepensesView> createState() => _DepensesViewState();
}

class _DepensesViewState extends State<DepensesView> {
  FormatPrice formatPrice = FormatPrice();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  // Clé Key du formulaire
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  ServicesDepense api = ServicesDepense();
  final StreamController<List<DepensesModel>> _streamController =
      StreamController();
  List<DepensesModel> filteredDepenses = [];
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
  }

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    _streamController
        .close(); // Fermer le StreamController pour éviter les fuites de mémoire
    super.dispose();
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Vérifier si le widget est monté avant d'appeler setState()
      setState(() {
        _loadProducts(); // Rafraîchir les produits
      });
    }
    if (!mounted) return;
  }

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getAllDepenses(token, userId);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final depenses = (body["results"] as List)
            .map((json) => DepensesModel.fromJson(json))
            .toList();

        if (!_streamController.isClosed) {
          _streamController.add(depenses); // Ajouter les dépenses au stream
        }
      if (!mounted) return;
        setState(() {
          filteredDepenses = selectedDate == null
              ? depenses
              : depenses.where((article) {
                  return article.date.year == selectedDate!.year &&
                      article.date.month == selectedDate!.month &&
                      article.date.day == selectedDate!.day;
                }).toList();
        });
        
      } else {
        if (!_streamController.isClosed) {
          _streamController.addError("Failed to load depenses");
        }
      }
    } catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError("Error loading depenses");
      }
    }
  }

  // Envoie des donnees vers le server
  Future<void> _sendNewDepenseToServer() async {
    if (_globalKey.currentState!.validate()) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;

      final data = {
        "userId": userId,
        "montants": _montantController.text,
        "motifs": _motifController.text
      };

      try {
        final res = await api.postNewDepenses(data, token);
        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          // ignore: use_build_context_synchronously
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const DepensesView()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  int _totalFilter() {
    return filteredDepenses.isEmpty
        ? 0
        : filteredDepenses
            .map((article) => article.montants)
            .reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: const Color(0xff001c30),
              expandedHeight: 40,
              pinned: true,
              floating: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Dépenses",
                    style:
                        GoogleFonts.roboto(fontSize: 16, color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color.fromARGB(255, 0, 40, 68),
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(                  
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              "Total",
                              style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            )),
                        Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              "${_totalFilter()} XOF",
                              style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            )),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      constraints:
                          const BoxConstraints(maxWidth: 250, maxHeight: 40),
                      child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color.fromARGB(255, 255, 136, 0),
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                        
                            if (picked != null && mounted) {
                              setState(() {
                                selectedDate = picked;
                              });
                              await _loadProducts(); // Recharge avec filtre
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 136, 0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  selectedDate == null
                                      ? 'Choisir une date'
                                      : DateFormat('dd MMM yyyy').format(selectedDate!),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<DepensesModel>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color:Colors.orange,
                            size:50
                        )),
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    "Erreur de chargement des données. Verifier votre réseau de connexion. Réessayer en tirant l'ecrans vers le bas !!",
                                    style: GoogleFonts.roboto(fontSize: 14),
                                  ))),
                          const SizedBox(width: 40),
                          IconButton(
                              onPressed: () {
                                _refresh();
                              },
                              icon:
                                  const Icon(Icons.refresh_outlined, size: 24))
                        ],
                      ),
                    )),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return  SliverFillRemaining(child: Text("Aucun produit disponible.",style: GoogleFonts.poppins(fontSize: 18),));
                } else {
                  final List<DepensesModel> depenses = snapshot.data!;
                  // Filtrer les articles par la date sélectionnée
                  filteredDepenses = selectedDate == null
                      ? depenses
                      : depenses.where((article) {
                          if (selectedDate != null) {
                            return article.date.year == selectedDate!.year &&
                                article.date.month == selectedDate!.month &&
                                article.date.day == selectedDate!.day;
                          }
                          return false;
                        }).toList();
                         if (filteredDepenses.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                              "Aucune dépense trouvé pour la date sélectionnée.",style: GoogleFonts.poppins(fontSize: 18),),
                        ),
                      );
                    }
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDepenses.length,
                        itemBuilder: (BuildContext context, int index) {
                          DepensesModel depense = filteredDepenses[index];
                          return Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color.fromARGB(255, 230, 230, 230)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 15),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              depense.motifs,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                formatPrice.formatNombre(
                                                    depense.montants.toString()),
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Date",
                                        style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Expanded(
                                        child: Text(DateFormat("dd MMM yyyy")
                                            .format(depense.date)),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        ),
        onPressed: () {
          _addDepenses(context);
        },
        child: const Icon(Icons.add,
            size: AppSizes.iconLarge, color: Colors.white),
      ),
    );
  }

  void _addDepenses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(15),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Form(
            key: _globalKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Enregistrer vos depenses",
                      style: GoogleFonts.roboto(
                          fontSize: AppSizes.fontMedium,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _montantController,
                    decoration: const InputDecoration(
                        labelText: "Somme depensée",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Le nom du produit est requis";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _motifController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                        labelText: "Motif du depense",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "La description est requise";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 115, 0),
                        minimumSize: const Size(400, 50)),
                    onPressed: () {
                      _sendNewDepenseToServer();
                      Navigator.pop(context);
                    },
                    child: Text("Enregistrer",
                        style: GoogleFonts.roboto(
                            fontSize: AppSizes.fontMedium,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
