// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:salespulse/models/profil_model.dart';
import 'package:salespulse/models/vente_model_pro.dart';
import 'package:salespulse/models/client_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/client_api.dart';
import 'package:salespulse/services/profil_api.dart';
import 'package:salespulse/services/reglement_api.dart';
import 'package:salespulse/services/vente_api.dart';

class HistoriqueVentesScreen extends StatefulWidget {
  const HistoriqueVentesScreen({super.key});

  @override
  State<HistoriqueVentesScreen> createState() => _HistoriqueVentesScreenState();
}

class _HistoriqueVentesScreenState extends State<HistoriqueVentesScreen> {
  List<VenteModel> ventes = [];
  List<VenteModel> filteredVentes = [];
  List<ClientModel> clients = [];

  String searchQuery = "";
  DateTime? dateDebut;
  DateTime? dateFin;
  String? selectedClientId;
  String? selectedStatut;

  final ServicesVentes api = ServicesVentes();
  final ServicesClients _clientApi = ServicesClients();

  @override
  void initState() {
    super.initState();
    fetchClients();
    fetchVentes();
  }

  Future<void> fetchClients() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
  
    try {
      final res = await _clientApi.getClients(token);

      if (res.statusCode == 200) {
        setState(() {
          clients = (res.data["clients"] as List)
              .map((e) => ClientModel.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur fetchClients: $e");
    }
  }

  Future<void> fetchVentes() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await api.getAllVentes(
        token,
        clientId: selectedClientId,
        dateDebut: dateDebut != null
            ? DateFormat('yyyy-MM-dd').format(dateDebut!)
            : null,
        dateFin:
            dateFin != null ? DateFormat('yyyy-MM-dd').format(dateFin!) : null,
      );

      if (res.statusCode == 200) {
        final data = res.data;
        ventes = (data["ventes"] as List)
            .map((e) => VenteModel.fromJson(e))
            .toList();
        applyFilters();
      }
    } catch (e) {
      debugPrint("Erreur fetchVentes: $e");
    }
  }

  void applyFilters() {
    setState(() {
      filteredVentes = ventes.where((vente) {
        final matchSearch =
            vente.statut.toLowerCase().contains(searchQuery.toLowerCase());
        final matchStatut =
            selectedStatut == null || vente.statut == selectedStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text("Historique des ventes",
                style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ["Date", "Client", "Total", "Paiement", "Statut"],
              data: filteredVentes.map((vente) {
                return [
                  DateFormat('dd/MM/yyyy').format(vente.date),
                  vente.clientNom ?? "Occasionnel",
                  "${vente.total} Fcfa",
                  vente.typePaiement,
                  vente.statut
                ];
              }).toList(),
            )
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void resetFilters() {
    setState(() {
      dateDebut = null;
      dateFin = null;
      selectedClientId = null;
      searchQuery = "";
      selectedStatut = null;
    });
    fetchVentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          backgroundColor: const Color(0xff001c30),
          title: Text(
            "Historique des ventes",
            style: GoogleFonts.roboto(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          )),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Zone de filtres
            Container(
              // color: const Color.fromARGB(255, 0, 40, 68),
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 500,
                        height: 40,
                        child: TextField(
                          style: GoogleFonts.roboto(fontSize: 14),
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[200],
                              hintText: "Rechercher par statut...",
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 24,
                                color: Colors.orange.shade700,
                              ),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(20))),
                          onChanged: (val) {
                            searchQuery = val;
                            applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            maximumSize: const Size(200, 40)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              dateDebut = picked;
                            });
                            fetchVentes();
                          }
                        },
                        child: Text("Date début",
                            style: GoogleFonts.roboto(
                                fontSize: 14, color: Colors.white)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            maximumSize: const Size(200, 40)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              dateFin = picked;
                            });
                            fetchVentes();
                          }
                        },
                        child: Text("Date fin",
                            style: GoogleFonts.roboto(
                                fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("Client: ",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black)),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        icon: const Icon(Icons.people,
                            size: 18, color: Colors.white),
                        label: Text(
                          selectedClientId != null
                              ? clients
                                  .firstWhere((c) => c.id == selectedClientId)
                                  .nom
                              : "Tous les clients",
                          style: GoogleFonts.roboto(
                              color: Colors.white, fontSize: 13),
                        ),
                        onPressed: _ouvrirModalSelectionClient,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatut,
                            hint: Text("Filtrer par statut",
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.black87)),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.black54),
                            style: GoogleFonts.poppins(
                                color: Colors.black, fontSize: 13),
                            items: [
                              DropdownMenuItem(
                                  value: null,
                                  child: Text("Tous les statuts",
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.black))),
                              ...["payée", "crédit", "partiel"].map((statut) {
                                return DropdownMenuItem(
                                  value: statut,
                                  child: Text(
                                      statut[0].toUpperCase() +
                                          statut.substring(1),
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.black87)),
                                );
                              })
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedStatut = val;
                              });
                              applyFilters();
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print,
                            size: 24, color: Colors.blue),
                        onPressed: _generatePdf,
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            size: 24, color: Colors.orange.shade700),
                        onPressed: resetFilters,
                        tooltip: "Réinitialiser les filtres",
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Liste des ventes
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: BoxBorder.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(10)),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowHeight: 35,
                          headingRowColor:
                              WidgetStateProperty.all(Colors.orange.shade700),
                          headingTextStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          columns: [
                            DataColumn(
                                label: Text("Date".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Client".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Contact".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Total".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Paiement".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Statut".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Reste".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Monnaie".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Produits".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            DataColumn(
                                label: Text("Règlement de compte".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                          ],
                          rows: filteredVentes.map((vente) {
                            return DataRow(cells: [
                              DataCell(Text(
                                  DateFormat('dd/MM/yyyy').format(vente.date),
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(vente.clientNom ?? "Occasionnel",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(
                                  vente.contactClient ?? "Occasionnel",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text("${vente.total} Fcfa",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(vente.typePaiement,
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(vente.statut,
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(vente.reste.toString(),
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(vente.monnaie.toString(),
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.list),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text("Produits vendus",
                                                style: GoogleFonts.roboto(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.black)),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children:
                                                  vente.produits.map((prod) {
                                                return ListTile(
                                                  leading: prod.image != null &&
                                                          prod.image!.isNotEmpty
                                                      ? Image.network(
                                                          prod.image!,
                                                          width: 40)
                                                      : const Icon(Icons
                                                          .image_not_supported),
                                                  title: Text(prod.nom),
                                                  subtitle: Text(
                                                      "${prod.quantite} x ${prod.prixUnitaire} Fcfa",
                                                      style: GoogleFonts.roboto(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black)),
                                                  trailing: Text(
                                                      "${prod.sousTotal} Fcfa",
                                                      style: GoogleFonts.roboto(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black)),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.print,
                                          color: Colors.blue),
                                      tooltip: "Imprimer la facture",
                                      onPressed: () =>
                                          generateFacturePdf(vente),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (vente.reste > 0)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent),
                                        child: Text('Règlement',
                                            style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: Colors.white)),
                                        onPressed: () => _ouvrirDialogReglement(
                                            context, vente, "règlement"),
                                      ),
                                    if (vente.monnaie > 0)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent),
                                        child: Text('Remboursement',
                                            style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: Colors.white)),
                                        onPressed: () => _ouvrirDialogReglement(
                                            context, vente, "remboursement"),
                                      ),
                                  ],
                                ),
                              )
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () =>
            generateRapportPdfPro(filteredVentes, dateDebut, dateFin),
        tooltip: "Générer le rapport PDF",
        child: const Icon(Icons.bar_chart_outlined, color: Colors.white),
      ),
    );
  }

  void _ouvrirModalSelectionClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String query = '';
        List<ClientModel> resultats = [...clients];

        return StatefulBuilder(builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SizedBox(
              height: 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sélectionner un client",
                      style: GoogleFonts.roboto(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (val) {
                      query = val;
                      setStateModal(() {
                        resultats = clients
                            .where((c) => c.nom
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Rechercher un client...",
                      prefixIcon:
                          Icon(Icons.search, color: Colors.orange.shade700),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: resultats.length,
                      itemBuilder: (context, index) {
                        final client = resultats[index];
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(client.nom,
                              style: GoogleFonts.poppins(fontSize: 14)),
                          onTap: () {
                            setState(() {
                              selectedClientId = client.id;
                            });
                            Navigator.pop(context);
                            fetchVentes();
                          },
                        );
                      },
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedClientId = null;
                        });
                        Navigator.pop(context);
                        fetchVentes();
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      label: Text("Effacer le filtre",
                          style: GoogleFonts.roboto(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

// Charge une image depuis le réseau, ou renvoie null si erreur
  Future<pw.MemoryImage?> tryLoadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}
    return null; // échec du chargement réseau
  }

  Future<void> generateFacturePdf(VenteModel vente) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    // Charger logo depuis assets

    ProfilModel? profil;

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await ServicesProfil().getProfils(token);
      if (res.statusCode == 200) {
        profil = ProfilModel.fromJson(res.data["profils"]);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }

    // Tente de charger le logo depuis le net
    final pw.MemoryImage? logoNetwork =
        await tryLoadNetworkImage(profil?.image ?? "");

    // Charge image locale (à mettre dans assets et déclarer dans pubspec.yaml)
    final pw.ImageProvider logoLocal = pw.MemoryImage(
      (await rootBundle.load('assets/logos/salespulse.jpg'))
          .buffer
          .asUint8List(),
    );
    final int reste = (vente.total - vente.montantRecu) > 0
        ? (vente.total - vente.montantRecu)
        : 0;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(
                logoNetwork ?? logoLocal,
                width: 100,
                height: 100,
              ), // Logo centré
              pw.SizedBox(height: 10),
              pw.Text("FACTURE",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Facture N°: ${vente.id}",
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Date : ${dateFormatter.format(vente.date)}",
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text("Client : ${vente.clientNom ?? 'Ocasionnel'}",
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Text("Détail des produits :",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                border: null,
                headers: ["Produit", "Qté", "PU", "Sous-total"],
                data: vente.produits.map((p) {
                  return [
                    p.nom,
                    "${p.quantite}",
                    "${p.prixUnitaire} Fcfa",
                    "${p.sousTotal} Fcfa"
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Total : ${vente.total} Fcfa",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Montant reçu : ${vente.montantRecu} Fcfa",
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Monnaie : ${vente.monnaie} Fcfa",
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Reste à payer : $reste Fcfa",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text("Mode de paiement : ${vente.typePaiement}",
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Statut : ${vente.statut}",
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> generateRapportPdfPro(
      List<VenteModel> ventes, DateTime? dateDebut, DateTime? dateFin) async {
    final pdf = pw.Document();
    final format = DateFormat('dd/MM/yyyy');

    ProfilModel? profil;

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await ServicesProfil().getProfils(token);
      if (res.statusCode == 200) {
        profil = ProfilModel.fromJson(res.data["profils"]);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }

    // Tente de charger le logo depuis le net
    final pw.MemoryImage? logoNetwork =
        await tryLoadNetworkImage(profil?.image ?? "");

    // Charge image locale (à mettre dans assets et déclarer dans pubspec.yaml)
    final pw.ImageProvider logoLocal = pw.MemoryImage(
      (await rootBundle.load('assets/logos/salespulse.jpg'))
          .buffer
          .asUint8List(),
    );

    final total = ventes.fold<int>(0, (sum, v) => sum + v.total);
    final moyenne = ventes.isNotEmpty ? (total ~/ ventes.length) : 0;

    // Par client
    final ventesParClient = <String, int>{};
    final ventesParClientCount = <String, int>{};

    // Par jour
    final ventesParJour = <String, int>{};
    final ventesParJourCount = <String, int>{};

    // ✅ Nouveau : Par produit
    final ventesParProduit = <String, int>{};

    for (var v in ventes) {
      final nomClient = v.clientNom ?? '—';
      ventesParClient[nomClient] = (ventesParClient[nomClient] ?? 0) + v.total;
      ventesParClientCount[nomClient] =
          (ventesParClientCount[nomClient] ?? 0) + 1;

      final date = format.format(v.date);
      ventesParJour[date] = (ventesParJour[date] ?? 0) + v.total;
      ventesParJourCount[date] = (ventesParJourCount[date] ?? 0) + 1;

      // 🔁 Nouveau : boucle sur les produits de chaque vente
      for (var produit in v.produits) {
        final nomProduit = produit.nom;
        final quantite = produit.quantite;
        ventesParProduit[nomProduit] =
            (ventesParProduit[nomProduit] ?? 0) + quantite;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            pw.Image(
              logoNetwork ?? logoLocal,
              width: 100,
              height: 100,
            ), // Logo centré
            pw.SizedBox(height: 10),
            pw.SizedBox(height: 20),
            pw.Text("Rapport de ventes",
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),
            pw.Text(
                "Période : ${dateDebut != null ? format.format(dateDebut) : '—'} → ${dateFin != null ? format.format(dateFin) : '—'}"),
            pw.SizedBox(height: 12),

            // Résumé
            pw.Text("Résumé général :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "Nombre total de ventes : ${ventes.length}"),
            pw.Bullet(text: "Total vendu : $total Fcfa"),
            pw.Bullet(text: "Moyenne par vente : $moyenne Fcfa"),
            pw.SizedBox(height: 12),

            // Par client
            pw.Text("Répartition par client :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParClient.entries.map((e) {
              final count = ventesParClientCount[e.key];
              return pw.Text("- ${e.key} : ${e.value} Fcfa  ($count ventes)");
            }),
            pw.SizedBox(height: 12),

            // Par jour
            pw.Text("Répartition par jour :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParJour.entries.map((e) {
              final count = ventesParJourCount[e.key]!;
              return pw.Text("- ${e.key} : ${e.value} Fcfa  ($count ventes)");
            }),
            pw.SizedBox(height: 12),

            // ✅ Répartition par produit
            pw.Text("Répartition par produit :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParProduit.entries.map((e) {
              return pw.Text("- ${e.key} : ${e.value} unité(s)");
            }),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _ouvrirDialogReglement(
      BuildContext context, VenteModel vente, String type) {
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(type == "Règlement" ? "Règlement" : "Remboursement"),
        content: TextField(
          controller: montantController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: "Montant",
              labelStyle:
                  GoogleFonts.roboto(fontSize: 14, color: Colors.black)),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            child: Text("Valider",style: GoogleFonts.roboto(fontSize: 14,color: Colors.white),),
            onPressed: () async {
              final montant = int.tryParse(montantController.text) ?? 0;
              if (montant <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Montant invalide ou supérieur au dû")));
                return;
              }

              final token =
                  Provider.of<AuthProvider>(context, listen: false).token;
              final userId =
                  Provider.of<AuthProvider>(context, listen: false).userId;
              final userName =
                  Provider.of<AuthProvider>(context, listen: false).userName;
              final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
              final reglement = {
                "venteId": vente.id, // ⇦ ID de la vente concernée
                "userId": userId, // ⇦ ID du vendeur
                "adminId":adminId,
                "clientId": vente.clientId,
                "nom": vente.clientNom,
                "montant": montant,
                "type": type,
                "mode": vente.typePaiement,
                "operateur": userName,
                "date": DateTime.now().toIso8601String(),
              };

              final res =
                  await ServicesReglements().postReglements(reglement, token);
              if (res.statusCode == 201) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                       backgroundColor: Colors.green,
                      content: Text("Règlement effectué",style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),)));
                 fetchVentes();
                // Tu peux recharger les crédits ici
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erreur lors du règlement")));
              }
            },
          ),
        ],
      ),
    );
  }
}
