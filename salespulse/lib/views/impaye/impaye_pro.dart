// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';

class ClientRetard {
  final String nomClient;
  final String? contact;
  final int total;
  final int montantRecu;
  final int reste;
  final DateTime date;

  ClientRetard({
    required this.nomClient,
    required this.contact,
    required this.total,
    required this.montantRecu,
    required this.reste,
    required this.date,
  });

  factory ClientRetard.fromJson(Map<String, dynamic> json) {
    return ClientRetard(
      nomClient: json['nomClient'] ?? 'Client inconnu',
      contact: json['contact'],
      total: json['total'],
      montantRecu: json['montantRecu'],
      reste: json['reste'],
      date: DateTime.parse(json['date']),
    );
  }
}

class ClientsEnRetardScreen extends StatefulWidget {
  const ClientsEnRetardScreen({super.key});

  @override
  State<ClientsEnRetardScreen> createState() => _ClientsEnRetardScreenState();
}

class _ClientsEnRetardScreenState extends State<ClientsEnRetardScreen> {
  ServicesStats api = ServicesStats();
  late Future<List<ClientRetard>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = _fetchClientsEnRetard();
  }

  Future<List<ClientRetard>> _fetchClientsEnRetard() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final response = await api.getClientRetard(token);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['clients'];
      return data.map((json) => ClientRetard.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des données');
    }
  }

  void _generatePdf(List<ClientRetard> clients) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Rapport des Clients en Retard'),
          pw.Table.fromTextArray(
            headers: ['Nom', 'Contact', 'Total', 'Reçu', 'Reste', 'Date'],
            data: clients
                .map((c) => [
                      c.nomClient,
                      c.contact ?? '-',
                      '${c.total} F',
                      '${c.montantRecu} F',
                      '${c.reste} F',
                      dateFormat.format(c.date)
                    ])
                .toList(),
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,//const Color(0xff001c30),
        title: Text("Clients en Retard de Paiement",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
            ),
            onPressed: () async {
              final clients = await _clientsFuture;
              _generatePdf(clients);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ClientRetard>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final clients = snapshot.data ?? [];

          if (clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/not_data.png",
                      width: 200, height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  Text("Aucun client en retard de paiement.",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          )),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
                              color: Colors.white, fontWeight: FontWeight.bold),
                          columns: [
                            DataColumn(
                                label: Text(
                              "Nom".toUpperCase(),
                              style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            )),
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
                                label: Text("Reçu".toUpperCase(),
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
                                label: Text("Date".toUpperCase(),
                                    style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                          ],
                          rows: clients.map((c) {
                            return DataRow(cells: [
                              DataCell(Text(c.nomClient,
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(c.contact ?? '-',
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text("${c.total.toStringAsFixed(2)} F",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(
                                  "${c.montantRecu.toStringAsFixed(2)} F",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text("${c.reste.toStringAsFixed(2)} F",
                                  style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black))),
                              DataCell(Text(
                                  DateFormat('dd/MM/yyyy').format(c.date),
                                  style: GoogleFonts.roboto(
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
        },
      ),
    );
  }
}
