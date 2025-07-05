// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
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
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final response = await api.getClientRetard(userId, token);

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
            data: clients.map((c) => [
              c.nomClient,
              c.contact ?? '-',
              '${c.total} F',
              '${c.montantRecu} F',
              '${c.reste} F',
              dateFormat.format(c.date)
            ]).toList(),
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clients en Retard de Paiement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
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
            return const Center(child: Text("Aucun client en retard de paiement."));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Nom")),
                DataColumn(label: Text("Contact")),
                DataColumn(label: Text("Total")),
                DataColumn(label: Text("Reçu")),
                DataColumn(label: Text("Reste")),
                DataColumn(label: Text("Date")),
              ],
              rows: clients.map((c) {
                return DataRow(cells: [
                  DataCell(Text(c.nomClient)),
                  DataCell(Text(c.contact ?? '-')),
                  DataCell(Text("${c.total} F")),
                  DataCell(Text("${c.montantRecu} F")),
                  DataCell(Text("${c.reste} F")),
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(c.date))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
