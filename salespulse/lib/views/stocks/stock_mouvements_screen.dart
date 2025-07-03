// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/mouvements_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/mouvement_api.dart';

class MouvementsListFiltered extends StatefulWidget {
  final String productId;
  final String token;

  const MouvementsListFiltered(
      {super.key, required this.productId, required this.token});

  @override
  // ignore: library_private_types_in_public_api
  _MouvementsListFilteredState createState() => _MouvementsListFilteredState();
}

class _MouvementsListFilteredState extends State<MouvementsListFiltered> {
  final ServicesMouvements api = ServicesMouvements();

  List<MouvementModel> mouvements = [];
  int page = 1;
  int limit = 20;
  int totalPages = 1;

  String? selectedType;
  DateTime? dateDebut;
  DateTime? dateFin;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMouvements();
  }

  Future<void> fetchMouvements({bool reset = false}) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    if (reset) {
      page = 1;
      mouvements.clear();
    }

    if (page > totalPages) return; // plus de pages

    setState(() => isLoading = true);

    try {
      final result = await api.getMouvements(
        userId: userId,
        token: widget.token,
        productId: widget.productId,
        type: selectedType,
        dateDebut: dateDebut,
        dateFin: dateFin,
        page: page,
        limit: limit,
      );

      final List<MouvementModel> mouvementsJson = result["mouvements"] ?? [];
      final pagination = result["pagination"] ?? {};

      setState(() {
        mouvements.addAll(mouvementsJson);
        totalPages = pagination["totalPages"] ?? 1;
        page++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showFilterDialog() {
    String? tempType = selectedType;
    DateTime? tempDateDebut = dateDebut;
    DateTime? tempDateFin = dateFin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filtrer les mouvements"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempType,
                hint: const Text("Type de mouvement"),
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text(
                        "Tous",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black),
                      )),
                  DropdownMenuItem(
                      value: 'ajout',
                      child: Text('Ajout',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'vente',
                      child: Text('Vente',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'retrait',
                      child: Text('Retrait',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'perte',
                      child: Text('Perte',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'modification',
                      child: Text('Modification',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.white))),
                ],
                onChanged: (value) {
                  tempType = value;
                },
              ),
              const SizedBox(height: 12),
              // Date pickers
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempDateDebut ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      tempDateDebut = date;
                    });
                  }
                },
                child: Text(
                    tempDateDebut == null
                        ? "Sélectionner date début"
                        : "Début: ${DateFormat('dd/MM/yyyy').format(tempDateDebut!)}",
                    style:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempDateFin ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      tempDateFin = date;
                    });
                  }
                },
                child: Text(
                    tempDateFin == null
                        ? "Sélectionner date fin"
                        : "Fin: ${DateFormat('dd/MM/yyyy').format(tempDateFin!)}",
                    style:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                selectedType = tempType;
                dateDebut = tempDateDebut;
                dateFin = tempDateFin;
                mouvements.clear();
                page = 1;
              });
              fetchMouvements(reset: true);
              Navigator.pop(context);
            },
            child: Text("Appliquer",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "ajout":
        return Icons.add_box;
      case "vente":
        return Icons.remove_shopping_cart;
      case "retrait":
        return Icons.indeterminate_check_box;
      case "perte":
        return Icons.error_outline;
      case "modification":
        return Icons.edit;
      default:
        return Icons.device_unknown;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case "ajout":
        return Colors.green.shade700;
      case "vente":
        return Colors.red.shade700;
      case "retrait":
        return Colors.orange.shade700;
      case "perte":
        return Colors.grey.shade700;
      case "modification":
        return Colors.blue.shade700;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
              size: 18,
              color: Colors.white,
            )),
        title: Text(
          "Historique des mouvements",
          style: GoogleFonts.roboto(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff001c30),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.orange.shade700,),
            tooltip: "Filtrer",
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: mouvements.isEmpty && !isLoading
          ? Center(
              child: Text(
                "Aucun mouvement trouvé.",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    page <= totalPages) {
                  fetchMouvements();
                  return true;
                }
                return false;
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: mouvements.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == mouvements.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final mouv = mouvements[index];
                  final color = _colorForType(mouv.type);

                  return Card(
                    color: Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      leading: CircleAvatar(
                        // ignore: deprecated_member_use
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(
                          _iconForType(mouv.type),
                          color: color,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        "${mouv.type.toUpperCase()} • ${mouv.quantite}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "${DateFormat('dd/MM/yyyy HH:mm').format(mouv.date)}\n${mouv.description}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Avant : ${mouv.ancienStock}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "Après : ${mouv.nouveauStock}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
