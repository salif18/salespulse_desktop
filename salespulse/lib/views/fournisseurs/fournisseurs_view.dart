import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/fournisseurs_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/fournisseur_api.dart';
import 'package:salespulse/utils/app_size.dart';

class FournisseurView extends StatefulWidget {
  const FournisseurView({super.key});

  @override
  State<FournisseurView> createState() => _FournisseurViewState();
}

class _FournisseurViewState extends State<FournisseurView> {
  ServicesFournisseurs api = ServicesFournisseurs();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<FournisseurModel>> _listFournisseurs =
      StreamController<List<FournisseurModel>>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _numero = TextEditingController();
  final _address = TextEditingController();
  final _produit = TextEditingController();

  @override
  void initState() {
    _getfournisseurs();
    super.initState();
  }

  @override
  void dispose() {
    _listFournisseurs.close();
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    _address.dispose();
    _produit.dispose();
    super.dispose();
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getfournisseurs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.getFournisseurs(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final fournisseurs = (body["fournisseurs"] as List)
              .map((json) => FournisseurModel.fromJson(json))
              .toList();
          _listFournisseurs.add(fournisseurs);
        });
      }
    } catch (e) {
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

//SUPPRIMER CATEGORIE API
  Future<void> _removeFournisseur(id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteFournisseurs(id, token);
      final body = res.data;
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _getfournisseurs(); // Actualiser la liste des catégories
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

//AJOUTER CATEGORIE API
  Future<void> _sendToserver(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    if (_globalKey.currentState!.validate()) {
      final data = {
        "userId": userId,
        "adminId":adminId,
        "prenom": _prenom.text,
        "nom": _nom.text,
        "numero": _numero.text,
        "address": _address.text,
        "produit": _produit.text
      };
      try {
        showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        final res = await api.postFournisseur(data, token);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          _getfournisseurs();
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _getfournisseurs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xff001c30),
            expandedHeight: 50, // Augmentation de la hauteur
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Mes fournisseurs",
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          // Utiliser un SliverList à la place d'un ListView.builder pour éviter les conflits de défilement
          StreamBuilder<List<FournisseurModel>>(
            stream: _listFournisseurs.stream,
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
                                children: [
                                   Image.asset("assets/images/erreur.png",width: 200,height: 200, fit: BoxFit.cover),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Erreur de chargement des données. Verifier votre réseau de connexion. Réessayer en tirant l'ecrans vers le bas!!",
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ))),
                      const SizedBox(width: 40),
                      IconButton(
                          onPressed: () {
                            _refresh();
                          },
                          icon: const Icon(Icons.refresh_outlined,
                              size: AppSizes.iconLarge))
                    ],
                  ),
                )));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                    child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Image.asset("assets/images/not_data.png",width: 200,height: 200, fit: BoxFit.cover),
                                  const SizedBox(height: 20),
                        Text("Pas de données disponibles",style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.w400),),
                      ],
                    )));
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      child: LayoutBuilder(builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowHeight: 35,
                                headingRowColor:
                                    WidgetStateProperty.all(Colors.orange),
                                headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                columns: [
                                  DataColumn(
                                      label: Text(
                                    'PHOTO',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black
                                        ),
                                  )),
                                  DataColumn(
                                      label: Text('NOM',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                                color: Colors.black,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('TEL',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                                color: Colors.black,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('PRODUIT',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                                color: Colors.black,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('ADRESSE',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                                color: Colors.black,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('ACTION',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                                color: Colors.black,
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: snapshot.data!.map((fournisseur) {
                                  return DataRow(
                                    cells: [
                                      // Logo
                                      DataCell(
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipOval(child: Image.asset("assets/images/contact2.png",width: 50,height: 50,)),
                                        ),
                                      ),
                      
                                      // Nom
                                      DataCell(Text(
                                        fournisseur.prenom,
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                        ),
                                      )),
                      
                                      // Tél
                                      DataCell(Text(fournisseur.numero.toString(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                          ))),
                      
                                      // Produit
                                      DataCell(Text(fournisseur.produit,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                          ))),
                      
                                      // Adresse
                                      DataCell(Text(fournisseur.address,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                          ))),
                      
                                      // Action (supprimer)
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                              Icons.person_remove_alt_1,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm =
                                                await showRemoveFournisseur(
                                                    context);
                                            if (confirm == true) {
                                              _removeFournisseur(fournisseur.id);
                                            }
                                          },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        onPressed: () {
          _addFournisseurShow(context);
        },
        child: const Icon(
          Icons.add,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

//FENETRE POUR AJOUTER CATEGORIE
  void _addFournisseurShow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Ajouter categories",
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _globalKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _prenom,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer le prenom du fournisseur';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Prénom du fournisseur",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nom,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer le nom du fournisseur';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Nom du fournisseur",
                        hintStyle:
                            GoogleFonts.roboto(fontSize: AppSizes.fontMedium),
                        prefixIcon: const Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _numero,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer le numero du fournisseur';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Numero du fournisseur",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.phone,
                          size: 24,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _produit,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer le nom du produit';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Nom du produit",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.article_rounded,
                          size: 24,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _address,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer address du fournisseur';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Address du fournisseur",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          size: 24,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _sendToserver(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
                        minimumSize: const Size(400, 50),
                      ),
                      child: Text(
                        "Enregistrer",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// FENTRE DIALOGUE POUR CONFIRMER LA SUPPRESSION
  Future<bool> showRemoveFournisseur(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer"),
          content: const Text(
              "Êtes-vous sûr de vouloir supprimer cette catégorie ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Annuler", style: GoogleFonts.roboto(fontSize: 14, color: Colors.blueAccent)),
            ),
            TextButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Supprimer", style: GoogleFonts.roboto(fontSize: 14,color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
